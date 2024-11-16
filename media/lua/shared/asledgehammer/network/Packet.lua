---[[
--- @author JabDoesThings, asledgehammer 2024
---]]

local JSON = require 'asledgehammer/util/json';
local class = require 'asledgehammer/util/class';
local ZedCrypt = require 'asledgehammer/encryption/ZedCrypt';

--- @class Packet
--- @field module string
--- @field command string
--- @field data table | nil
--- @field encrypted table
local Packet = class(
--- @param ins table
--- @param module string
--- @param command string
--- @param data table | nil
    function(ins, module, command, data)
        
        if data == nil then
            data = {};
        end
        
        ins.module = module;
        ins.command = command;
        ins.data = data;
        ins.encrypted = nil;
    end
);

--- With this priority, packets will immediately encrypt over the current tick. (Not recommended for non-cached or
--- larger packet payloads!)
---
--- @type 1
Packet.PRIORITY_IMMEDIATE = 1;

--- With this priority, packets will encrypt over ticks, not immediately. (Generally recommended)
---
--- @type 2
Packet.PRIORITY_NORMAL = 2;

--- @alias PacketEncryptionOptions { priority: 1 | 2, hideCommand: boolean }
--- @alias PacketCallback fun(packet: Packet): void

--- @type PacketEncryptionOptions
Packet.DEFAULT_ENCRYPTION_OPTIONS = {
    priority = Packet.PRIORITY_NORMAL
};

--- @param player IsoPlayer
---
--- @return void
function Packet:sendToPlayer(player)
    if self.encrypted ~= nil then
        sendServerCommand(player, self.module, '_', self.encrypted.data);
    else
        sendServerCommand(player, self.module, self.command, self.data);
    end
end

--- @return void
function Packet:sendToServer()
    if self.encrypted ~= nil then
        sendClientCommand(self.module, '_', self.encrypted.data);
    else
        sendClientCommand(self.module, self.command, self.data);
    end
end

---
--- @param key string
--- @param callback PacketCallback | nil
--- @param options PacketEncryptionOptions | nil
function Packet:encrypt(key, callback, options)
    assert(key ~= nil, 'The given key is nil!');

    if callback then
        assert(type(callback) == 'function', 'Callback is not a function!');
    end

    -- Prepare our options based on what's given.
    if not options then
        options = Packet.DEFAULT_ENCRYPTION_OPTIONS;
    else
        if not options.priority then
            options.priority = Packet.DEFAULT_ENCRYPTION_OPTIONS.priority;
        end
    end

    local encryption = {
        command = '_',
        data = {
            options = options,
            _ = self.data
        },
    };

    -- Ensure empty packets with encrypted commands have a data table.
    if encryption.data._ == nil then
        encryption.data._ = {};
    end

    -- Swap out the command as data when the command is encrypted.
    encryption.data._.command = self.command;

    if options.priority == Packet.PRIORITY_IMMEDIATE then

        -- Immediately swap out the table for its serialized and encrypted counterpart.
        encryption.data._ = ZedCrypt.encrypt(JSON.stringify(encryption.data._), key);

        self.encrypted = encryption;

        -- Invoke callback.
        if callback then callback(self) end

    elseif options.priority == Packet.PRIORITY_NORMAL then

        self.thread = ZedCrypt.encryptAsync(JSON.stringify(encryption.data._), key);

        --- @type fun(): void | nil
        local onTick = nil;

        --- @type string | nil
        local threadResult = nil;

        onTick = function()

            if coroutine.status(self.thread) ~= 'dead' then
                local success, result = coroutine.resume(self.thread);

                -------------------------------------
                -- Handle failure of the thread here.
                if not success then
                    error(result);
                    Events.OnTickEvenPaused.Remove(onTick);
                    self.thread = nil;
                    return;
                end
                -------------------------------------

                -- If a result is returned then assign it.
                threadResult = result;

            else
                print('[WARNING]: Packet:encrypt() coroutine died unexpectedly without result!!!');
                print(tostring(threadResult));
                Events.OnTickEvenPaused.Remove(onTick);
            end

            -- The job is not complete.
            if threadResult == nil then return end

            Events.OnTickEvenPaused.Remove(onTick);

            -- Set the packet's encrypted data.
            encryption.data._ = threadResult;
            self.encrypted = encryption;
            self.thread = nil;

            -- Invoke callback.
            if callback then callback(self) end
        end

        Events.OnTickEvenPaused.Add(onTick);

    end
end

--- @param key string
--- @param callback PacketCallback | nil
function Packet:decrypt(key, callback)
    assert(key ~= nil, 'The given key is nil!');

    if callback then
        assert(type(callback) == 'function', 'Callback is not a function!');
    end

    --- @type table
    local encrypted = nil;

    if not self.encrypted then
        -- Check to make sure the packet is encrypted.
        assert(self.data.options ~= nil, 'The packet is not encrypted.');

        -- Transform the packet to begin decryption.
        encrypted = self.data;
        self.command = self.data.command;
    end

    --- @type PacketEncryptionOptions
    local options = encrypted.options;

    if options.priority == Packet.PRIORITY_IMMEDIATE then
        local _ = JSON.parse(ZedCrypt.decrypt(encrypted._, key));

        -- Swap out the command if stored in encryption.
        self.command = _.command;
        _.command = nil;

        self.data = _;

        -- Invoke callback.
        if callback then callback(self) end

    elseif options.priority == Packet.PRIORITY_NORMAL then
        self.thread = ZedCrypt.decryptAsync(encrypted._, key);

        --- @type fun(): void | nil
        local onTick = nil;

        --- @type string | nil
        local threadResult = nil;

        onTick = function()
            if coroutine.status(self.thread) ~= 'dead' then
                local success, result = coroutine.resume(self.thread);

                -------------------------------------
                -- Handle failure of the thread here.
                if not success then
                    error(result);
                    Events.OnTickEvenPaused.Remove(onTick);
                    self.thread = nil;
                    return;
                end
                -------------------------------------

                -- If a result is returned then assign it.
                threadResult = result;

            else
                print('[WARNING]: Packet:decrypt() coroutine died unexpectedly without result!!!');
                print(tostring(threadResult));
                Events.OnTickEvenPaused.Remove(onTick);
            end

            -- The job is not complete.
            if threadResult == nil then return end

            Events.OnTickEvenPaused.Remove(onTick);

            local _ = JSON.parse(threadResult);

            -- Swap out the command if stored in encryption.
            if _.command ~= nil then
                self.command = _.command;
                _.command = nil;
            end

            self.encrypted = self.data;
            self.data = _;
            self.thread = nil;

            -- Invoke callback.
            if callback then callback(self) end
        end

        Events.OnTickEvenPaused.Add(onTick);

    end
end

--- Prints a JSON string or the packet.
---
--- @return void
function Packet:toJSON()
    return JSON.stringify({
        module = self.module,
        command = self.command,
        data = self.data,
        encrypted = self.encrypted
    });
end

return Packet;
