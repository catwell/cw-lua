-- G-Counter

local utils = require "utils"

--- METHODS

local incr = function(self, qty)
  self.e[self.node] = self.e[self.node] + qty
end

local merge = function(self, other)
  for k,v in pairs(other.e) do
    if self.e[k] < v then self.e[k] = v end
  end
end

local value = function(self)
  local r = 0
  for _,v in pairs(self.e) do r = r+v end
  return r
end

local methods = {
  incr = incr, -- (qty) -> !
  merge = merge, -- (other) -> !
  value = value, -- () -> number
}

--- CLASS

local new = function(node)
  local r = {node = node, e = utils.defmap(0)}
  return setmetatable(r, {__index = methods})
end

return {
  new = new, -- (node) -> G-Counter
}
