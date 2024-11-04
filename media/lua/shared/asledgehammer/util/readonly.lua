---[[
--- Creates a read-only object, much like frozen objects in JavaScript.
--- 
--- Example:
--- ```lua
--- local readonly = require 'readonly';
--- -- Cannot modify.
--- local object = readonly({ pi = math.PI });
--- ```
---
--- @author asledgehammer, JabDoesThings, 2024
---]]

-- Creates a read-only object, much like frozen objects in JavaScript.
-- 
-- Example:
-- 
-- local readonly = require 'readonly';
-- -- Cannot modify.
-- local object = readonly({ pi = math.PI });
--
-- 
-- @author asledgehammer, JabDoesThings 2024

local meta;
return function(table)
    meta = getmetatable(table) or {};
    return setmetatable({}, {
        __index     = table,
        __newindex  = function() error("Attempt to modify read-only class.", 2) end,
        __metatable = false,
        __add       = meta.__add,
        __sub       = meta.__sub,
        __mul       = meta.__mul,
        __div       = meta.__div,
        __mod       = meta.__mod,
        __pow       = meta.__pow,
        __eq        = meta.__eq,
        __lt        = meta.__lt,
        __le        = meta.__le,
        __concat    = meta.__concat,
        __call      = meta.__call,
        __tostring  = meta.__tostring
    });
end
