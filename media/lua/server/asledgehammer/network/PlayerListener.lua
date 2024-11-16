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

    local toRemove = {};
    local timeNow;
    local timeLast = 0;
    local playersOnline, size;
    local player, username;
    local found;

    Events.OnTickEvenPaused.Add(function()

        timeNow = getTimeInMillis();

        -- Only run once every 5 seconds.
        if timeNow - timeLast < 2000 then return end

        -- The next run is approximately 5 seconds from now.
        timeLast = timeNow;

        -- Grab the current list of online players.
        playersOnline = getOnlinePlayers();

        -- Look for players that have logged in since the last check.
        size = playersOnline:size();
        for i = 0, size - 1, 1 do
            
            local nextPlayer = playersOnline:get(i);
            username = nextPlayer:getUsername();
            player = PlayerListener.players[username];
            
            if player == nil then
                onLogin(nextPlayer, username)
            end
        
        end

        -- Look for players that are no longer online.
        for _username, _ in pairs(PlayerListener.players) do

            found = false;
            
            for i = 0, size - 1, 1 do
            
                local nextPlayer = playersOnline:get(i);
            
                if _username == nextPlayer:getUsername() then
                    found = true;
                    break;
                end
            
            end
            
            if not found then 
                table.insert(toRemove, _username)
            end

        end

        -- Handle logged out players. (If any)
        if #toRemove ~= 0 then

            for _, _username in ipairs(toRemove) do
                onLogout(_username);
            end
        
        end

        toRemove = {};
    
    end);

end);

LuaEventManager.AddEvent('OnServerPlayerLogin');
LuaEventManager.AddEvent('OnServerPlayerLogout');

return PlayerListener;
