local TableNumber = {};

--- Grabs the value from a TableNumber or returns the value as a number.
---
--- @param value number|table
--- @param name string? (Default is 'value')
--- @return number value
TableNumber.getValue = function(value, name)
    if not name then name = 'value' end
    if type(value) == 'table' then
        if not value.__table_number then
            error("The '" .. name .. "' value is a table but isn't a TableNumber.", 2);
        end
        return value.value;
    elseif type(value) ~= 'number' then
        error("The '" .. name .. "' value is not a TableNumber or a number.");
    end
    return value;
end

--- @param value number|table The value to test. (Must be a number or TableNumber)
--- @return number The number of bits the value needs to store itself.
function TableNumber.getBitCount(value)
    local sType = type(value);
    if sType ~= 'number' and sType ~= table then
        error("The 'value' is not a number. (type: " .. sType .. ")", 2);
    elseif value < 0 then
        error("The 'value' is signed and cannot be used in an unsigned function.", 2);
    end
    if sType == 'table' then
        if not value.__table_number then
            error('Not a valid number or TableNumber.', 2);
        end
        value = value.__bit_count;
    end
    if value <= 255 then return 8 end
    if value <= 65535 then return 16 end
    if value <= 4294967295 then return 32 end
    return 64;
end

---@param value any The value to check, preferably a table.
---@return boolean result True if the value is a NumberTable.
function TableNumber.isTableNumber(value)
    return type(value) == 'table' and value.__table_number;
end

return TableNumber;
