-- PN-Counter

local GCounter = require "g_counter"

--- METHODS

local decr = function(self,qty)
  self.n:incr(qty)
end

local incr = function(self,qty)
  self.p:incr(qty)
end

local merge = function(self,other)
  self.p:merge(other.p)
  self.n:merge(other.n)
end

local value = function(self)
  return self.p:value() - self.n:value()
end

local methods = {
  decr = decr, -- (qty) -> !
  incr = incr, -- (qty) -> !
  merge = merge, -- (other) -> !
  value = value, -- () -> number
}

--- CLASS

local new = function(node)
  local r = {
    node = node,
    p = GCounter.new(node),
    n = GCounter.new(node),
  }
  return setmetatable(r,{__index = methods})
end

return {
  new = new, -- (node) -> PN-Counter
}
