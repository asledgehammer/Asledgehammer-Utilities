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
local uint32_meta, p;
---------------------

--- @class uint32
--- @field __table_number boolean
--- @field value number
--- @field TYPE 'uint32'
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
--- A readonly class that packages and handles arithmatic operations for unsigned int32.

uint32_meta       = {
    --________ METHODS ________--
    __add      = function(t, other) return uint32(t.value + getValue(other)) end,
    __sub      = function(t, other) return uint32(t.value - getValue(other)) end,
    __mul      = function(t, other) return uint32(t.value * getValue(other)) end,
    __div      = function(t, other) return uint32(t.value / getValue(other)) end,
    __mod      = function(t, other) return uint32(t.value % getValue(other)) end,
    __pow      = function(t, other) return uint32(t.value ^ getValue(other)) end,
    __eq       = function(t, other) return t.value == getValue(other) end,
    __lt       = function(t, other) return t.value < getValue(other) end,
    __le       = function(t, other) return t.value <= getValue(other) end,
    __concat   = function(t, other) return tostring(t) .. tostring(other) end,
    __tostring = function(t) return tostring(t.value) end,
    --_________________________--
};

--- @param value number|table
---
--- @return uint32
uint32            = function(value)
    p = {
        --_________ FLAGS _________--
        __table_number = true,
        TYPE           = 'uint32',
        BIT_SIZE       = 32,
        MIN_SIZE       = 0,
        MAX_SIZE       = 4294967295,
        --________ FIELDS _________--
        value          = getValue(value) % 4294967295,
        --________ METHODS ________--
        AND            = function(self, mask) return u_and(self.value, getValue(mask, 'mask'), 32) end,
        NAND           = function(self, mask) return u_nand(self.value, getValue(mask, 'mask'), 32) end,
        OR             = function(self, mask) return u_or(self.value, getValue(mask, 'mask'), 32) end,
        XOR            = function(self, mask) return u_xor(self.value, getValue(mask, 'mask'), 32) end,
        NOT            = function(self, mask) return u_not(self.value, getValue(mask, 'mask'), 32) end,
        RIGHT          = function(self, offset) return u_right(self.value, getValue(offset, 'offset'), 32) end,
        LEFT           = function(self, offset) return u_left(self.value, getValue(offset, 'offset'), 32) end,
        getValue       = function(self) return self.value end,
        --_________________________--
    };
    setmetatable(p, uint32_meta);
    return readonly(p);
end

--- @class UInt32
--- @field TYPE 'uint32'
--- @field BIT_SIZE number
--- @field MIN_SIZE number
--- @field MAX_SIZE number
UInt32            = {
    TYPE     = 'uint32',
    BIT_SIZE = 32,
    MIN_SIZE = 0,
    MAX_SIZE = 4294967295,
};
setmetatable(UInt32, { __call = function(value) return uint32(value) end });
UInt32 = readonly(UInt32);
