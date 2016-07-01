local bin = require "itc.bin"
local itc_id = require "itc.id"
local itc_event = require "itc.event"

local function repr(self)
    assert(not self.dead)
    local t = {"[", self.id:repr(), ", ", self.ev:repr(), "]"}
    return table.concat(t)
end

local function normalize(self)
    self.id:normalize()
    self.ev:normalize()
end

local function dominates(self, other)
    assert((not self.dead) and (not other.dead))
    return self.ev:dominates(other.ev)
end

local new

local function fork(self)
    assert(not self.dead)
    return new { id = self.id:split(), ev = self.ev:copy() }
end

local function peek(self)
    assert(not self.dead)
    return new { id = itc_id.new(), ev = self.ev:copy() }
end

local function join(self, other)
    assert((not self.dead) and (not other.dead))
    self.id:sum(other.id)
    self.ev:join(other.ev)
    other.dead = true
end

local function is_anonymous(self)
    return(self.id.data == 0)
end

local function event(self)
    assert(not self.dead)
    assert(not self:is_anonymous()) -- cannot be called on anonymous stamps
    self.ev:event(self.id)
end

local function encode(self)
    assert(not self.dead)
    return bin.encode(self.id.data, self.ev.data)
end

local methods = {
    repr = repr,
    normalize = normalize,
    dominates = dominates,
    fork = fork,
    peek = peek,
    join = join,
    is_anonymous = is_anonymous,
    event = event,
    encode = encode,
}

local mt = { __index = methods }

new = function(args)
    args = args or {}
    local id = args.id or itc_id.new {data = true}
    local ev = args.ev or itc_event.new()
    local self = { id = id, ev = ev }
    return setmetatable(self, mt)
end

local decode = function(data)
    local i, e = bin.decode(data)
    return new {id = itc_id.new {data = i}, ev = itc_event.new {data = e}}
end

return {
    new = new,
    decode = decode,
}
