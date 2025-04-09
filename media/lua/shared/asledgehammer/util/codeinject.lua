---[[
--- Kahlua Code injection utility to insert code into loadstring'd code.
---
--- @author asledgehammer, JabDoesThings 2025
---]]

local tableutils = require 'asledgehammer/util/tableutils';

--- @param code string
--- @param vars table<string, {type: 'raw'|'function'|'func'|'table'|'number'|'string', value: any}>
---
--- @return string
return function (code, vars)
    for id, var in pairs(vars) do
        if var.type == 'function' or var.type == 'func' then
            local literalValue = 'loadstring("' .. string.gsub(var.value, '"', '\\"') .. '")()';
            code = string.gsub(code, '{%s*func%s*=%s*"' .. id .. '"%s*}', literalValue);
            code = string.gsub(code, "{%s*func%s*=%s*'" .. id .. "'%s*}", literalValue);
        elseif var.type == 'table' then
            if type(var.value) == 'string' then
                local literalValue = 'loadstring("' .. string.gsub(var.value, '"', '\\"') .. '")()';
                code = string.gsub(code, '{%s*table%s*=%s*"' .. id .. '"%s*}', literalValue);
                code = string.gsub(code, "{%s*table%s*=%s*'" .. id .. "'%s*}", literalValue);
            elseif type(var.value) == 'table' then
                local literalValue = tableutils.tableToString(var.value);
                code = string.gsub(code, '{%s*table%s*=%s*"' .. id .. '"%s*}', literalValue);
                code = string.gsub(code, "{%s*table%s*=%s*'" .. id .. "'%s*}", literalValue);
            end
        elseif var.type == 'number' then
            local literalValue = tostring(var.value);
            code = string.gsub(code, '{%s*number%s*=%s*"' .. id .. '"%s*}', literalValue);
            code = string.gsub(code, "{%s*number%s*=%s*'" .. id .. "'%s*}", literalValue);
        elseif var.type == 'boolean' then
            local literalValue = tostring(var.value);
            code = string.gsub(code, '{%s*boolean%s*=%s*"' .. id .. '"%s*}', literalValue);
            code = string.gsub(code, "{%s*boolean%s*=%s*'" .. id .. "'%s*}", literalValue);
        elseif var.type == 'raw' then
            local literalValue = tostring(var.value);
            code = string.gsub(code, '{%s*raw%s*=%s*"' .. id .. '"%s*}', literalValue);
            code = string.gsub(code, "{%s*raw%s*=%s*'" .. id .. "'%s*}", literalValue);
        else
            local literalValue = '"' .. tostring(var.value) .. '"';
            code = string.gsub(code, '{%s*%w+%s*=%s*"' .. id .. '"%s*}', literalValue);
            code = string.gsub(code, "{%s*%w+%s*=%s*'" .. id .. "'%s*}", literalValue);
        end
    end
    return code;
end;
