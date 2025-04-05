local CHAR_SEQUENCE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-';

--- Scrambles a random set of characters between a minimum and maximum length.
---
--- @param minChars number The minimum (or exact) number of characters to generate.
--- @param maxChars? number (Optional) The maximum number of characters to generate.
--- @param rand? Random (Optional) The random object to sample.
---
--- @return string result The result-generated characters.
return function(minChars, maxChars, rand)
    if not rand then
        rand = newrandom();
    end
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
    --- The generated length of the scrambled result.
    ---
    --- @type number
    local lengthChars = minChars;
    if maxChars > minChars then
        local deltaChars = maxChars - minChars;
        lengthChars = minChars + math.floor(rand:random(1, deltaChars));
    end
    for _ = 1, lengthChars do
        --- @type number
        local index = 0;
        index = math.floor(rand:random(sequenceLength));
        result = result .. string.sub(CHAR_SEQUENCE, index, index);
    end
    return result;
end
