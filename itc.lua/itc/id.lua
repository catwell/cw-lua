local fmt = string.format

local function _repr(x)
    if x == false then
        return "0"
    elseif x == true then
        return "1"
    else
        assert(type(x) == "table")
        return fmt("(%s, %s)", _repr(x[1]), _repr(x[2]))
    end
end

local function repr(self)
    return _repr(self.data)
end

local function _norm(x)
    if type(x) == "boolean" then return x end
    assert(type(x) == "table")
    local x1, x2 = _norm(x[1]), _norm(x[2])
    if x1 == false and x2 == false then
        return false
    elseif x1 == true and x2 == true then
        return true
    else
        return {x1, x2}
    end
end

local function _split(x)
    if x == false then
        return false, false
    elseif x == true then
        return {true, false}, {false, true}
    end
    assert(type(x) == "table")
    if x[1] == false then
        local i1, i2 = _split(x[2])
        return {false, i1}, {false, i2}
    elseif x[2] == false then
        local i1, i2 = _split(x[1])
        return {i1, false}, {i2, false}
    else
        return {x[1], false}, {false, x[2]}
    end
end

local function _sum(x, y)
    if x == false then
        return y
    elseif y == false then
        return x
    end
    assert(type(x) == "table" and type(y) == "table")
    return _norm {_sum(x[1], y[1]), _sum(x[2], y[2])}
end

local function normalize(self)
    self.data = _norm(self.data)
end

local function sum(self, other)
    self.data = _sum(self.data, other.data)
end

local new

local function split(self)
    local i1, i2 = _split(self.data)
    self.data = i1
    return new { data = i2 }
end

local methods = {
    repr = repr,
    normalize = normalize,
    split = split,
    sum = sum,
}

local mt = { __index = methods }

new = function(args)
    args = args or {}
    local data = args.data or false
    local self = { data = data }
    return setmetatable(self, mt)
end

return {new = new}
