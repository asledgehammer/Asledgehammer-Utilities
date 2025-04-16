--- @meta asledgehammer_utilities.primitive.Int8

---[[
--- @author JabDoesThings, asledgehammer 2025
---]]

--- @class int8: TableNumber
--- @field __table_number true
--- @field value number
--- @field TYPE 'int8'
--- @field BIT_SIZE number 8
--- @field AND fun(self:int8, mask: table|number): number
--- @field NAND fun(self:int8, mask: table|number): number
--- @field OR fun(self:int8, mask: table|number): number
--- @field XOR fun(self:int8, mask: table|number): number
--- @field NOT fun(self:int8, mask: table|number): number
--- @field RIGHT fun(self:int8, offset: table|number): number
--- @field LEFT fun(self:int8, offset: table|number): number
--- @field getValue fun(self:int8): number
local int8 = {};

--- @class Int8
--- @field TYPE 'int8'
--- @field BIT_SIZE number 8
--- @field MIN_SIZE number -127
--- @field MAX_SIZE number 128
local Int8 = {};
