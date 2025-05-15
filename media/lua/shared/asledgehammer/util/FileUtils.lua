---[[
--- @author JabDoesThings, asledgehammer 2025
---]]

--- @param uri string
---
--- @return string | nil
local function readFile(uri)
    local reader = getFileReader(uri, false);

    -- A nil reader indicates a bad path or a missing file.
    if not reader then
        return nil;
    end

    ---------------------------------
    -- Read the contents of the file.
    local data = '';
    local line = reader:readLine();
    while line ~= nil do
        data = data .. line .. '\n';
        line = reader:readLine();
    end
    reader:close();
    ---------------------------------

    return data;
end

local function writeFile(uri, data, append)
    local writer = getFileWriter(uri, true, append or false);
    -- try/catch
    pcall(function()
        writer:write(data);
    end);
    -- finally
    writer:close();
end

return {
    readFile = readFile,
    writeFile = writeFile
};
