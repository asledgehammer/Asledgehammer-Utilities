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
local int16_meta, p;
---------------------

--- @class int16
--- @field __table_number boolean
--- @field value number
--- @field TYPE 'int16'
--- @field BIT_SIZE number
--- @field AND fun(self:int16, mask: table|number): number
--- @field NAND fun(self:int16, mask: table|number): number
--- @field OR fun(self:int16, mask: table|number): number
--- @field XOR fun(self:int16, mask: table|number): number
--- @field NOT fun(self:int16, mask: table|number): number
--- @field RIGHT fun(self:int16, offset: table|number): number
--- @field LEFT fun(self:int16, offset: table|number): number
--- @field getValue fun(self:int16): number
---
--- A readonly class that packages and handles arithmatic operations for signed int16.

int16_meta        = {
    --________ METHODS ________--
    __add      = function(t, other) return int16(t.value + getValue(other)) end,
    __sub      = function(t, other) return int16(t.value - getValue(other)) end,
    __mul      = function(t, other) return int16(t.value * getValue(other)) end,
    __div      = function(t, other) return int16(t.value / getValue(other)) end,
    __mod      = function(t, other) return int16(t.value % getValue(other)) end,
    __pow      = function(t, other) return int16(t.value ^ getValue(other)) end,
    __eq       = function(t, other) return t.value == getValue(other) end,
    __lt       = function(t, other) return t.value < getValue(other) end,
    __le       = function(t, other) return t.value <= getValue(other) end,
    __concat   = function(t, other) return tostring(t) .. tostring(other) end,
    __tostring = function(t) return tostring(t.value) end,
    --_________________________--
};

--- @return int16
int16             = function(value)
    p = {
        --_________ FLAGS _________--
        __table_number = true,
        TYPE           = 'int16',
        BIT_SIZE       = 0x10,
        MIN_SIZE       = -0x7FFF,
        MAX_SIZE       = 0xFFFF,
        --________ FIELDS _________--
        value          = ((getValue(value) + 0x7FFF) % 0xFFFF) - 0x7FFF,
        --________ METHODS ________--
        AND            = function(self, mask) return s_and(self.value, getValue(mask, 'mask'), 16) end,
        NAND           = function(self, mask) return s_nand(self.value, getValue(mask, 'mask'), 16) end,
        OR             = function(self, mask) return s_or(self.value, getValue(mask, 'mask'), 16) end,
        XOR            = function(self, mask) return s_xor(self.value, getValue(mask, 'mask'), 16) end,
        NOT            = function(self, mask) return s_not(self.value, getValue(mask, 'mask'), 16) end,
        RIGHT          = function(self, offset) return s_right(self.value, getValue(offset, 'offset'), 16) end,
        LEFT           = function(self, offset) return s_left(self.value, getValue(offset, 'offset'), 16) end,
        getValue       = function(self) return self.value end,
        --_________________________--
    };
    setmetatable(p, int16_meta);
    return readonly(p);
end

--- @class Int16
--- @field TYPE 'int16'
--- @field BIT_SIZE number
--- @field MIN_SIZE number
--- @field MAX_SIZE number
Int16             = {
    TYPE     = 'int16',
    BIT_SIZE = 0x10,
    MIN_SIZE = -0x7FFF,
    MAX_SIZE = 0xFFFF,
};
setmetatable(Int16, { __call = function(value) return int16(value) end });
Int16 = readonly(Int16);
