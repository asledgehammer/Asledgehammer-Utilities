---[[
--- @author JabDoesThings, asledgehammer 2024
---]]

local readonly = require 'asledgehammer/util/readonly';

--- The Default amount of steps for coroutine-processing.
--- NOTE: If isServer(), the value is multiplied by 8. (Server TPS is way lower than clients)
--- @type number
local DEFAULT_STEPS = 128;
if isServer() then
    DEFAULT_STEPS = DEFAULT_STEPS * 8;
end

--- @param str string
---
--- @return number[]
local function expand(str)
    if type(str) ~= 'string' then
        error('Cannot expand key. (Not string. type: ' .. tostring(type(str)) .. ')');
    end
    local a = {};
    for b = 1, #str do table.insert(a, string.byte(string.sub(str, b, b)) + 255) end
    return a;
end

local ZedCrypt = {};

--- @param data string
--- @param key string
---
--- @return string
function ZedCrypt.encrypt(data, key)
    local a = '';
    local b = 1;
    local c = expand(key);
    for d = 1, #data do
        local e = c[b];
        b = b + 1;
        if b > #c then b = 1 end
        local f = string.sub(data, d, d);
        local g = string.byte(f);
        f = string.char(g + e);
        a = a .. f;
    end
    return a;
    -- return data;
end

--- @param data string
--- @param key string
--- @param steps number (Default: 128 steps per tick)
---
--- @return thread
function ZedCrypt.encryptAsync(data, key, steps)
    steps = steps or DEFAULT_STEPS;

    local routine = function()
        local a = '';
        local b = 1;
        local c = expand(key);
        local h = 0;
        for d = 1, #data do
            local e = c[b];
            b = b + 1;
            if b > #c then b = 1 end
            local f = string.sub(data, d, d);
            local g = string.byte(f);
            f = string.char(g + e);
            a = a .. f;

            -- (Coroutine step)
            h = h + 1;
            if h == steps then
                h = 0;
                -- coroutine.yield();
            end
        end
        return a;
        -- return data;
    end
    return coroutine.create(routine);
end

--- @param data string
--- @param key string
---
--- @return string
function ZedCrypt.decrypt(data, key)
    local a = '';
    local b = 1;
    local c = expand(key);
    for d = 1, #data do
        local e = c[b];
        b = b + 1;
        if b > #c then b = 1 end
        local f = string.sub(data, d, d);
        local g = string.byte(f);
        f = string.char(g - e);
        a = a .. f;
    end
    return a;
    -- return data;
end

--- @param data string
--- @param key string
--- @param steps number (Default: 128 steps per tick)
---
--- @return thread
function ZedCrypt.decryptAsync(data, key, steps)
    steps = steps or DEFAULT_STEPS;

    local routine = function()
        local a = '';
        local b = 1;
        local c = expand(key);
        local h = 0;
        for d = 1, #data do
            local e = c[b];
            b = b + 1;
            if b > #c then b = 1 end
            local f = string.sub(data, d, d);
            local g = string.byte(f);
            f = string.char(g - e);
            a = a .. f;

            -- (Coroutine step)
            h = h + 1;
            if h == steps then
                h = 0;
                -- coroutine.yield();
            end
        end
        return a;
        -- return data;
    end

    return coroutine.create(routine);
end

return readonly(ZedCrypt);
