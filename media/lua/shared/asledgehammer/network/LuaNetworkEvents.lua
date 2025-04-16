---[[
--- Adds a custom LuaEvent `OnLuaNetworkConnected` that fires when a successful ping-pong response from the server is
--- received. It's very annoying having to write out these function add-removes in code so this is here to simplify the
--- process.
---
--- @author JabDoesThings, asledgehammer 2025
---]]

local readonly = require 'asledgehammer/util/readonly';

-- (Network only)
local IS_CLIENT = isClient();
local IS_SERVER = isServer();
if not IS_CLIENT and not IS_SERVER then return end

local triggered = false;
local timeNow, timeLast = 0, 0;

--- @generic E: any
--- @param object any
--- @param field string
---
--- @return E, nil
local function getJavaField(object, field)
    local offset = string.len(field);
    for i = 0, getNumClassFields(object) - 1 do
        local m = getClassField(object, i);
        if string.sub(tostring(m), -offset) == field then
            return getClassFieldVal(object, m);
        end
    end
    return nil;
end

--- @param event string
--- @param callback function
local function AddFirst(event, callback)
    --- callbacks: ArrayList<function>
    local callbacks = getJavaField(LuaEventManager.AddEvent(event), 'callbacks');
    if not callbacks then
        print('Cannot Event.AddFirst(): Event doesn\'t exist: ' .. tostring(event));
    end
    callbacks:add(0, callback);
end

local module = {};
local poolClient = {};
local poolServer = {};

--- @param func fun(module: string, command: string, player: IsoPlayer, args: any): void
function module.addClientListener(func)
    table.insert(poolClient, func);
end

--- @param func fun(module: string, command: string, args: any): void
function module.addServerListener(func)
    table.insert(poolServer, func);
end

Events.OnGameBoot.Add(function()
    if IS_CLIENT then
        AddFirst('OnServerCommand', function(m, command, args)
            for _, callback in ipairs(poolServer) do
                pcall(function() callback(m, command, args) end);
            end
        end);
    elseif IS_SERVER then
        AddFirst('OnClientCommand', function(m, command, player, args)
            for _, callback in ipairs(poolClient) do
                pcall(function() callback(m, command, player, args) end);
            end
        end);
    end
end);

LuaEventManager.AddEvent('OnLuaNetworkConnected');

if IS_CLIENT then
    Events.OnGameStart.Add(function()
        local a = function()
            timeNow = getTimeInMillis();
            if timeNow - timeLast > 500 then
                sendClientCommand('asledgehammer_utilities', 'ping', {});
                timeLast = getTimeInMillis();
            end
        end
        module.addServerListener(function(m, command, args)
            if m ~= 'asledgehammer_utilities' then return end
            if command ~= 'pong' then return end
            if not triggered then
                triggered = true;
                triggerEvent('OnLuaNetworkConnected');
            end
            Events.OnTickEvenPaused.Remove(a);
        end);
        Events.OnTickEvenPaused.Add(a);
    end);
elseif IS_SERVER then
    Events.OnServerStarted.Add(function()
        module.addClientListener(function(m, command, player)
            if m ~= 'asledgehammer_utilities' then return end
            if command ~= 'ping' then return end
            triggerEvent('OnLuaNetworkConnected', player);
            sendServerCommand(player, 'asledgehammer_utilities', 'pong', {});
        end);
    end);
end

Events.OnLuaNetworkConnected.Add(
--- @param player? IsoPlayer
    function(player)
        if player then
            print('### LUA NETWORK CONNECTION (Player "' .. player:getUsername() .. '") ###');
        else
            print('### LUA NETWORK CONNECTION ###');
        end
    end
);

return readonly(module);
