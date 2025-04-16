--- @meta asledgehammer_utilities.math.TableNumber

---[[
--- @author JabDoesThings, asledgehammer 2025
---]]

--- @class TableNumber A pseudo-number table that is used to evaluate arethmatic instructions with data-size and value-range constraints.
local TableNumber = {};

--- Grabs the value from a TableNumber or returns the value as a number.
---
--- @param value number|table Either a native Lua number or a TableNumber-stored value.
--- @param name string? (Default is 'value')
---
--- @return number value The native Lua number representing the TableNumber's stored value.
function TableNumber.getValue(value, name) end

--- @param value number|table The value to test. (Must be a number or TableNumber)
---
--- @return number bitCount The number of bits the value needs to store itself.
function TableNumber.getBitCount(value) end

--- @param value any The value to check, preferably a table.
---
--- @return boolean result True if the value is a NumberTable.
function TableNumber.isTableNumber(value) end
