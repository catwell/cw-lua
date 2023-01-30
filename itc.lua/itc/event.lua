local fmt = string.format

local function is_nontrivial_event(x)
    return type(x) == "table" and #x == 3 and type(x[1] == "number")
end

local function _repr(x)
    if type(x) == "number" then
        return fmt("%d", x)
    else
        assert(is_nontrivial_event(x))
        return fmt("(%d, %s, %s)", x[1], _repr(x[2]), _repr(x[3]))
    end
end

local function repr(self)
    return _repr(self.data)
end

local function _min(x)
    -- only over normalized events
    return type(x) == "number" and x or x[1]
end

local function _max(x)
    if type(x) == "number" then return x end
    return x[1] + math.max(_max(x[2]), _max(x[3]))
end

local function _sink(x, m)
    if type(x) == "table" then
        return { _sink(x[1], m), x[2], x[3] }
    end
    assert(x >= m)
    return x - m
end

local function _norm(x)
    if type(x) == "number" then return x end
    assert(is_nontrivial_event(x))
    local n, x1, x2 = x[1], _norm(x[2]), _norm(x[3])
    if x1 == x2 then
        assert(type(x1) == "number")
        return n + x1
    end
    local m = math.min(_min(x1), _min(x2))
    return {n + m, _sink(x1, m), _sink(x2, m)}
end

local function normalize(self)
    self.data = _norm(self.data)
end

local function _lift(x, m)
    if type(x) == "table" then
        return { _lift(x[1], m), x[2], x[3] }
    end
    return x + m
end

local function _dom(x, y)
    -- In the paper this is called leq(y, x).
    -- x and y must be normalized.
    if type(x) == "number" then
        if type(y) == "number" then
            return x >= y
        else
            -- Not exactly what the paper says, but equivalent and faster.
            return x >= y[1] and _dom(x - y[1], y[2]) and _dom(x - y[1], y[3])
        end
    else
        if type(y) == "number" then
            return x[1] >= y
        else
            return x[1] >= y[1] and
                _dom(_lift(x[2], x[1]), _lift(y[2], y[1])) and
                _dom(_lift(x[3], x[1]), _lift(y[3], y[1]))
        end
    end
end

local function _copy(x)
    if type(x) == "number" then return x end
    return { x[1], _copy(x[2]), _copy(x[3]) }
end

local function _join(x, y)
    if type(x) == "number" then
        if type(y) == "number" then
            return math.max(x, y)
        else
            return _join({x, 0, 0}, y)
        end
    elseif type(y) == "number" then
        return _join(x, {y, 0, 0})
    end
    assert(type(x) == "table" and type(y) == "table")
    if x[1] > y[1] then return _join(y, x) end
    return _norm {
        x[1],
        _join(x[2], _lift(y[2], y[1] - x[1])),
        _join(x[3], _lift(y[3], y[1] - x[1])),
    }
end

local function _fill(i, x)
    -- returns: tree, did_something
    if i == false or type(x) == "number" then
        return x, false
    elseif i == true then
        return _max(x), true
    end
    assert(type(i) == "table" and type(x) == "table")
    if i[1] == true then
        local er, ds = _fill(i[2], x[3])
        local r = _norm {x[1], math.max(_max(x[2], _min(er))), er}
        return r, ds or type(r) == "number" or r[1] ~= x[1] or r[2] ~= x[2]
    elseif i[2] == true then
        local el, ds = _fill(i[1], x[2])
        local r = _norm {x[1], el, math.max(_max(x[3], _min(el)))}
        return r, ds or type(r) == "number" or r[1] ~= x[1] or r[3] ~= x[3]
    else
        local el, dsl = _fill(i[1], x[2])
        local er, dsr = _fill(i[2], x[3])
        return _norm {x[1], el, er}, dsl or dsr
    end
end

local function _grow(i, x, cs, cw)
    -- returns: tree, strong cost, weak cost
    if type(x) == "number" then
        if i == true then
            return x + 1, cs, cw
        else
            return _grow(i, {x, 0, 0}, cs + 1, cw)
        end
    elseif i == true then
        print("This case is not in the paper.")
        return {x[1] + 1, x[2], x[3]}, cs, cw
    end
    assert(type(i) == "table" and type(x) == "table")
    if i[1] == false then
        local er, csr, cwr = _grow(i[2], x[3], cs, cw)
        return {x[1], x[2], er}, csr, cwr + 1
    elseif i[2] == false then
        local el, csl, cwl = _grow(i[1], x[2], cs, cw)
        return {x[1], el, x[3]}, csl, cwl + 1
    else
        local el, csl, cwl = _grow(i[1], x[2], cs, cw)
        local er, csr, cwr = _grow(i[2], x[3], cs, cw)
        if csl < csr or (csl == csr and cwl < cwr) then
            return {x[1], el, x[3]}, csl, cwl + 1
        else
            return {x[1], x[2], er}, csr, cwr + 1
        end
    end
end

local function dominates(self, other)
    return _dom(self.data, other.data)
end

local new

local function copy(self)
    return new { data = _copy(self.data) }
end

local function join(self, other)
    self.data = _join(self.data, other.data)
end

local function event(self, _id)
    local data, changed = _fill(_id.data, self.data)
    if changed then
        self.data = data
    else
        self.data = _grow(_id.data, self.data, 0, 0)
    end
end

local methods = {
    repr = repr,
    normalize = normalize,
    dominates = dominates,
    copy = copy,
    join = join,
    event = event,
}

local mt = { __index = methods }

new = function(args)
    args = args or {}
    local data = args.data or 0
    local self = { data = data }
    return setmetatable(self, mt)
end

return {new = new}
