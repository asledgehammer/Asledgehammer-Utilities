---[[
--- Kahlua Table Utilities.
---
--- @author asledgehammer, JabDoesThings 2025
---]]

local readonly = require 'asledgehammer/util/readonly';

local tableutils = {};

function tableutils.isArray(t)
    local i = 0;
    for _ in pairs(t) do
        i = i + 1;
        if t[i] == nil then return false end
    end
    return true;
end

function tableutils.anyToString(v, encaseStrings)
    if encaseStrings == nil then encaseStrings = true end
    local type = type(v);
    if type == 'number' then
        return tostring(v);
    elseif type == 'boolean' then
        return tostring(v);
    elseif type == 'nil' then
        return 'nil';
    elseif type == 'table' then
        return tableutils.tableToString(v);
    else
        if encaseStrings then
            return '"' .. tostring(v) .. '"';
        else
            return tostring(v);
        end
    end
end

function tableutils.tableToString(t)
    local s = '';
    if tableutils.isArray(t) then
        for _, v in ipairs(t) do
            local vStr = tableutils.anyToString(v);
            if s == '' then s = vStr else s = s .. ',' .. vStr end
        end
    else
        for k, v in pairs(t) do
            local vStr = tableutils.anyToString(v);
            if s == '' then
                s = s .. k .. '=' .. vStr;
            else
                s = s .. ',' .. k .. '=' .. vStr;
            end
        end
    end
    return '{' .. s .. '}';
end

return readonly(tableutils);
