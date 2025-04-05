---[[
---
--- (Modified to be module-friendly with Project Zomboid by asledgehammer, JabDoesThings)
---
--- @author amussey (https://github.com/amussey/lua-json-validator/blob/master/validJson.lua)
---]]

local json_validator = {};

function json_validator.bool_check(contents)
    contents = json_validator.s_trim(contents);
    return contents == "true" or contents == "false";
end

function json_validator.null_check(contents)
    contents = json_validator.s_trim(contents);
    return contents == "null";
end

function json_validator.string_check(contents)
    contents = json_validator.s_trim(contents);
    if string.sub(contents, 1, 1) ~= "\""
        or string.sub(contents, string.len(contents), string.len(contents)) ~= '\"' then
        return false;
    end
    local returnString = string.sub(contents, 2, string.len(contents) - 1);
    return (string.find(returnString, '"') == nil);
end

function json_validator.number_check(contents)
    contents = json_validator.s_trim(contents);
    if string.sub(contents, 1, 1) == "\""
        or string.sub(contents, string.len(contents), string.len(contents)) == "\"" then
        return false;
    end
    local contentCheck1 = tostring(string.match("1.42", "[\\-\\+]?[0-9]*[\\.[0-9]+]?") ~= nil);
    local contentCheck2 = (string.match(contents, "[\\-\\+]?[0-9]*[\\.[0-9]+]?") == contents);
    return (contentCheck1 and contentCheck2);
end

function json_validator.s_split(str, inSplitPattern, outResults)
    if not outResults then outResults = {} end
    local theStart = 1;
    local theSplitStart, theSplitEnd = string.find(str, inSplitPattern, theStart);
    while theSplitStart do
        table.insert(outResults, string.sub(str, theStart, theSplitStart - 1));
        theStart = theSplitEnd + 1;
        theSplitStart, theSplitEnd = string.find(str, inSplitPattern, theStart);
    end
    table.insert(outResults, string.sub(str, theStart));
    return outResults;
end

function json_validator.s_trim(str)
    return string.match(str, "^()%s*$") and "" or string.match(str, "^%s*(.*%S)");
end

function json_validator.t_length(T)
    local count = 0;
    for _ in pairs(T) do count = count + 1 end
    return count;
end

function json_validator.is_valid(contents)
    contents = json_validator.s_trim(contents);
    if contents == "{}" or contents == "[]" or contents == "\"\"" then
        return true;
    end
    local js = 1;
    local je = 2;
    local searchChar = "";
    local failChar = "";
    if string.sub(contents, js, js) == "{" then
        searchChar = "}";
        failChar = "]";
    elseif string.sub(contents, js, js) == "[" then
        searchChar = "]";
        failChar = "}";
    else
        return false;
    end

    while string.sub(contents, je, je) ~= searchChar and string.sub(contents, je, je) ~= "" do
        if string.sub(contents, je, je) == failChar then
            return false;
        elseif string.sub(contents, je, je) == "{" then
            searchChar = "}";
            failChar = "]";
            js = je;
        elseif string.sub(contents, je, je) == "[" then
            searchChar = "]";
            failChar = "}";
            js = je;
        end
        je = je + 1;
    end

    if string.sub(contents, je, je) == searchChar then
        -- the current array or list is from js to je
        -- if it's a list, validate it and remove it.
        local array_check_bool = json_validator.array_check(string.sub(contents, js, je));
        local list_check_bool = json_validator.list_check(string.sub(contents, js, je));
        local checkBool = array_check_bool or list_check_bool;
        if checkBool then
            -- contents without the current value.
            contents = string.sub(contents, 1, js - 1) .. "\"\"" .. string.sub(contents, je + 1, string.len(contents));
            return json_validator.is_valid(contents);
        else
            return false;
        end
    end
end

function json_validator.array_check(contents)
    contents = json_validator.s_trim(contents);
    if string.sub(contents, 1, 1) == "{"
        and string.sub(contents, string.len(contents), string.len(contents)) == "}" then
        contents = string.sub(contents, 2, string.len(contents) - 1);
        contents = json_validator.s_trim(contents);
    else
        return false;
    end
    if contents == "" then return true end
    contents = json_validator.s_split(contents, ",");
    local finalValue = true;
    for _, value in pairs(contents) do
        finalValue = finalValue and json_validator.array_item_check(value);
    end
    return finalValue;
end

function json_validator.valid_json(contents)
    contents = json_validator.s_trim(contents);
    if string.sub(contents, 1, 1) ~= "{" and string.sub(contents, 1, 1) ~= "[" then
        return false;
    end
    return json_validator.is_valid(contents);
end

function json_validator.array_item_check(contents)
    contents = json_validator.s_split(contents, ':');
    if json_validator.t_length(contents) ~= 2 then
        -- There is not a key-value pair.
        return false;
    end
    contents[1] = json_validator.s_trim(contents[1]);
    contents[2] = json_validator.s_trim(contents[2]);
    local contentValue1 = json_validator.string_check(contents[1]);
    local value = contents[2];
    local listcheckbool = false;
    local arraycheckbool = false;
    if string.sub(value, 1, 1) == "{" and string.sub(value, string.len(value), string.len(value)) == "}" then
        arraycheckbool = json_validator.array_check(string.sub(value, 2, string.len(value) - 1));
    elseif string.sub(value, 1, 1) == "[" and string.sub(value, string.len(value), string.len(value)) == "]" then
        listcheckbool = json_validator.list_check(string.sub(value, 2, string.len(value) - 1));
    end
    local contentValue2 = (
        json_validator.string_check(value)
        or json_validator.number_check(value)
        or json_validator.bool_check(value)
        or json_validator.null_check(value)
        or listcheckbool or arraycheckbool
    );
    return contentValue1 and contentValue2;
end

function json_validator.list_check(contents)
    contents = json_validator.s_trim(contents);
    if string.sub(contents, 1, 1) == "["
        and string.sub(contents, string.len(contents), string.len(contents)) == "]" then
        contents = string.sub(contents, 2, string.len(contents) - 1);
        contents = json_validator.s_trim(contents);
    else
        return false;
    end
    if contents == "" then return true end
    contents = json_validator.s_split(contents, ',');

    local finalValue = true;
    for _, value in pairs(contents) do
        local listcheckbool = false;
        local arraycheckbool = false;
        if string.sub(value, 1, 1) == "{" and string.sub(value, string.len(value), string.len(value)) == "}" then
            arraycheckbool = json_validator.array_check(string.sub(value, 2, string.len(value) - 1));
        elseif string.sub(value, 1, 1) == "[" and string.sub(value, string.len(value), string.len(value)) == "]" then
            listcheckbool = json_validator.list_check(string.sub(value, 2, string.len(value) - 1));
        end
        finalValue = finalValue and
            (
                json_validator.string_check(value)
                or json_validator.number_check(value)
                or json_validator.bool_check(value)
                or json_validator.null_check(value)
                or listcheckbool
                or arraycheckbool
            );
    end
    return finalValue;
end

return json_validator.is_valid;
