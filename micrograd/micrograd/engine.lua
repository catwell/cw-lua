local value_methods = {}
local value_mt = { __index = value_methods }

local function new_value(data, _children, _op)
    local self = {
        data = data,
        grad = 0,
        _backward = function() end,
        _prev = _children or {},
        _op = _op or "",
    }
    return setmetatable(self, value_mt)
end

local function is_value(v)
    return getmetatable(v) == value_mt
end

function value_mt.__add(self, other)
    if not is_value(self) then
        assert(is_value(other))
        return other + self
    end
    if not is_value(other) then
        other = new_value(other)
    end

    local out = new_value(
        self.data + other.data,
        {[self] = true, [other] = true},
        "+"
    )
    local function backward()
        self.grad = self.grad + out.grad
        other.grad = other.grad + out.grad
    end
    out._backward = backward
    return out
end

function value_mt.__mul(self, other)
    if not is_value(self) then
        assert(is_value(other))
        return other * self
    end
    if not is_value(other) then
        other = new_value(other)
    end

    local out = new_value(
        self.data * other.data,
        {[self] = true, [other] = true},
        "*"
    )
    local function backward()
        self.grad = self.grad + other.data * out.grad
        other.grad = other.grad + self.data * out.grad
    end
    out._backward = backward
    return out
end

function value_mt.__pow(self, other)
    if not is_value(self) then
        assert(is_value(other))
        return other ^ self
    end
    if type(other) ~= "number" then
        error("only supporting int/float powers for now")
    end

    local out = new_value(
        self.data ^ other,
        {[self] = true},
        string.format("^%f", other)
    )
    local function backward()
        self.grad = self.grad + (other * self.data ^ (other - 1)) * out.grad
    end
    out._backward = backward
    return out
end

function value_methods.relu(self)
    local out = new_value(
        self.data < 0 and 0 or self.data,
        {[self] = true},
        "ReLU"
    )
    local function backward()
        self.grad = self.grad + (out.data > 0 and 1 or 0) * out.grad
    end
    out._backward = backward
    return out
end

function value_methods.backward(self)
    local topo = {}
    local visited = {}
    local function build_topo(v)
        if not visited[v] then
            visited[v] = true
            for child in pairs(v._prev) do
                build_topo(child)
            end
            topo[#topo + 1] = v
        end
    end
    build_topo(self)
    self.grad = 1
    for i = #topo, 1, -1 do
        topo[i]._backward()
    end
end

function value_mt.__unm(self)
    return self * -1
end

function value_mt.__sub(self, other)
    return self + (-other)
end

function value_mt.__div(self, other)
    return self * other ^ -1
end

function value_mt.__tostring(self)
    return string.format("Value(data=%f, grad=%f)", self.data, self.grad)
end


return { Value = new_value }
