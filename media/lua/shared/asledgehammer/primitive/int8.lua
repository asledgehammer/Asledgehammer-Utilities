---[[
--- @author asledgehammer, JabDoesThings, 2024
---]]

local readonly    = require 'asledgehammer/util/readonly';
local bite        = require 'asledgehammer/math/bite';
local TableNumber = require 'asledgehammer/math/TableNumber';
local s_and       = bite.s_and;
local s_nand      = bite.s_nand;
local s_or        = bite.s_or;
local s_xor       = bite.s_xor;
local s_not       = bite.s_not;
local s_left      = bite.s_left;
local s_right     = bite.s_right;
local getValue    = TableNumber.getValue;

-- LOCAL VARIABLES --
--- @type int8[]
local INT8_TABLE  = {};
local rop, p;
---------------------

--- A readonly class that packages and handles arithmatic operations for unsigned int8.
local int8_meta   = {
    --________ METHODS ________--
    __add      = function(t, other) return int8(t.value + getValue(other)) end,
    __sub      = function(t, other) return int8(t.value - getValue(other)) end,
    __mul      = function(t, other) return int8(t.value * getValue(other)) end,
    __div      = function(t, other) return int8(t.value / getValue(other)) end,
    __mod      = function(t, other) return int8(t.value % getValue(other)) end,
    __pow      = function(t, other) return int8(t.value ^ getValue(other)) end,
    __eq       = function(t, other) return t.value == getValue(other) end,
    __lt       = function(t, other) return t.value < getValue(other) end,
    __le       = function(t, other) return t.value <= getValue(other) end,
    __concat   = function(t, other) return tostring(t) .. tostring(other) end,
    __tostring = function(t) return tostring(t.value) end,
    --_________________________--
};

-- For this type, we will map all 256 possible values to a map to optimize the use of int8.
for i = 0, 255, 1 do
    p = {
        --_________ FLAGS _________--
        __table_number = true,
        TYPE           = 'int8',
        BIT_SIZE       = 8,
        MIN_SIZE       = -127,
        MAX_SIZE       = 128,
        --________ FIELDS _________--
        value          = i - 127,
        --________ METHODS ________--
        AND            = function(self, mask) return s_and(self.value, getValue(mask, 'mask'), 8) end,
        NAND           = function(self, mask) return s_nand(self.value, getValue(mask, 'mask'), 8) end,
        OR             = function(self, mask) return s_or(self.value, getValue(mask, 'mask'), 8) end,
        XOR            = function(self, mask) return s_xor(self.value, getValue(mask, 'mask'), 8) end,
        NOT            = function(self, mask) return s_not(self.value, getValue(mask, 'mask'), 8) end,
        RIGHT          = function(self, offset) return s_right(self.value, getValue(offset, 'offset'), 8) end,
        LEFT           = function(self, offset) return s_left(self.value, getValue(offset, 'offset'), 8) end,
        getValue       = function(self) return self.value end,
        --_________________________--
    };
    setmetatable(p, int8_meta);
    rop = readonly(p);
    table.insert(INT8_TABLE, rop);
end

--- @return int8
int8 = function(value) return INT8_TABLE[((value + 127) % 255) + 1] end

Int8 = {
    TYPE     = 'int8',
    BIT_SIZE = 8,
    MIN_SIZE = -127,
    MAX_SIZE = 128
};
setmetatable(Int8, { __call = function(value) return int8(value) end });
Int8 = readonly(Int8);
