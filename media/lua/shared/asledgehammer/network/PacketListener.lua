---[[ 
--- PacketListener is an advanced packet solution for multiplayer mods for Project Zomboid.
--- 
--- TODO: Create Packet class for results to be stored and sent more than once.
--- 
--- @author JabDoesThings, asledgehammer 2024
---]]

-- Make sure that this script only runs in the Project Zomboid environment.
if not instanceof then return nil end

local IS_SERVER = isServer();

local class = require 'asledgehammer/util/class';
local aeslua = require 'asledgehammer/util/encryption/aeslua';
local JSON = require 'asledgehammer/util/json';

--- @type table<string, PacketListener>
local listeners = {};

--- @class PacketListener
-- --- @field module string The module channel to listen.
-- --- @field onGetKey fun(): string
-- --- @field onReceivePacket fun(module: string, player: IsoPlayer?, id: string, data: table?): void
-- --- @field listening boolean True if the listener is registered and listening for receiving packets.
local PacketListener = class(function(ins)
    --- @type boolean
    ins.listening = false;
    --- @type nil | string
    ins.module = nil;
    --- @type nil | string | fun(): string
    ins.onGetKey = nil;
    --- @type nil | fun(): void
    ins.onReceivePacket = nil;
end);

PacketListener.RESULT_SUCCESS = 0;
PacketListener.RESULT_ERROR = 1;

--- Sends the packet immediately through LuaNet. If encrypted, the encryption will happen immediately. DO NOT USE IF NOT
--- ON CONNECTION ESTABLISHED OR DURING GAMEPLAY! THIS WILL FREEZE THE GAME!
PacketListener.PRIORITY_IMMEDIATE = 1;

--- Sends the packet after encrypting its contents over a period of ticks. (Recommended)
PacketListener.PRIORITY_PASSIVE = 2;

--- @type {encryption: {key:number, mode:number, priority: number}?}
---
--- Default encryption options.
PacketListener.DEFAULT_ENCRYPTION_OPTIONS = {

    --- @type {key:number, mode:number, priority: number}?
    ---
    --- If defined, sets to encrypt the packet before sending and decrypts after receiving the packet.
    encryption = {

        --- @type 16 | 24 | 32
        ---
        --- Either **AES128**, **AES192**, or **AES256**.
        keyLength = aeslua.AES128,

        --- @type 1 | 2 | 3 | 4
        ---
        --- Either **ECBMODE**, **CBCMODE**, **OFBMODE**, or **CFBMODE**.
        mode = aeslua.OFBMODE,

        send = {
            --- @type 1 | 2
            ---
            --- Either **PRIORITY_IMMEDIATE**, or **PRIORITY_PASSIVE**.
            priority = PacketListener.PRIORITY_PASSIVE
        },

        receive = {
            --- @type 1 | 2
            ---
            --- Either **PRIORITY_IMMEDIATE**, or **PRIORITY_PASSIVE**.
            priority = PacketListener.PRIORITY_PASSIVE
        },
    },

    --- @type (fun(status: 0 | 1): void) | nil
    onSent = function(status) end
};

--______________________________________________________________________________--

--- @class PacketJob
--- @field mode 1|2
--- @field listener PacketListener
--- @field player IsoPlayer? Only set this if this is a server-side job.
--- @field complete boolean If true, the job is complete and handled.
--- @field step fun()
--- @field thread thread? The thread that is ran for normal priority jobs.

--- @class ins PacketJob
--- @param mode 1|2
--- @param listener PacketListener
--- @param player IsoPlayer | nil
--- @param module string
--- @param id string
--- @param args table | nil
--- @param options any
local PacketJob = class(function(ins, mode, listener, player, module, id, args, options)
    -- Arguments --
    ins.mode = mode;
    ins.listener = listener;
    ins.player = player;
    ins.module = module;
    ins.id = id;
    ins.args = args;
    ins.options = options;
    -- State flags --
    ins.complete = false;

    ins.onGetKey = listener.onGetKey;


    if options and options.encryption then
        local encryption = options.encryption;

        local priority;
        if mode == 1 then -- MODE_SEND
            priority = options.encryption.send.priority;
        else              -- MODE_RECEIVE
            priority = options.encryption.receive.priority;
        end

        if priority == PacketListener.PRIORITY_PASSIVE then
            print('Processing PacketJob with priority normal..');

            ins.jobSteps = 1;

            local getKey = ins.onGetKey;
            local key = nil;
            if type(getKey) == 'function' then
                key = getKey()
            elseif type(getKey) == 'string' then
                key = getKey;
            end
            assert(key, 'The key given or returned is nil!');
            if encryption then
                if mode == 1 then
                    local _ = JSON.stringify({ id = id, data = args });
                    ins.id = nil;
                    ins.args = nil;
                    ins.thread = aeslua.encryptAsync(key, _, encryption.keyLength, encryption.mode);
                elseif mode == 2 then
                    print('### args = ' .. args._);
                    ins.thread = aeslua.decryptAsync(key, args._, encryption.keyLength, encryption.mode);
                end
            end
        end
    end
end);

PacketJob.MODE_SEND = 1;
PacketJob.MODE_RECEIVE = 2;

function PacketJob:stepImmediate()
    --- Ensures that data won't corrupt by poor implementation of jobs API.
    if self.complete then return end

    local listener = self.listener;
    local player = self.player;
    local module = self.module;

    if self.mode == PacketJob.MODE_SEND then
        local options = self.options;
        local encryption = options.encryption;

        local _out;
        -- Convert the data table to a JSON string and then encrypt it. Also forward options to the outTable.
        if encryption then
            assert(encryption.keyLength, 'keyLength not defined for encryption!');
            assert(encryption.mode, 'mode not defined for encryption!');

            local getKey = self.onGetKey;
            local key = nil;
            if type(getKey) == 'function' then
                key = getKey();
            elseif type(getKey) == 'string' then
                key = getKey;
            end
            assert(key, 'The key given or returned is nil!');

            _out = { options = options };
            local _ = JSON.stringify({ id = self.id, data = self.args });

            -- Cleanup to prevent side-channel attack.
            self.id = nil;
            self.args = nil;

            _out._ = aeslua.encrypt(key, _, encryption.keyLength, encryption.mode);
        else
            _out = {
                _ = {
                    id = self.id,
                    data = self.args,
                },
                options = options,
            };
        end

        if IS_SERVER then
            sendServerCommand(player, module, '_', _out);
        else
            sendClientCommand(module, '_', _out);
        end

        self.complete = true;
    elseif self.mode == PacketJob.MODE_RECEIVE then
        local options = self.args.options;
        local encryption = options.encryption;

        local _in;

        -- Convert the data table to a JSON string and then encrypt it. Also forward options to the outTable.
        if encryption then
            assert(encryption.keyLength, 'keyLength not defined for encryption!');
            assert(encryption.mode, 'mode not defined for encryption!');

            local getKey = self.onGetKey;
            local key = nil;
            if type(getKey) == 'function' then
                key = getKey();
            elseif type(getKey) == 'string' then
                key = getKey;
            end
            assert(key, 'The key given or returned is nil!');

            _in = { options = self.options };
            local t = JSON.parse(aeslua.decrypt(key, self.args._, encryption.keyLength, encryption.mode));
            _in._ = t;
        else
            _in = {
                _ = {
                    id = self.args._.id,
                    data = self.args._.id,
                },
                options = self.options,
            };
        end
        if IS_SERVER then
            listener.onReceivePacket(self.player, _in._.id, _in._.data);
        else
            listener.onReceivePacket(_in._.id, _in._.data);
        end

        self.complete = true;
    end
end

function PacketJob:stepNormal()
    -- Ensures that data won't corrupt by poor implementation of jobs API.
    if self.complete then return end

    if coroutine.status(self.thread) ~= 'dead' then
        local success, result = coroutine.resume(self.thread);

        if not success then
            error(result);
            return;
        end

        self.jobSteps = self.jobSteps + 1;
        self.result = result;
    end

    -- The job is not complete.
    if not self.result then return end

    local module = self.module;
    local player = self.player;

    if self.mode == PacketJob.MODE_SEND then
        local _out = { options = self.options, _ = self.result };

        if IS_SERVER then
            sendServerCommand(player, module, '_', _out);
        else
            sendClientCommand(module, '_', _out);
        end

        -- Let the sending code know the job is completed.
        if self.options.onSent and type(self.options.onSent) == "function" then
            self.options.onSent(PacketListener.RESULT_SUCCESS);
        end
    else
        local listener = self.listener;
        local _ = JSON.parse(self.result);

        if IS_SERVER then
            listener.onReceivePacket(player, _.id, _.data);
        else
            listener.onReceivePacket(_.id, _.data);
        end
    end

    -- print('Job completed in ' .. tostring(self.jobSteps) .. ' step(s).');
    self.complete = true;
end

function PacketJob:step()
    --- Ensures that data won't corrupt by poor implementation of jobs API.
    if self.complete then return end

    self.error = true;
    pcall(function()
        local options = self.options;
        if options and self.options.encryption then
            local priority;
            if self.mode == PacketJob.MODE_SEND then
                priority = options.encryption.send.priority;
            else
                priority = options.encryption.receive.priority;
            end

            if priority == PacketListener.PRIORITY_IMMEDIATE then
                self:stepImmediate();
            else
                self:stepNormal();
            end
        else
            self:stepImmediate();
        end
    end);
    self.error = false;
end

--______________________________________________________________________________--

--- All packets to send are stored here.
local jobs = {
    --- All packets to encrypt & send goes here.
    send = {},
    --- All packets to decrypt goes here.
    receive = {},
};

--- @param module string
--- @param getKey (fun(): string)|string|nil
--- @param onReceivePacket fun(module: string, player: IsoPlayer?, id: string, data: table?): void
---
--- @return void
function PacketListener:listen(module, getKey, onReceivePacket)
    assert(module and #module ~= 0, 'The parameter \'module\' is either nil or an empty string.');
    assert(not self.listening, 'The PacketListener is already listening to module \'' .. module .. '\'!');
    self.module = module;
    self.onGetKey = getKey;
    self.onReceivePacket = onReceivePacket;
    self.listening = true;
    listeners[module] = self;
end

function PacketListener:unListen()
    assert(self.listening, 'The PacketListener is not listening and cannot unlisten.');
    listeners[self.module] = nil;
    self.module = nil;
    self.listening = false;
end

--- Sends a packet through LuaNet. Options
---
--- @param player IsoPlayer? Only send if server-side.
--- @param id string The ID of the packet.
--- @param data table The data of the packet.
--- @param options table? The options on how to send the packet. PacketListener.DEFAULT_ENCRYPTION_OPTIONS is used if
---                       not provided.
function PacketListener:sendToPlayer(player, id, data, options)
    -- Default options
    if not options then options = PacketListener.DEFAULT_ENCRYPTION_OPTIONS end

    -- Create and queue the job.
    local job = PacketJob(PacketJob.MODE_SEND, self, player, self.module, id, data, options);
    table.insert(jobs.send, job);
end

--- Sends a packet through LuaNet. Options
---
--- @param player IsoPlayer? Only send if server-side.
--- @param id string The ID of the packet.
--- @param data table The data of the packet.
--- @param options table? The options on how to send the packet. PacketListener.DEFAULT_ENCRYPTION_OPTIONS is used if
---                       not provided.
function PacketListener:sendToServer(id, data, options)
    -- Default options
    if not options then options = PacketListener.DEFAULT_ENCRYPTION_OPTIONS end

    -- Create and queue the job.
    local job = PacketJob(PacketJob.MODE_SEND, self, nil, self.module, id, data, options);
    table.insert(jobs.send, job);
end

--______________________________________________________________________________--

--- For packet listeners that initialize and send on the very first call to `OnGameStart`, this helps with LuaNet
---     not being ready for it to send the packet, preventing the packet from being discarded.
local initDelayCounter = 5;

local sendJobsToRemove = {};
local receiveJobsToRemove = {};

local function staticTick()
    -- Prevents sending packets before LuaNet initializes.
    if initDelayCounter ~= 0 then
        initDelayCounter = initDelayCounter - 1;
        return;
    end

    -- Step all jobs.
    for index, job in ipairs(jobs.send) do
        if not job.error and not job.ready then job:step() end
        if job.ready or job.error then sendJobsToRemove[index] = job end
    end
    for index, job in ipairs(jobs.receive) do
        if not job.error and not job.ready then job:step() end
        if job.ready or job.error then receiveJobsToRemove[index] = job end
    end
    -- Clean out completed jobs.
    for index, _ in pairs(sendJobsToRemove) do
        table.remove(jobs.send, index);
        table.remove(sendJobsToRemove, index);
    end
    for index, _ in pairs(receiveJobsToRemove) do
        table.remove(jobs.receive, index);
        table.remove(receiveJobsToRemove, index);
    end
end

local function staticCommand(module, command, player, args)
    -- print(
    --     'OnCommand(\n' ..
    --     '\tmodule=\'' .. module .. '\',\n' ..
    --     '\tcommand=\'' .. command .. '\',\n' ..
    --     '\tplayer=\'' .. tostring(player) .. '\',\n' ..
    --     '\targs=\'' .. JSON.stringify(args) .. '\',\n' ..
    --     ')'
    -- );
    for _, listener in pairs(listeners) do
        local b = false;
        pcall(function()
            assert(listener.module, 'The listener doesn\'t have a module!');
            assert(listener.listening, 'The listener isn\'t listening!');
            local lModule = listener.module;
            if lModule == module and command == '_' then
                local job = PacketJob(PacketJob.MODE_RECEIVE, listener, player, module, nil, args,
                    PacketListener.DEFAULT_ENCRYPTION_OPTIONS);
                table.insert(jobs.receive, job);
                b = true;
            end
        end);
        if b then return end
    end
end

local function staticServerCommand(module, command, args)
    staticCommand(module, command, nil, args);
end

if instanceof then
    Events.OnTickEvenPaused.Add(staticTick);
    if isClient() and not isServer() then Events.OnServerCommand.Add(staticServerCommand) end
    if not isClient() and isServer() then Events.OnClientCommand.Add(staticCommand) end
end

return PacketListener;
