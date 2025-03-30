local CHAR_SEQUENCE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-';

if not instanceof then
    math.randomseed(os.time());
end

--- Scrambles a random set of characters between a minimum and maximum length.
---
--- @param minChars number The minimum (or exact) number of characters to generate.
--- @param maxChars? number (Optional) The maximum number of characters to generate.
---
--- @return string result The result-generated characters.
return function(minChars, maxChars)
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
