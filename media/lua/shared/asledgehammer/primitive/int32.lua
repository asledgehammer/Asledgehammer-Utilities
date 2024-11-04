---[[
--- @author asledgehammer, JabDoesThings, 2024
---]]

local readonly    = require 'asledgehammer/util/readonly';
local bite        = require 'asledgehammer/util/bite';
local TableNumber = require 'asledgehammer/util/TableNumber';
local s_and       = bite.s_and;
local s_nand      = bite.s_nand;
local s_or        = bite.s_or;
local s_xor       = bite.s_xor;
local s_not       = bite.s_not;
local s_left      = bite.s_left;
local s_right     = bite.s_right;
local getValue    = TableNumber.getValue;

-- LOCAL VARIABLES --
local int32_meta, p;
---------------------

--- @class int32
--- @field __table_number boolean
--- @field value number
--- @field TYPE 'int32's
--- @field BIT_SIZE number
--- @field AND fun(self:uint32, mask: table|number): number
--- @field NAND fun(self:uint32, mask: table|number): number
--- @field OR fun(self:uint32, mask: table|number): number
--- @field XOR fun(self:uint32, mask: table|number): number
--- @field NOT fun(self:uint32, mask: table|number): number
--- @field RIGHT fun(self:uint32, offset: table|number): number
--- @field LEFT fun(self:uint32, offset: table|number): number
--- @field getValue fun(self:uint32): number
---
--- A readonly class that packages and handles arithmatic operations for signed int32.

int32_meta        = {
    --________ METHODS ________--
    __add      = function(t, other) return int32(t.value + getValue(other)) end,
    __sub      = function(t, other) return int32(t.value - getValue(other)) end,
    __mul      = function(t, other) return int32(t.value * getValue(other)) end,
    __div      = function(t, other) return int32(t.value / getValue(other)) end,
    __mod      = function(t, other) return int32(t.value % getValue(other)) end,
    __pow      = function(t, other) return int32(t.value ^ getValue(other)) end,
    __eq       = function(t, other) return t.value == getValue(other) end,
    __lt       = function(t, other) return t.value < getValue(other) end,
    __le       = function(t, other) return t.value <= getValue(other) end,
    __concat   = function(t, other) return tostring(t) .. tostring(other) end,
    __tostring = function(t) return tostring(t.value) end,
    --_________________________--
};

--- @param value number|table
---
--- @return int32
int32             = function(value)
    p = {
        --_________ FLAGS _________--
        __table_number = true,
        TYPE           = 'int32',
        BIT_SIZE       = 32,
        MIN_SIZE       = -2147483647,
        MAX_SIZE       = 2147483648,
        --________ FIELDS _________--
        value          = ((getValue(value) + 2147483647) % 4294967295) - 2147483647,
        --________ METHODS ________--
        AND            = function(self, mask) return s_and(self.value, getValue(mask, 'mask'), 32) end,
        NAND           = function(self, mask) return s_nand(self.value, getValue(mask, 'mask'), 32) end,
        OR             = function(self, mask) return s_or(self.value, getValue(mask, 'mask'), 32) end,
        XOR            = function(self, mask) return s_xor(self.value, getValue(mask, 'mask'), 32) end,
        NOT            = function(self, mask) return s_not(self.value, getValue(mask, 'mask'), 32) end,
        RIGHT          = function(self, offset) return s_right(self.value, getValue(offset, 'offset'), 32) end,
        LEFT           = function(self, offset) return s_left(self.value, getValue(offset, 'offset'), 32) end,
        getValue       = function(self) return self.value end,
        --_________________________--
    };
    setmetatable(p, int32_meta);
    return readonly(p);
end

--- @class Int32
--- @field TYPE 'int32'
--- @field BIT_SIZE number
--- @field MIN_SIZE number
--- @field MAX_SIZE number
Int32             = {
    TYPE     = 'int32',
    BIT_SIZE = 32,
    MIN_SIZE = -2147483647,
    MAX_SIZE = 2147483648,
};
setmetatable(Int32, { __call = function(value) return int32(value) end });
Int32 = readonly(Int32);
