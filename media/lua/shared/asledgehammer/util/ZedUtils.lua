local JSON = require 'asledgehammer/util/JSON';
local readonly = require 'asledgehammer/util/readonly';

local ZedUtils = {};
local IS_SERVER = isServer();

--- Prints a LuaCommand to the console.
---
--- @param module string
--- @param command string
--- @param player IsoPlayer | nil
--- @param args table
---
--- @return void
function ZedUtils.printLuaCommand(module, command, player, args)
    local s = 'On';
    if IS_SERVER then
        s = s .. 'Client';
    else
        s = s .. 'Server';
    end
    s = s .. 'Command(\n';
    s = s .. '\tmodule=\'' .. module .. '\',\n';
    s = s .. '\tcommand=\'' .. command .. '\'';
    if player ~= nil then
        s = s .. ',\n\tplayer=\'' .. tostring(player:getUsername()) .. '\'';
    end
    if args ~= nil then
        s = s .. ',\n\targs=\'' .. JSON.stringify(args) .. '\'';
    end
    s = s .. '\n)';
    print(s);
end

--- Delays a task by x ticks.
--- 
--- @param ticks number The amount of ticks delayed before invoking the callback. <br>NOTE: If ticks is zero then the callback is invoked immediately.
--- @param callback fun(): void The callback to invoke after the delay.
--- 
--- @return void
function ZedUtils.delay(ticks, callback)
    -- (Sanity checks)
    assert(ticks > -1, 'Ticks cannot be negative. (Given: ' .. tostring(ticks) .. ')');
    assert(callback ~= nil, 'The callback is nil!');
    assert(type(callback) == 'function', 'The callback is not a function. (Given type: ' .. type(callback) .. ')');

    -- Run immediatley.
    if ticks == 0 then
        callback();
        return;
    end

    -- Run delayed.
    local t = 0;
    --- @type fun(): void | nil
    local onTick = nil;
    onTick = function()
        if t < ticks then
            t = t + 1;
            return;
        end
        Events.OnFETick.Remove(onTick);
        Events.OnTickEvenPaused.Remove(onTick);
        callback();
    end

    Events.OnFETick.Add(onTick);
    Events.OnTickEvenPaused.Add(onTick);
end

return readonly(ZedUtils);
