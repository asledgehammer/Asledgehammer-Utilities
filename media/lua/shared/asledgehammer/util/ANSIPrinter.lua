---[[
--- @author JabDoesThings, asledgehammer 2025
---]]

-- ANSI library.
local ANSI_LIB = require 'asledgehammer/util/ansi';
local ansi = ANSI_LIB.ansi;

--- @class ANSIPrinter: ISBaseObject ANSIPrinter is a print & printf wrapper for Lua mods in Project Zomboid to print more conveniently while providing ANSI support for ANSI colors, modes, actions, etc.
--- @field name string The name of the printer. (Used in prefixes)
--- @field enabled boolean If true, ANSI codes are printed. If false, ANSI codes are stripped prior to printing.
--- @field infoPrefix string The prefix printed for info prints.
--- @field successPrefix string The prefix printed for success prints.
--- @field warnPrefix string The prefix printed for warning prints.
--- @field errorPrefix string The prefix printed for error prints.
--- @field fatalPrefix string The prefix printed for fatal prints.
--- @field STRIP_PATTERN string The Lua string-match pattern for every possible ANSI code.
--- @field RESET string Shorthand storage of the ANSI Reset code. (Used for cleaner code)
--- @field KEYS table<ANSICode, string> A pre-built table of all non-destructive ANSI codes.
ANSIPrinter = ISBaseObject:derive('ANSIPrinter');

--- Store all ANSI keys.
ANSIPrinter.KEYS = {};
for key, value in pairs(ANSI_LIB.keys) do
    ANSIPrinter.KEYS[key] = ansi(value);
end
ANSIPrinter.RESET = ANSIPrinter.KEYS['reset'];

--- Helpful prefetch.
local prefix = '%s[%s] :: ';
local bright, dim, white = ANSIPrinter.KEYS['bright'], ANSIPrinter.KEYS['dim'], ANSIPrinter.KEYS['white'];
local red, green, yellow = ANSIPrinter.KEYS['red'], ANSIPrinter.KEYS['green'], ANSIPrinter.KEYS['yellow'];
local redbg = ANSIPrinter.KEYS['redbg'];

ANSIPrinter.STRIP_PATTERN = '[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]';

--- Strips ANSI codes from a content string.
---
--- @param message string The message that may contain ANSI codes.
---
--- @return string strippedMessage
function ANSIPrinter.strip(message)
    local stripped = message:gsub(ANSIPrinter.STRIP_PATTERN, '');
    return stripped;
end

--- Sets the name of the prefixes for the printer.
---
--- @param name string The name to display.
function ANSIPrinter:setName(name)
    self.name = name;
    self.infoPrefix = string.format(prefix, dim, name);
    self.successPrefix = string.format(prefix, bright .. green, name);
    self.warnPrefix = string.format(prefix, bright .. yellow, name);
    self.errorPrefix = string.format(prefix, bright .. red, name);
    self.fatalPrefix = string.format(prefix, bright .. white .. redbg, name);
end

--- A middle-man printer to call that checks the ANSI `self.enabled` state, stripping ANSI codes if disabled.
---
--- @param ... any The normal printer arguments.
function ANSIPrinter:print(...)
    local s = '';

    for _, v in ipairs({ ... }) do
        if s == '' then
            s = tostring(v);
        else
            s = s .. '\t' .. tostring(v);
        end
    end
    if not self.enabled then
        print(ANSIPrinter.strip(s));
        return;
    end

    -- Print normally. (Force each line to reset the ANSI state, otherwise subsequent prints will keep the state)
    print(s .. ANSIPrinter.RESET);
end

--- A common printf implementation in modern compiled languages. Takes 2nd -> Nth arguments as `string.format(...)`
--- arguments.
---
--- @param message string The message to format and print.
--- @param ... any The `string.format(...)` arguments to inject.
function ANSIPrinter:printf(message, ...)
    if not self.enabled then
        self:print(string.format(message, ...));
        return;
    end
    self:print(string.format(message, ...));
end

--- A wrapped call to `self:printf(message, ...)`, prefixed by `self.infoPrefix` along with ANSI codes to display
--- information logs.
---
--- @param message? string The message to format and print.
--- @param ... any The `string.format(...)` arguments to inject.
function ANSIPrinter:info(message, ...)
    if not message then
        self:print(self.infoPrefix);
    else
        self:printf(self.infoPrefix .. tostring(message), ...);
    end
end

--- A wrapped call to `self:printf(message, ...)`, prefixed by `self.infoPrefix` along with ANSI codes to display
--- successful logs.
---
--- @param message? string The message to format and print.
--- @param ... any The `string.format(...)` arguments to inject.
function ANSIPrinter:success(message, ...)
    if not message then
        self:print(self.successPrefix);
    else
        self:printf(self.successPrefix .. tostring(message), ...);
    end
end

--- A wrapped call to `self:printf(message, ...)`, prefixed by `self.warnPrefix` along with ANSI codes to display
--- warning logs.
---
--- @param message? string The message to format and print.
--- @param ... any The `string.format(...)` arguments to inject.
function ANSIPrinter:warn(message, ...)
    if not message then
        self:print(self.warnPrefix);
    else
        self:printf(self.warnPrefix .. tostring(message), ...);
    end
end

--- A wrapped call to `self:printf(message, ...)`, prefixed by `self.errorPrefix` along with ANSI codes to display
--- error logs.
---
--- @param message? string The message to format and print.
--- @param ... any The `string.format(...)` arguments to inject.
function ANSIPrinter:error(message, ...)
    if not message then
        self:print(self.errorPrefix);
    else
        self:printf(self.errorPrefix .. tostring(message), ...);
    end
end

--- A wrapped call to `self:printf(message, ...)`, prefixed by `self.fatalPrefix` along with ANSI codes to display
--- fatal logs.
---
--- @param message? string The message to format and print.
--- @param ... any The `string.format(...)` arguments to inject.
function ANSIPrinter:fatal(message, ...)
    if not message then
        self:print(self.fatalPrefix);
    else
        self:printf(self.fatalPrefix .. tostring(message), ...);
    end
end

--- @param name string The name to set for the prefix of the printer.
--- @param enabled? boolean If true, ANSI codes are printed. if false, ANSI codes are stripped prior to being printed. If not provided, the ANSI state is deffered to `ansi.ANSI_SUPPORTED`.
---
--- @return ANSIPrinter instance The new printer object.
function ANSIPrinter:new(name, enabled)
    ---------------------
    --- Invoke `super()`
    ---
    --- @type ANSIPrinter
    local o = ISBaseObject:new();
    setmetatable(o, self);
    self.__index = self;
    ---------------------

    o:setName(name);
    o.enabled = enabled or ANSI_LIB.ANSI_SUPPORTED;

    return o;
end;

return ANSIPrinter;
