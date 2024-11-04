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
--- @type uint8[]
local UINT8_TABLE = {};
local uint8_meta, rop, p;
---------------------

--- @class uint8
--- @field __table_number boolean
--- @field value number
--- @field TYPE 'uint8'
--- @field BIT_SIZE number
--- @field AND fun(self:uint8, mask: table|number): number
--- @field NAND fun(self:uint8, mask: table|number): number
--- @field OR fun(self:uint8, mask: table|number): number
--- @field XOR fun(self:uint8, mask: table|number): number
--- @field NOT fun(self:uint8, mask: table|number): number
--- @field RIGHT fun(self:uint8, offset: table|number): number
--- @field LEFT fun(self:uint8, offset: table|number): number
--- @field getValue fun(self:uint8): number
---
--- A readonly class that packages and handles arithmatic operations for unsigned int8.

uint8_meta        = {
    --________ METHODS ________--
    __add      = function(t, other) return uint8(t.value + getValue(other)) end,
    __sub      = function(t, other) return uint8(t.value - getValue(other)) end,
    __mul      = function(t, other) return uint8(t.value * getValue(other)) end,
    __div      = function(t, other) return uint8(t.value / getValue(other)) end,
    __mod      = function(t, other) return uint8(t.value % getValue(other)) end,
    __pow      = function(t, other) return uint8(t.value ^ getValue(other)) end,
    __eq       = function(t, other) return t.value == getValue(other) end,
    __lt       = function(t, other) return t.value < getValue(other) end,
    __le       = function(t, other) return t.value <= getValue(other) end,
    __concat   = function(t, other) return tostring(t) .. tostring(other) end,
    __tostring = function(t) return tostring(t.value) end,
    --_________________________--
};

-- For this type, we will map all 256 possible values to a map to optimize the use of uint8.
for i = 0, 255, 1 do
    p = {
        --_________ FLAGS _________--
        __table_number = true,
        TYPE           = 'uint8',
        BIT_SIZE       = 8,
        MIN_SIZE       = 0,
        MAX_SIZE       = 255,
        --________ FIELDS _________--
        value          = i,
        --________ METHODS ________--
        AND            = function(self, mask) return u_and(self.value, getValue(mask, 'mask'), self.BIT_SIZE) end,
        NAND           = function(self, mask) return u_nand(self.value, getValue(mask, 'mask'), self.BIT_SIZE) end,
        OR             = function(self, mask) return u_or(self.value, getValue(mask, 'mask'), self.BIT_SIZE) end,
        XOR            = function(self, mask) return u_xor(self.value, getValue(mask, 'mask'), self.BIT_SIZE) end,
        NOT            = function(self, mask) return u_not(self.value, getValue(mask, 'mask'), self.BIT_SIZE) end,
        RIGHT          = function(self, offset)
            return u_right(self.value, getValue(offset, 'offset'), self.BIT_SIZE);
        end,
        LEFT           = function(self, offset)
            return u_left(self.value, getValue(offset, 'offset'), self.BIT_SIZE);
        end,
        getValue       = function(self) return self.value end,
        --_________________________--
    };
    setmetatable(p, uint8_meta);
    rop = readonly(p);
    table.insert(UINT8_TABLE, rop);
end

--- @return uint8
uint8 = function(value) return UINT8_TABLE[(value % 255) + 1] end

--- @class UInt8
--- @field TYPE 'uint8'
--- @field BIT_SIZE number
--- @field MIN_SIZE number
--- @field MAX_SIZE number
UInt8 = {
    TYPE     = 'uint8',
    BIT_SIZE = 8,
    MIN_SIZE = 0,
    MAX_SIZE = 255
};
setmetatable(UInt8, { __call = function(value) return uint8(value) end });
UInt8 = readonly(UInt8);
