---[[
--- BITE is a last resort for Lua 5.1 (Kahlua2) bitwise support for Project Zomboid.
---
--- YES, THIS IS VERY VERY SLOW BUT BETTER THAN NOTHING AT ALL.
---
--- @author JabDoesThings, asledgehammer 2023
---]]

local BITS = 32;

--- @class bite
--- @field bcast fun(value): number Cast a value to the internally-used integer type
--- @field bnot fun(value): number Returns the one's compliment of the value.
--- @field band fun(value, ...): number Returns the bitwise AND of the values.
--- @field bor fun(value, ...): number Returns the bitwise OR of the values.
--- @field bxor fun(value, ...): number Returns the bitwise EXCLUSIVE OR of the values.
--- @field lshift fun(value, offset): number Returns value shifted by offset.
--- @field rshift fun(value, offset): number Returns value shifted logically right by offset.
--- @field arshift fun(value, offset): number Returns value shifted arithmetically right by offset.
--- @field tobit fun(value): number
--- @field tohex fun(value): string
--- @field rol fun(a, b): number
--- @field test fun(): void Tests 'bite' with 'bitlib' to see if the same results occur.

local readonly = function(table)
    local meta = getmetatable(table) or {};
    return setmetatable({}, {
        __index     = table,
        __newindex  = function() error("Attempt to modify read-only class.", 2) end,
        __metatable = false,
        __add       = meta.__add,
        __sub       = meta.__sub,
        __mul       = meta.__mul,
        __div       = meta.__div,
        __mod       = meta.__mod,
        __pow       = meta.__pow,
        __eq        = meta.__eq,
        __lt        = meta.__lt,
        __le        = meta.__le,
        __concat    = meta.__concat,
        __call      = meta.__call,
        __tostring  = meta.__tostring
    });
end

local HEX_BIN_DICTIONARY = {
    ['0'] = '0000',
    ['1'] = '0001',
    ['2'] = '0010',
    ['3'] = '0011',
    ['4'] = '0100',
    ['5'] = '0101',
    ['6'] = '0110',
    ['7'] = '0111',
    ['8'] = '1000',
    ['9'] = '1001',
    ['a'] = '1010',
    ['b'] = '1011',
    ['c'] = '1100',
    ['d'] = '1101',
    ['e'] = '1110',
    ['f'] = '1111'
};

local BIN_HEX_DICTIONARY = {
    ['0000'] = '0',
    ['0001'] = '1',
    ['0010'] = '2',
    ['0011'] = '3',
    ['0100'] = '4',
    ['0101'] = '5',
    ['0110'] = '6',
    ['0111'] = '7',
    ['1000'] = '8',
    ['1001'] = '9',
    ['1010'] = 'A',
    ['1011'] = 'B',
    ['1100'] = 'C',
    ['1101'] = 'D',
    ['1110'] = 'E',
    ['1111'] = 'F'
};

--- @param value string The hexadecimal string.
---
--- @return string binary The binary string.
local function hex2bin(value, bits, positive)
    local result = '';
    for i in string.gmatch(value, '.') do
        i = string.lower(i);
        result = result .. HEX_BIN_DICTIONARY[i];
    end
    while #result < bits do
        if positive then
            result = '0' .. result;
        else
            result = '1' .. result;
        end
    end
    return result;
end

--- @param value string The binary string.
---
--- @return string binary The hexadecimal string.
local function bin2hex(value)
    local l, result = string.len(value), '';
    local rem = (l % 4) - 1;
    -- need to prepend zeros to eliminate mod 4
    if (rem > 0) then value = string.rep('0', 4 - rem) .. value end
    for i = 1, l, 4 do result = result .. BIN_HEX_DICTIONARY[string.sub(value, i, i + 3)] end
    return result;
end

--- @param value string The binary string.
---
--- @return number
local function s_bin2dec(value)
    local isNegative = string.sub(value, 1, 1) == '1';
    local ex2 = #value - 2;
    local mRet = 0;
    for i = 2, #value, 1 do
        local charValue = string.sub(value, i, i);
        if isNegative then
            if charValue == '0' then
                mRet = mRet + math.pow(2, ex2);
            end
        else
            if charValue == '1' then
                mRet = mRet + math.pow(2, ex2);
            end
        end
        ex2 = ex2 - 1;
    end
    if isNegative then mRet = -mRet - 1 end
    return mRet;
end

--- @param value number The Base10 string.
--- @param bits number The string length to extend.
---
--- @return string binary The binary string.
local function s_dec2bin(value, bits)
    local n = bits or 0;
    local sValue = hex2bin(string.format('%x', value), BITS, value > -1);
    if string.sub(sValue, 1, 1) == '1' then
        while string.len(sValue) < n do sValue = '1' .. sValue end
    else
        while string.len(sValue) < n do sValue = '0' .. sValue end
    end
    return sValue;
end

--_________________________________________________________________--

--- @type bite
--- @diagnostic disable-next-line: missing-fields
local bite = {};

--_____________________--

--- Unknown function.
bite.rol = function() error('The function \'rol(a, b)\' is not implemented.') end

bite.tohex = function(value)
    if type(value) == 'string' then return string.format('%x', value) else return bin2hex(value) end
end

bite.tobit = function(value)
    if type(value) == 'number' then return value else return s_bin2dec(hex2bin(value)) end
end

--- Calculates the 'AND' bitwise operation for two signed values.
---
--- @param value number Either a number or NumberTable.
--- @param mask number Either a number or NumberTable.
---
--- @return number result The calculated result.
bite.band = function(value, mask) end

--- Calculates the 'OR' bitwise operation for two signed values.
---
--- @param value number Either a number or NumberTable.
--- @param mask number Either a number or NumberTable.
---
--- @return number result The calculated result.
bite.bor = function(value, mask) end

--- Calculates the 'XOR' bitwise operation for two signed values.
---
--- @param value number Either a number or NumberTable.
--- @param mask number Either a number or NumberTable.
---
--- @return number result The calculated result.
bite.bxor = function(value, mask) end

--- Calculates the 'NOT' bitwise operation for two signed values.
---
--- @param value number Either a number or NumberTable.
---
--- @return number result The calculated result.
bite.bnot = function(value) end

--- Shifts a value's bits to the left. ( x << y )
---
--- @param value number Either a number or NumberTable to be shifted.
--- @param offset number The number of bits to shift to the left.
---
--- @return number result The calculated result.
bite.lshift = function(value, offset) end

--- Shifts a value's bits to the right. ( x >> y )
---
--- @param value number Either a number or NumberTable to be shifted.
--- @param offset number The number of bits to shift to the left.
---
--- @return number result The calculated result.
bite.rshift = function(value, offset) end

--- Shifts a value's bits to the right. ( x >>> y )
---
--- @param value number Either a number or NumberTable to be shifted.
--- @param offset number The number of bits to shift to the left.
---
--- @return number result The calculated result.
bite.arshift = function(value, offset) end


if BitwiseOps then
    bite.bnot = BitwiseOps.bnot32;
    bite.band = BitwiseOps.band32;
    bite.bor = BitwiseOps.bor32;
    bite.bxor = BitwiseOps.bxor32;
    bite.lshift = BitwiseOps.lshift32;
    bite.rshift = BitwiseOps.rshift32;
    bite.arshift = BitwiseOps.arshift32;
else
    bite.band = function(value, mask)
        local bv, bm, br, cv, cm = s_dec2bin(value, BITS), s_dec2bin(mask, BITS), '', '', '';
        for i = 1, BITS do
            cv, cm = string.sub(bv, i, i), string.sub(bm, i, i);
            if cv == '1' and cm == '1' then br = br .. '1' else br = br .. '0' end
        end
        return s_bin2dec(br);
    end

    bite.bor = function(value, mask)
        local bv, bm, br, cv, cm = s_dec2bin(value, BITS), s_dec2bin(mask, BITS), '', '', '';
        for i = 1, BITS do
            cv, cm = string.sub(bv, i, i), string.sub(bm, i, i);
            if cv == '1' then br = br .. '1' elseif cm == '1' then br = br .. '1' else br = br .. '0' end
        end
        return s_bin2dec(br);
    end

    bite.bxor = function(value, mask)
        local bv, bm, br, cv, cm = s_dec2bin(value, BITS), s_dec2bin(mask, BITS), '', '', '';
        for i = 1, BITS do
            cv, cm = string.sub(bv, i, i), string.sub(bm, i, i);
            if cv == '1' then
                if cm == '0' then br = br .. '1' else br = br .. '0' end
            elseif cm == '1' then
                if cv == '0' then br = br .. '1' else br = br .. '0' end
            else
                br = br .. '0'
            end
        end
        return s_bin2dec(br);
    end

    bite.bnot = function(value)
        local bv, br = s_dec2bin(value, BITS), '';
        for i = 1, BITS do
            if string.sub(bv, i, i) == '1' then br = br .. '0' else br = br .. '1' end
        end
        return s_bin2dec(br);
    end

    bite.lshift = function(value, offset)
        if offset >= BITS then return 0 elseif offset <= 0 then return value end
        local bv = s_dec2bin(value, BITS);
        local br = string.sub(bv, offset + 1);
        while #br < BITS do br = br .. '0' end
        return s_bin2dec(br);
    end

    bite.rshift = function(value, offset)
        if offset >= BITS then return 0 elseif offset <= 0 then return value end
        local bv = s_dec2bin(value, BITS);
        local br = string.sub(bv, 1, BITS - offset);
        while (string.len(br) < BITS) do br = '0' .. br end
        return s_bin2dec(br);
    end

    bite.arshift = function(value, offset)
        if offset >= BITS then return 0 elseif offset <= 0 then return value end
        local bv = s_dec2bin(value, BITS);
        local br, b1 = string.sub(bv, 1, BITS - offset), string.sub(bv, 1, 1);
        while (string.len(br) < BITS) do br = b1 .. br end
        return s_bin2dec(br);
    end
end

return readonly(bite);
