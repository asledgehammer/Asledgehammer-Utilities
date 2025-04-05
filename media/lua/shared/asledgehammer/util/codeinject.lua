local function isArray(t)
    local i = 0;
    for _ in pairs(t) do
        i = i + 1;
        if t[i] == nil then return false end
    end
    return true;
end

--- @type fun(t: table): string
local tableToString;
--- @type fun(v: any): string
local anyToString;

anyToString = function(v, encaseStrings)
    if encaseStrings == nil then encaseStrings = true end
    local type = type(v);
    if type == 'number' then
        return tostring(v);
    elseif type == 'boolean' then
        return tostring(v);
    elseif type == 'nil' then
        return 'nil';
    elseif type == 'table' then
        return tableToString(v);
    else
        if encaseStrings then
            return '"' .. tostring(v) .. '"';
        else
            return tostring(v);
        end
    end
end

tableToString = function(t)
    local s = '';
    if isArray(t) then
        for _, v in ipairs(t) do
            local vStr = anyToString(v);
            if s == '' then s = vStr else s = s .. ',' .. vStr end
        end
    else
        for k, v in pairs(t) do
            local vStr = anyToString(v);
            if s == '' then
                s = s .. k .. '=' .. vStr;
            else
                s = s .. ',' .. k .. '=' .. vStr;
            end
        end
    end
    return '{' .. s .. '}';
end

--- @param code string
--- @param vars table<string, {type: 'raw'|'function'|'func'|'table'|'number'|'string', value: any}>
---
--- @return string
return function(code, vars)
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
                local literalValue = tableToString(var.value);
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
