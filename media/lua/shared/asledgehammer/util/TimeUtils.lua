---[[
--- TimeUtils gives mods cleaner implementations of repeated and delayed time-tasks.
---
--- @author JabDoesThings, asledgehammer 2025
---]]

local readonly = require 'asledgehammer/util/readonly';

local TimeUtils = {};

--- Delays a task by x ticks.
---
--- @param ticks number The amount of ticks delayed before invoking the callback. <br>NOTE: If ticks is zero then the callback is invoked immediately.
--- @param callback fun(): void The callback to invoke after the delay.
---
--- @return void
function TimeUtils.delayTicks(callback, ticks)
    -- (Sanity checks)
    assert(ticks > -1, 'Ticks cannot be negative. (Given: ' .. tostring(ticks) .. ')');
    assert(callback ~= nil, 'The callback is nil!');
    assert(type(callback) == 'function', 'The callback is not a function. (Given type: ' .. type(callback) .. ')');

    -- Run immediatley.
    if ticks == 0 then
        callback();
        return;
    end

    -- Run delayed.
    local t = 0;
    --- @type fun(): void | nil
    local onTick = nil;
    onTick = function()
        if t < ticks then
            t = t + 1;
            return;
        end
        Events.OnFETick.Remove(onTick);
        Events.OnTickEvenPaused.Remove(onTick);
        callback();
    end

    Events.OnFETick.Add(onTick);
    Events.OnTickEvenPaused.Add(onTick);
end

--- Executes a task every x ticks. Return a non-false inferenced value to stop the task from running.
---
--- NOTE: If the task errors, it will not repeat.
--- NOTE: If the ticks is 0, it'll run every tick.
---
--- @param callback fun(): boolean | nil
--- @param ticks number The ticks between execution.
function TimeUtils.everyTicks(callback, ticks)
    -- (Sanity checks)
    assert(ticks > -1, 'Ticks cannot be negative. (Given: ' .. tostring(ticks) .. ')');
    assert(callback ~= nil, 'The callback is nil!');
    assert(type(callback) == 'function', 'The callback is not a function. (Given type: ' .. type(callback) .. ')');

    -- Run immediatley.
    if ticks == 0 then
        callback();
        return;
    end

    -- Run delayed.
    local t = 0;
    --- @type fun(): void | nil
    local onTick = nil;
    onTick = function()
        if t < ticks then
            t = t + 1;
            return;
        end

        local result = false;
        local callbackResult = pcall(function()
            if callback() then
                result = true
            end
        end);

        if not callbackResult or result then
            Events.OnFETick.Remove(onTick);
            Events.OnTickEvenPaused.Remove(onTick);
        end

        t = 0;
    end

    Events.OnFETick.Add(onTick);
    Events.OnTickEvenPaused.Add(onTick);
end

--- Delays a task by x ticks.
---
--- @param seconds number The amount of seconds delayed before invoking the callback. <br>NOTE: If seconds is zero then the callback is invoked immediately.
--- @param callback fun(): void The callback to invoke after the delay.
---
--- @return void
function TimeUtils.delaySeconds(callback, seconds)
    -- (Sanity checks)
    assert(seconds > -1, 'Seconds cannot be negative. (Given: ' .. tostring(seconds) .. ')');
    assert(callback ~= nil, 'The callback is nil!');
    assert(type(callback) == 'function', 'The callback is not a function. (Given type: ' .. type(callback) .. ')');

    -- Run immediatley.
    if seconds == 0 then
        callback();
        return;
    end

    -- Run delayed.
    local timeLast = getTimeInMillis();
    --- @type fun(): void | nil
    local onTick = nil;
    onTick = function()
        if getTimeInMillis() - timeLast >= seconds then
            Events.OnFETick.Remove(onTick);
            Events.OnTickEvenPaused.Remove(onTick);
            callback();
        end
    end

    Events.OnFETick.Add(onTick);
    Events.OnTickEvenPaused.Add(onTick);
end

--- Executes a task every x seconds. Return a non-false inferenced value to stop the task from running.
---
--- NOTE: If the task errors, it will not repeat.
--- NOTE: If the seconds is 0, it'll run every tick.
---
--- @param callback fun(): boolean | nil
--- @param seconds number The seconds between execution.
function TimeUtils.everySeconds(callback, seconds)
    -- (Sanity checks)
    assert(seconds > -1, 'Seconds cannot be negative. (Given: ' .. tostring(seconds) .. ')');
    assert(callback ~= nil, 'The callback is nil!');
    assert(type(callback) == 'function', 'The callback is not a function. (Given type: ' .. type(callback) .. ')');

    --- @type fun(): void | nil
    local onTick = nil;

    -- Run immediatley.
    if seconds == 0 then
        onTick = function()
            local result = false;
            local callbackResult = pcall(function()
                if callback() then
                    result = true
                end
            end);
            if not callbackResult or result then
                Events.OnFETick.Remove(onTick);
                Events.OnTickEvenPaused.Remove(onTick);
                return;
            end
        end
    else
        -- Run delayed.
        local timeLast = getTimeInMillis() / 1000;
        onTick = function()
            local timeNow = getTimeInMillis() / 1000;
            if timeNow - timeLast >= seconds then
                local result = false;
                local callbackResult = pcall(function()
                    if callback() then
                        result = true
                    end
                end);

                if not callbackResult or result then
                    Events.OnFETick.Remove(onTick);
                    Events.OnTickEvenPaused.Remove(onTick);
                    return;
                end
                timeLast = getTimeInMillis();
            end
        end
    end

    Events.OnFETick.Add(onTick);
    Events.OnTickEvenPaused.Add(onTick);
end

return readonly(TimeUtils);
