---[[
--- @author JabDoesThings, asledgehammer 2025
---]]

local JSON = require 'asledgehammer/util/JSON';
local readonly = require 'asledgehammer/util/readonly';
local TimeUtils = require 'asledgehammer/util/TimeUtils';

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
    if IS_SERVER then s = s .. 'Client' else s = s .. 'Server' end
    s = s .. 'Command(\n\tmodule=\'' .. module .. '\',\n\tcommand=\'' .. command .. '\'';
    if player ~= nil then s = s .. ',\n\tplayer=\'' .. tostring(player:getUsername()) .. '\'' end
    if args ~= nil then s = s .. ',\n\targs=\'' .. JSON.stringify(args) .. '\'' end
    print(s .. '\n)');
end

--- Delays a task by x ticks.
---
--- @deprecated Use `TimeUtils.delayTicks()`.
---
--- @param ticks number The amount of ticks delayed before invoking the callback. <br>NOTE: If ticks is zero then the callback is invoked immediately.
--- @param callback fun(): void The callback to invoke after the delay.
---
--- @return void
function ZedUtils.delay(ticks, callback)
    TimeUtils.delayTicks(callback, ticks);
end

return readonly(ZedUtils);
