---[[
---
--- This script handles additional events for managing players logging in and
--- out of multiplayer servers. (Server-Side)
---
--- Events:
---   - void OnServerPlayerLogin(IsoPlayer player)
---   - void OnServerPlayerLogout(IsoPlayer player)
---
--- @author asledgehammer, JabDoesThings 2024
---
---]]

local readonly = require 'asledgehammer/util/readonly';

-- Only run on servers.
if isClient() or not isServer() then return end

local PlayerListener = {};

--- @type table<string, IsoPlayer>
PlayerListener.players = {};

--- @param player IsoPlayer
--- @param username string
local function onLogin(player, username)
    if PlayerListener.players[username] ~= nil then
        return
    end

    PlayerListener.players[username] = player;
    triggerEvent('OnServerPlayerLogin', player);
end

---@param username string
local function onLogout(username)
    local player = PlayerListener.players[username];
    if player == nil then return end

    PlayerListener.players[username] = nil;
    triggerEvent('OnServerPlayerLogout', player);
end

Events.OnServerStarted.Add(function()
    --- @type string[]
    local toRemove = {};
    --- @type number
    local timeNow;
    --- @type number
    local timeLast = 0;
    --- @type ArrayList<IsoPlayer>, number
    local playersOnline, size;
    --- @type IsoPlayer, string
    local player, username;
    --- @type IsoPlayer | nil
    local foundPlayer;

    Events.OnTickEvenPaused.Add(function()
        timeNow = getTimeInMillis();

        -- Only run once every 5 seconds.
        if timeNow - timeLast < 2000 then return end

        -- The next run is approximately 5 seconds from now.
        timeLast = timeNow;

        -- Grab the current list of online players.
        playersOnline = getOnlinePlayers();
        --- @cast playersOnline ArrayList<IsoPlayer>

        -- Look for players that have logged in since the last check.
        size = playersOnline:size();
        for i = 0, size - 1 do
            --- @type IsoPlayer
            local nextPlayer = playersOnline:get(i);
            username = nextPlayer:getUsername();
            player = PlayerListener.players[username];

            if not player and not nextPlayer:isDead() then
                onLogin(nextPlayer, username);
            end
        end

        -- Look for players that are no longer online.
        for _username, _ in pairs(PlayerListener.players) do
            --- @cast _username string
            foundPlayer = nil;
            for i = 0, size - 1, 1 do
                local nextPlayer = playersOnline:get(i);
                if _username == nextPlayer:getUsername() then
                    foundPlayer = nextPlayer;
                    break;
                end
            end
            if not foundPlayer or foundPlayer:isDead() then
                table.insert(toRemove, _username);
            end
        end

        -- Handle logged out players. (If any)
        if #toRemove ~= 0 then
            for _, _username in ipairs(toRemove) do
                --- @cast _username string
                onLogout(_username);
            end
        end

        toRemove = {};
    end);
end);

LuaEventManager.AddEvent('OnServerPlayerLogin');
LuaEventManager.AddEvent('OnServerPlayerLogout');

return readonly(PlayerListener);
