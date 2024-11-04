---[[
--- @author asledgehammer, JabDoesThings, 2024
---]]

local readonly    = require 'asledgehammer/util/readonly';
local bite        = require 'asledgehammer/util/bite';
local TableNumber = require 'asledgehammer/util/TableNumber';
local u_and       = bite.u_and;
local u_nand      = bite.u_nand;
local u_or        = bite.u_or;
local u_xor       = bite.u_xor;
local u_not       = bite.u_not;
local u_left      = bite.u_left;
local u_right     = bite.u_right;
local getValue    = TableNumber.getValue;

-- LOCAL VARIABLES --
local uint16_meta, p;
---------------------

--- @class uint16
--- @field __table_number boolean
--- @field value number
--- @field TYPE 'uint16'
--- @field BIT_SIZE number
--- @field AND fun(self:uint16, mask: table|number): number
--- @field NAND fun(self:uint16, mask: table|number): number
--- @field OR fun(self:uint16, mask: table|number): number
--- @field XOR fun(self:uint16, mask: table|number): number
--- @field NOT fun(self:uint16, mask: table|number): number
--- @field RIGHT fun(self:uint16, offset: table|number): number
--- @field LEFT fun(self:uint16, offset: table|number): number
--- @field getValue fun(self:uint16): number
---
--- A readonly class that packages and handles arithmatic operations for unsigned int16.

uint16_meta       = {
    --________ METHODS ________--
    __add      = function(t, other) return uint16(t.value + getValue(other)) end,
    __sub      = function(t, other) return uint16(t.value - getValue(other)) end,
    __mul      = function(t, other) return uint16(t.value * getValue(other)) end,
    __div      = function(t, other) return uint16(t.value / getValue(other)) end,
    __mod      = function(t, other) return uint16(t.value % getValue(other)) end,
    __pow      = function(t, other) return uint16(t.value ^ getValue(other)) end,
    __eq       = function(t, other) return t.value == getValue(other) end,
    __lt       = function(t, other) return t.value < getValue(other) end,
    __le       = function(t, other) return t.value <= getValue(other) end,
    __concat   = function(t, other) return tostring(t) .. tostring(other) end,
    __tostring = function(t) return tostring(t.value) end,
    --_________________________--
};

--- @return uint16
uint16            = function(value)
    p = {
        --_________ FLAGS _________--
        __table_number = true,
        TYPE           = 'uint16',
        BIT_SIZE       = 16,
        MIN_SIZE       = 0,
        MAX_SIZE       = 65535,
        --________ FIELDS _________--
        value          = getValue(value) % 65535,
        --________ METHODS ________--
        AND            = function(self, mask) return u_and(self.value, getValue(mask, 'mask'), 16) end,
        NAND           = function(self, mask) return u_nand(self.value, getValue(mask, 'mask'), 16) end,
        OR             = function(self, mask) return u_or(self.value, getValue(mask, 'mask'), 16) end,
        XOR            = function(self, mask) return u_xor(self.value, getValue(mask, 'mask'), 16) end,
        NOT            = function(self, mask) return u_not(self.value, getValue(mask, 'mask'), 16) end,
        RIGHT          = function(self, offset) return u_right(self.value, getValue(offset, 'offset'), 16) end,
        LEFT           = function(self, offset) return u_left(self.value, getValue(offset, 'offset'), 16) end,
        getValue       = function(self) return self.value end,
        --_________________________--
    };
    setmetatable(p, uint16_meta);
    return readonly(p);
end

--- @class UInt16
--- @field TYPE 'uint16'
--- @field BIT_SIZE number
--- @field MIN_SIZE number
--- @field MAX_SIZE number
UInt16            = {
    TYPE     = 'uint16',
    BIT_SIZE = 16,
    MIN_SIZE = 0,
    MAX_SIZE = 65535,
};
setmetatable(UInt16, { __call = function(value) return uint16(value) end });
UInt16 = readonly(UInt16);
