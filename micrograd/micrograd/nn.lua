local Value = (require "micrograd.engine").Value


local module_methods = {}
local module_mt = { __index = module_methods }

function module_methods.zero_grad(self)
    for _, p in ipairs(self:parameters()) do
        p.grad = 0
    end
end

function module_methods.parameters(self)
    return {}
end


local neuron_methods = setmetatable({}, module_mt)
local neuron_mt = { __index = neuron_methods }

local function new_neuron(nin, nonlin)
    if nonlin == nil then nonlin = true end
    local w = {}
    for i = 1, nin do w[i] = Value(math.random(-1, 1)) end
    local self = {w = w, b = Value(0), nonlin = nonlin }
    return setmetatable(self, neuron_mt)
end

function neuron_mt.__call(self, x)
    assert(#x == #self.w)
    local act = self.b
    for i = 1, #x do
        act = act + self.w[i] * x[i]
    end
    if self.nonlin then
        return act:relu()
    else
        return act + 0  -- avoid returning self.b
    end
end

function neuron_methods.parameters(self)
    local r = {}
    for i = 1, #self.w do r[i] = self.w[i] end
    r[#r + 1] = self.b
    return r
end

function neuron_mt.__tostring(self)
    return string.format(
        "%sNeuron(%d)",
        self.nonlin and "ReLU" or "Linear",
        #self.w
    )
end


local layer_methods = setmetatable({}, module_mt)
local layer_mt = { __index = layer_methods }

local function new_layer(nin, nout, nonlin)
    if nonlin == nil then nonlin = true end
    local neurons = {}
    for i = 1, nout do neurons[i] = new_neuron(nin, nonlin) end
    return setmetatable({ neurons = neurons }, layer_mt)
end

function layer_mt.__call(self, x)
    local out = {}
    for i, n in ipairs(self.neurons) do out[i] = n(x) end
    return #out == 1 and out[0] or out
end

function layer_methods.parameters(self)
    local r = {}
    for _, n in ipairs(self.neurons) do
        for _, p in ipairs(n:parameters()) do
            r[#r + 1] = p
        end
    end
    return r
end

function layer_mt.__tostring(self)
    local r = {}
    for i, n in ipairs(self.neurons) do r[i] = tostring(n) end
    return string.format("Layer of [%s]", table.concat(r, ", "))
end


local mlp_methods = setmetatable({}, module_mt)
local mlp_mt = { __index = mlp_methods }

local function new_mlp(nin, nouts)
    local sz = {nin}
    for i, nout in ipairs(nouts) do sz[i + 1] = nout end
    local n, layers = #nouts, {}
    for i = 1, n do layers[i] = new_layer(sz[i], sz[i + 1], i ~= n) end
    return setmetatable({ layers = layers }, mlp_mt)
end

function mlp_mt.__call(self, x)
    for _, layer in ipairs(self.layers) do
        x = layer(x)
    end
    return x
end

function mlp_methods.parameters(self)
    local r = {}
    for _, layer in ipairs(self.layers) do
        for _, p in ipairs(layer:parameters()) do
            r[#r + 1] = p
        end
    end
    return r
end

function mlp_mt.__tostring(self)
    local r = {}
    for i, layer in ipairs(self.layers) do r[i] = tostring(layer) end
    return string.format("MLP of [%s]", table.concat(r, ", "))
end


return { Neuron = new_neuron, Layer = new_layer, MLP = new_mlp }
