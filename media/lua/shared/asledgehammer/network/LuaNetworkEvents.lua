---[[
--- Adds a custom LuaEvent `OnLuaNetworkConnected` that fires when a successful ping-pong response from the server is
--- received. It's very annoying having to write out these function add-removes in code so this is here to simplify the
--- process.
---
--- @author JabDoesThings, asledgehammer 2025
---]]

-- (Network only)
local IS_CLIENT = isClient();
local IS_SERVER = isServer();
if not IS_CLIENT and not IS_SERVER then return end

LuaEventManager.AddEvent('OnLuaNetworkConnected');
local triggered = false;
local timeNow, timeLast = 0, 0;

if IS_CLIENT then
    Events.OnGameStart.Add(function()
        local a, b;
        a = function()
            timeNow = getTimeInMillis();
            if timeNow - timeLast > 500 then
                sendClientCommand('asledgehammer_utilities', 'ping', {});
                timeLast = getTimeInMillis();
            end
        end
        b = function()
            if not triggered then
                triggered = true;
                -- Confirm that this works.
                triggerEvent('OnLuaNetworkConnected');
            end
            Events.OnServerCommand.Remove(b);
            Events.OnTickEvenPaused.Remove(a);
        end
        Events.OnTickEvenPaused.Add(a);
        Events.OnServerCommand.Add(b);
    end);
elseif IS_SERVER then
    Events.OnServerStarted.Add(function()
        Events.OnClientCommand.Add(function(module, command, player, args)
            if module ~= 'asledgehammer_utilities' then return end
            if command ~= 'ping' then return end
            sendServerCommand(player, 'asledgehammer_utilities', 'pong', {});
        end);
    end);
end
