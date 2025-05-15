---[[
--- @author JabDoesThings, asledgehammer 2025
---]]

--- @alias ANSICode 'reset'|'bright'|'dim'|'italic'|'underline'|'reset_intensity'|'remove_underline'|'blink'|'reverse'|'hidden'|'black'|'red'|'green'|'yellow'|'blue'|'magenta'|'cyan'|'white'|'blackbg'|'redbg'|'greenbg'|'yellowbg'|'bluebg'|'magentabg'|'cyanbg'|'whitebg' All ANSI-code names.

local FileUtils = require 'asledgehammer/util/FileUtils';

--- @type table<ANSICode, number>
---
--- The non-destructive ANSI codes, represented by their names.
local keys = {
    reset     = 0,
    bright    = 1,
    dim       = 2,
    italic    = 3,
    underline = 4,
    blink     = 5,
    reverse   = 7,
    hidden    = 8,
    reset_intensity = 22,
    remove_underline = 24,
    black     = 30,
    red       = 31,
    green     = 32,
    yellow    = 33,
    blue      = 34,
    magenta   = 35,
    cyan      = 36,
    white     = 37,
    blackbg   = 40,
    redbg     = 41,
    greenbg   = 42,
    yellowbg  = 43,
    bluebg    = 44,
    magentabg = 45,
    cyanbg    = 46,
    whitebg   = 47
};

local escapeString = string.char(27) .. '[%dm';

local ANSI_SUPPORTED = false;
local ansiCode = FileUtils.readFile('console.lua');
if ansiCode then
    local config = loadstring(ansiCode)();
    if config.ansi ~= nil then
        ANSI_SUPPORTED = config.ansi;
    else
        ANSI_SUPPORTED = isServer();
    end
else
    ANSI_SUPPORTED = isServer();
    local data = string.format('return {\n\tansi = %s\n};', tostring(ANSI_SUPPORTED));
    FileUtils.writeFile('console.lua', data, false);
end

--- Builds an ANSI code from a number.
---
--- @param number number The ANSI-Code number.
---
--- @return string ANSIcodeString The built ANSI-Code as a string.
local function ansi(number)
    return escapeString:format(number);
end

--- Builds an ANSI code from a string.
---
--- @param name ANSICode
---
--- @return string ANSIcodeString The built ANSI-Code as a string.
local function ansiFromName(name)
    return ansi(keys[name]);
end

return { ANSI_SUPPORTED = ANSI_SUPPORTED, keys = keys, ansi = ansi, ansiFromName = ansiFromName };
