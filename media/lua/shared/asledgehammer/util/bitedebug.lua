---[[
--- @author asledgehammer, JabDoesThings, 2024
---]]

local bite = require 'asledgehammer/util/bite';

if BitwiseOps ~= nil then -- CraftHammer API
    local bit = {
        bnot = BitwiseOps.bnot32,
        band = BitwiseOps.band32,
        bor = BitwiseOps.bor32,
        bxor = BitwiseOps.bxor32,
        lshift = BitwiseOps.lshift32,
        rshift = BitwiseOps.rshift32,
        arshift = BitwiseOps.arshift32,
    };

    local x = {};

    function x.bnot(value)
        local a = bit.bnot(value);
        local b = bite.bnot(value);
        if bit and a ~= b then
            print('Bitwise mismatch: ~' .. value .. ' Java: ' .. a .. ' Lua: ' .. b);
        end
        return b;
    end

    function x.band(value, mask)
        local a = bit.band(value, mask);
        local b = bite.band(value, mask);
        if bit and a ~= b then
            print('Bitwise mismatch: ' .. value .. ' & ' .. mask .. ' Java: ' .. a .. ' Lua: ' .. b);
        end
        return b;
    end

    function x.bor(value, mask)
        local a = bit.bor(value, mask);
        local b = bite.bor(value, mask);
        if bit and a ~= b then
            print('Bitwise mismatch: ' .. value .. ' | ' .. mask .. ' Java: ' .. a .. ' Lua: ' .. b);
        end
        return b;
    end

    function x.bxor(value, mask)
        local a = bit.bxor(value, mask);
        local b = bite.bxor(value, mask);
        if bit and a ~= b then
            print('Bitwise mismatch: ' .. value .. ' ^ ' .. mask .. ' Java: ' .. a .. ' Lua: ' .. b);
        end
        return b;
    end

    function x.lshift(value, offset)
        local a = bit.lshift(value, offset);
        local b = bite.lshift(value, offset);
        if bit and a ~= b then
            print('Bitwise mismatch: ' .. value .. ' << ' .. offset .. ' Java: ' .. a .. ' Lua: ' .. b);
        end
        return b;
    end

    function x.rshift(value, offset)
        local a = bit.rshift(value, offset);
        local b = bite.rshift(value, offset);
        if bit and a ~= b then
            print('Bitwise mismatch: ' .. value .. ' >>> ' .. offset .. ' Java: ' .. a .. ' Lua: ' .. b);
        end
        return b;
    end

    function x.arshift(value, offset)
        local a = bit.arshift(value, offset);
        local b = bite.arshift(value, offset);
        if bit and a ~= b then
            print('Bitwise mismatch: ' .. value .. ' >> ' .. offset .. ' Java: ' .. a .. ' Lua: ' .. b);
        end
        return b;
    end

    return x;
else
    return bite;
end
