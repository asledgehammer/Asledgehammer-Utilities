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

return readonly(ZedUtils);
