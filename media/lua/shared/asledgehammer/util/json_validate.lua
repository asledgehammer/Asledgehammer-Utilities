local readonly = require 'asledgehammer/util/readonly';

local json = { _version = "0.1.2" };
local escape_char_map = {
    ["\\"] = "\\",
    ["\""] = "\"",
    ["\b"] = "b",
    ["\f"] = "f",
    ["\n"] = "n",
    ["\r"] = "r",
    ["\t"] = "t",
};

local escape_char_map_inv = { ["/"] = "/" };
for k, v in pairs(escape_char_map) do escape_char_map_inv[v] = k end

local parse;

local function create_set(...)
    local res = {};
    for i = 1, select("#", ...) do
        res[select(i, ...)] = true;
    end
    return res;
end

local space_chars  = create_set(" ", "\t", "\r", "\n");
local delim_chars  = create_set(" ", "\t", "\r", "\n", "]", "}", ",");
local escape_chars = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u");
local literals     = create_set("true", "false", "null");
local literal_map  = {
    ["true"] = true,
    ["false"] = false,
    ["null"] = nil,
};

local function next_char(str, idx, set, negate)
    for i = idx, #str do
        if set[str:sub(i, i)] ~= negate then
            return i;
        end
    end
    return #str + 1;
end

--- @param str string
--- @param idx number
--- @param msg string
---
--- @return boolean, table
local function decode_error(str, idx, msg)
    local line_count = 1;
    local col_count = 1;
    for i = 1, idx - 1 do
        col_count = col_count + 1;
        if str:sub(i, i) == "\n" then
            line_count = line_count + 1;
            col_count = 1;
        end
    end
    return false, { error = string.format("%s at line %d col %d", msg, line_count, col_count) };
end

--- @param n number
---
--- @return boolean, table
local function codepoint_to_utf8(n)
    local f = math.floor;
    if n <= 0x7f then
        return true, { char = string.char(n) };
    elseif n <= 0x7ff then
        return true, { char = string.char(f(n / 64) + 192, n % 64 + 128) };
    elseif n <= 0xffff then
        return true, { char = string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128) };
    elseif n <= 0x10ffff then
        return true, {
            char = string.char(
                f(n / 262144) + 240,
                f(n % 262144 / 4096) + 128,
                f(n % 4096 / 64) + 128, n % 64 + 128
            )
        };
    end
    return false, { error = string.format("invalid unicode codepoint '%x'", n) };
end

--- @param s string
---
--- @return boolean, table
local function parse_unicode_escape(s)
    local n1 = tonumber(s:sub(1, 4), 16);
    local n2 = tonumber(s:sub(7, 10), 16);
    -- Surrogate pair?
    if n2 then
        return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000);
    else
        return codepoint_to_utf8(n1);
    end
end

--- @param str string
--- @param i number
--- @return boolean, table
local function parse_string(str, i)
    local res = "";
    local j = i + 1;
    local k = j;
    while j <= #str do
        local x = str:byte(j);
        if x < 32 then
            return decode_error(str, j, "control character in string");
        elseif x == 92 then -- `\`: Escape
            res = res .. str:sub(k, j - 1);
            j = j + 1;
            local c = str:sub(j, j);
            if c == "u" then
                local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1) or str:match("^%x%x%x%x", j + 1);
                if not hex then return decode_error(str, j - 1, "invalid unicode escape in string") end
                local pue, puet = parse_unicode_escape(hex);
                if puet.error then
                    return pue, puet;
                end
                res = res .. puet.char;
                j = j + #hex;
            else
                if not escape_chars[c] then
                    return decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string");
                end
                res = res .. escape_char_map_inv[c];
            end
            k = j + 1;
        elseif x == 34 then -- `"`: End of string
            res = res .. str:sub(k, j - 1);
            return true, { res = res, i = j + 1 };
        end

        j = j + 1;
    end

    return decode_error(str, i, "expected closing quote for string");
end

--- @param str string
--- @param i number
--- @return boolean, table
local function parse_number(str, i)
    local x = next_char(str, i, delim_chars);
    local s = str:sub(i, x - 1);
    local n = tonumber(s);
    if not n then
        return decode_error(str, i, "invalid number '" .. s .. "'");
    end
    return true, { res = n, i = x };
end

--- @param str string
--- @param i number
--- @return boolean, table
local function parse_literal(str, i)
    local x = next_char(str, i, delim_chars);
    local word = str:sub(i, x - 1);
    if not literals[word] then
        return decode_error(str, i, "invalid literal '" .. word .. "'");
    end
    return true, { res = literal_map[word], i = x };
end

--- @param str string
--- @param i number
--- @return boolean, table
local function parse_array(str, i)
    local result, tbl;
    local res = {};
    local n = 1;
    i = i + 1;
    while 1 do
        local x;
        i = next_char(str, i, space_chars, true);
        -- Empty / end of array?
        if str:sub(i, i) == "]" then
            i = i + 1;
            break;
        end
        -- Read token
        result, tbl = parse(str, i);
        if not result then return false, tbl end
        x = tbl.res;
        i = tbl.i;
        res[n] = x;
        n = n + 1;
        -- Next token
        i = next_char(str, i, space_chars, true);
        local chr = str:sub(i, i);
        i = i + 1;
        if chr == "]" then break end
        if chr ~= "," then return decode_error(str, i, "expected ']' or ','") end
    end
    return true, { res = res, i = i };
end

--- @param str string
--- @param i number
--- @return boolean, table
local function parse_object(str, i)
    local result, tbl;
    local res = {};
    i = i + 1;
    while 1 do
        local key, val;
        i = next_char(str, i, space_chars, true);
        -- Empty / end of object?
        if str:sub(i, i) == "}" then
            i = i + 1;
            break;
        end
        -- Read key
        if str:sub(i, i) ~= '"' then
            return decode_error(str, i, "expected string for key");
        end
        result, tbl = parse(str, i);
        if not result then return result, tbl end
        key = tbl.res;
        i = tbl.i;

        -- Read ':' delimiter
        i = next_char(str, i, space_chars, true);
        if str:sub(i, i) ~= ":" then
            return decode_error(str, i, "expected ':' after key")
        end
        i = next_char(str, i + 1, space_chars, true);
        -- Read value
        result, tbl = parse(str, i);
        if not result then return result, tbl end
        val = tbl.res;
        i = tbl.i;
        -- Set
        res[key] = val;
        -- Next token
        i = next_char(str, i, space_chars, true);
        local chr = str:sub(i, i);
        i = i + 1;
        if chr == "}" then break end
        if chr ~= "," then return decode_error(str, i, "expected '}' or ','") end
    end
    return true, { res = res, i = i };
end

--- @type table<string, fun(a: string, b: number): boolean, table>
local char_func_map = {
    ['"'] = parse_string,
    ["0"] = parse_number,
    ["1"] = parse_number,
    ["2"] = parse_number,
    ["3"] = parse_number,
    ["4"] = parse_number,
    ["5"] = parse_number,
    ["6"] = parse_number,
    ["7"] = parse_number,
    ["8"] = parse_number,
    ["9"] = parse_number,
    ["-"] = parse_number,
    ["t"] = parse_literal,
    ["f"] = parse_literal,
    ["n"] = parse_literal,
    ["["] = parse_array,
    ["{"] = parse_object,
}

---@param str string
---@param idx number
---@return boolean, table
parse = function(str, idx)
    local chr = str:sub(idx, idx);
    local f = char_func_map[chr];
    if f then
        return f(str, idx);
    end
    return decode_error(str, idx, "unexpected character '" .. chr .. "'");
end

--- @param str string
---
--- @return boolean, table?
function json.parse(str)
    if type(str) ~= "string" then
        return false, { error = "expected argument of type string, got " .. type(str) };
    end

    local result, tbl = parse(str, next_char(str, 1, space_chars, true));
    if not result then return result, tbl end
    local res, idx = tbl.res, tbl.i;

    idx = next_char(str, idx, space_chars, true);
    if idx <= #str then
        return decode_error(str, idx, "trailing garbage");
    end
    return true;
end

--- @param str string
---
--- @return boolean result True if valid JSON.
function json.validate(str)
    if not string.match(str, '%{', 1) and not string.match(str, '%[', 1) then
        return false;
    end
    return json.parse(str);
end

return readonly(json);
