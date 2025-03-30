--- MARK: Constants
--- @alias IndexRange [number, number]

--- [Open Block] -> [Not Close Block]* -> [Close Block]
local STRING_PATTERN_BLOCK_COMMENT = '%-[%-]+%[%[' .. '.*' .. '%-[%-]+%]%]';
local STRING_PATTERN_LINE_COMMENT = '%-[%-]+[^\n]*\n';
local STRING_PATTERN_SINGLE_QUOTE_STRINGS = "'[^'\n]*'";
local STRING_PATTERN_DOUBLE_QUOTE_STRINGS = '"[^"\n]*"';

local CHAR_SEQUENCE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

if not instanceof then
    math.randomseed(os.time());
end

--- MARK: Utilities

--- Scrambles a random set of characters between a minimum and maximum length.
---
--- @param minChars number The minimum (or exact) number of characters to generate.
--- @param maxChars? number (Optional) The maximum number of characters to generate.
---
--- @return string result The result-generated characters.
local function randomstring(minChars, maxChars)
    -- Set if optional.
    if not maxChars then
        maxChars = minChars;
    end
    if minChars < 1 then
        error('Cannot set minChars to less than 1.');
    elseif maxChars < 1 then
        error('Cannot set maxChars to less than 1.');
    elseif maxChars < minChars then
        error('Cannot set maxChars to be less than minChars.');
    end
    --- @type string
    local result = '';
    --- @type number
    local sequenceLength = #CHAR_SEQUENCE;
    -- (Non-PZ Code)
    if not ZombRand then
        math.random(5);
    end
    --- The generated length of the scrambled result.
    ---
    --- @type number
    local lengthChars = minChars;
    if maxChars > minChars then
        local deltaChars = maxChars - minChars;
        if not ZombRand then
            -- (Non-PZ Code)
            local noise = math.random(deltaChars);
            lengthChars = minChars + noise;
        else
            lengthChars = minChars + math.floor(ZombRand(deltaChars));
        end
    end
    for _ = 1, lengthChars do
        --- @type number
        local index = 0;
        if ZombRand then
            index = math.floor(ZombRand(sequenceLength));
        else
            -- (Non-PZ Code)
            index = math.random(sequenceLength);
        end
        result = result .. string.sub(CHAR_SEQUENCE, index, index);
    end
    return result;
end

-- Inhibit Regular Expression magic characters ^$()%.[]*+-?)
local function strPlainText(strText)
    -- Prefix every non-alphanumeric character (%W) with a % escape character,
    -- where %% is the % escape, and %1 is original character
    return strText:gsub("(%W)", "%%%1")
end

local function arrayToString(array)
    local s = '';
    for i, v in pairs(array) do
        if s == '' then
            s = tostring(v);
        else
            s = s .. ',' .. tostring(v);
        end
    end
    return '[' .. s .. ']';
end

--- @param str string
--- @param ranges IndexRange[]
local printRanges = function(str, ranges)
    for i, v in ipairs(ranges) do
        print(i .. ': ' .. arrayToString(v) .. ' (' .. string.sub(str, v[1], v[2]) .. ')');
    end
end

--- @param ranges IndexRange[]
--- @param range IndexRange
---
--- @return boolean result
local insideRange = function(ranges, range)
    for _, r in ipairs(ranges) do
        if (r[1] <= range[1] and range[1] <= r[2]) and (r[1] <= range[2] and range[2] <= r[2]) then
            return true;
        end
    end
    return false;
end

--- @param ranges IndexRange[]
--- @param range IndexRange
---
--- @return boolean result
local insideRanges = function(ranges, range)
    for _, r in ipairs(ranges) do
        if (range[1] <= r[1] and r[1] <= range[2]) and (range[1] <= r[2] and r[2] <= range[2]) then
            return true;
        end
    end
    return false;
end

--- @param ranges IndexRange[]
--- @param range IndexRange
---
--- @return boolean result
local intersectsRange = function(ranges, range)
    for _, r in ipairs(ranges) do
        if (r[1] <= range[1] and range[1] <= r[2]) or (r[1] <= range[2] and range[2] <= r[2]) then
            return true;
        end
    end
    return false;
end

--- @param str string
--- @param pattern string
--- @param index? number
---
--- @return [number, number][] ranges The discovered ranges of the pattern in the string.
local findAllRanges = function(str, pattern, index)
    local spots = {};
    local lastIndex = index;
    local start, stop = string.find(str, pattern);
    while start ~= nil and stop ~= nil do
        table.insert(spots, { start, stop });
        lastIndex = stop + 1;
        start, stop = string.find(str, pattern, lastIndex);
    end
    return spots;
end

local findStrings = function(code, index)
    local spots = {};
    local doubleQuoteRanges = findAllRanges(code, STRING_PATTERN_DOUBLE_QUOTE_STRINGS, index);
    for _, v in ipairs(doubleQuoteRanges) do
        table.insert(spots, v);
    end
    local singleQuoteRanges = findAllRanges(code, STRING_PATTERN_SINGLE_QUOTE_STRINGS, index);
    for _, v in ipairs(singleQuoteRanges) do
        table.insert(spots, v);
    end
    return spots;
end

local findCommentBlocks = function(code, index)
    return findAllRanges(code, STRING_PATTERN_BLOCK_COMMENT, index);
end

local findLineComments = function(code, index)
    local spots = {};
    local lastIndex = index;
    local start, stop = string.find(code, STRING_PATTERN_LINE_COMMENT);
    while start ~= nil and stop ~= nil do
        -- Modify this line in the utility method because we want to match without /n inside the index.
        table.insert(spots, { start, stop - 1 });
        lastIndex = stop + 1;
        start, stop = string.find(code, STRING_PATTERN_LINE_COMMENT, lastIndex);
    end
    return spots;
end

-- MARK: API

local codestring = {};

---
--- @param code any
---
--- @return {blockComments: IndexRange[], lineComments: IndexRange[], strings: IndexRange[]}
function codestring.findRanges(code)
    -- NOTE: Match the initial ranges. Some of these will be invalid. The following code identifies and removes those
    -- mistakes.
    local blocksRanges = findCommentBlocks(code);
    local linesRanges = findLineComments(code);
    local stringsRanges = findStrings(code);

    -- Remove strings found inside of comments.
    if #stringsRanges then
        local newStringsRanges = {};
        for i, v in ipairs(stringsRanges) do
            if not insideRange(blocksRanges, v) and not insideRange(linesRanges, v) then
                table.insert(newStringsRanges, v);
            end
        end
        stringsRanges = newStringsRanges;
    end

    if #linesRanges ~= 0 then
        local newLinesRanges = {};
        for i, v in ipairs(linesRanges) do
            if not intersectsRange(blocksRanges, v) and not intersectsRange(stringsRanges, v) then
                table.insert(newLinesRanges, v);
            end
        end
        linesRanges = newLinesRanges;
    end

    if #stringsRanges then
        local newStringsRanges = {};
        for i, v in ipairs(stringsRanges) do
            if not insideRange(blocksRanges, v) and not insideRange(linesRanges, v) then
                table.insert(newStringsRanges, v);
            end
        end
        stringsRanges = newStringsRanges;
    end

    return { blockComments = blocksRanges, lineComments = linesRanges, strings = stringsRanges };
end

function codestring.split(str, sep)
    if str == '' then return str end
    local t = {};
    for str in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(t, str);
    end
    return t;
end

function codestring.join(lines, sep)
    local s = '';
    for i, v in ipairs(lines) do
        if i == 1 then
            s = v;
        else
            s = s .. sep .. v;
        end
    end
    return s;
end

function codestring.trim(str)
    local from = str:match "^%s*()"
    return from > #str and "" or str:match(".*%S", from)
end

--- Injects variables into a body of code that notes variables as `{VARIABLE_ID}`. The table must have this defined,
--- otherwise their text-body is not affected and the injection site(s) remain.
---
--- @param code string The code to modify.
--- @param variables table<string, any> The variables to inject.
---
--- @return string result The modified text with injected variables.
function codestring.injectVariables(code, variables)
    if code == '' then return code end
    for variable_id, variable_value in pairs(variables) do
        code = string.gsub(code, '{' .. variable_id .. '}', tostring(variable_value));
    end
    return code;
end

function codestring.deBlockCommentCode(code)
    local deCode = code;
    local lastIndex = 1;
    local start, stop = string.find(deCode, STRING_PATTERN_BLOCK_COMMENT);
    while start ~= nil and stop ~= nil do
        local block1 = '';
        local block2 = '';
        if start > 1 then
            block1 = string.sub(deCode, 1, start);
        end
        if stop + 1 < #code then
            block2 = string.sub(deCode, stop + 1, #deCode);
        end
        deCode = block1 .. block2;
        lastIndex = stop + 1;
        start, stop = string.find(deCode, STRING_PATTERN_BLOCK_COMMENT, lastIndex);
    end
    return deCode;
end

function codestring.deLineCommentCode(code)
    local deCode = '';
    for i, v in ipairs(codestring.split(code, '\n')) do
        if v ~= nil then
            local indexOfLineComment = string.find(v, '%-%-');
            if indexOfLineComment ~= nil then
                if indexOfLineComment ~= 1 then
                    if deCode == '' then
                        deCode = codestring.trim(string.sub(v, 1, indexOfLineComment - 1));
                    else
                        deCode = deCode .. ' ' .. codestring.trim(string.sub(v, 1, indexOfLineComment - 1));
                    end
                end
            else
                if deCode == '' then
                    deCode = v;
                else
                    deCode = deCode .. '\n' .. v;
                end
            end
        end
    end
    return deCode;
end

function codestring.deLineCode(code)
    local deCode = '';
    for i, v in ipairs(codestring.split(code, '\n')) do
        if i == 1 then
            deCode = codestring.trim(v);
        else
            deCode = deCode .. ' ' .. codestring.trim(v);
        end
    end
    return deCode;
end

function codestring.getVariableNames(code)
    local vars = {};
    local varRanges = findAllRanges(code, 'local [^%s^.]+', 1);
    for i,v in ipairs(varRanges) do
        local varName = string.sub(code, v[1] + 6, v[2]);
        if varName ~= 'function' then
            table.insert(vars, codestring.trim(varName));
        end
    end
    return vars;
end

function codestring.squashCode(code)
    local deCode = code;

    local ranges = codestring.findRanges(deCode);
    if #ranges.blockComments ~= 0 then
        for _, range in ipairs(ranges.blockComments) do
            local chunk = string.sub(code, range[1], range[2]);
            deCode = string.gsub(deCode, strPlainText(chunk), '', 1);
        end
    end
    if #ranges.lineComments ~= 0 then
        for _, range in ipairs(ranges.lineComments) do
            local chunk = string.sub(code, range[1], range[2]);
            deCode = string.gsub(deCode, strPlainText(chunk), '', 1);
        end
    end

    if #ranges.strings ~= 0 then
        for i, range in ipairs(ranges.strings) do
            local chunk = string.sub(code, range[1], range[2]);
            deCode = string.gsub(deCode, strPlainText(chunk), '${' .. tostring(i) .. '}', 1);
        end
    end

    -- deCode = string.gsub(deCode, '[%s]+', ' ');
    -- deCode = string.gsub(deCode, '\n', ' ');

    deCode = string.gsub(deCode, '[\n]+', '\n');

    local varNames = codestring.getVariableNames(deCode);
    for i, varName in ipairs(varNames) do
        local scrambled = randomstring(4, 8);
        print(varName .. ' -> ' .. scrambled);

        local p = '[^%w]' .. varName .. '[^%w]';
        local r = scrambled;

        deCode = string.gsub(deCode, p, r);
    end

    if #ranges.strings ~= 0 then
        for i, range in ipairs(ranges.strings) do
            local chunk = string.sub(code, range[1], range[2]);
            deCode = string.gsub(deCode, '%$%{' .. tostring(i) .. '%}', strPlainText(chunk));
        end
    end

    return codestring.trim(deCode);
end

-- DEBUG CODE
--
if not instanceof then
    -- see if the file exists
    local function file_exists(file)
        local f = io.open(file, "rb")
        if f then f:close() end
        return f ~= nil
    end

    -- get all lines from a file, returns an empty
    -- list/table if the file does not exist
    local function lines_from(file)
        if not file_exists(file) then return {} end
        local lines = {}
        for line in io.lines(file) do
            lines[#lines + 1] = line
        end
        return lines
    end

    -- tests the functions above
    local file = 'C:/Users/jabdo/Zomboid/Lua/ModLoader/mods/EtherHammerX/modules/' .. 'unlockvizion_client.lua';
    local lines = lines_from(file);
    local code = table.concat(lines, '\n');

    local deCode = codestring.squashCode(code);
    print('result: ');
    print(deCode);
    print(loadstring(deCode)());
end

return codestring;
