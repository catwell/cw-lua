-- g_boolean

-- Boolean value based on an increasing integer.

local utils = require "utils"

--- METHODS

local flip = function(self)
  self.v = self.v + 1
end

local merge = function(self, other)
  if other.v > self.v then self.v = other.v end
end

local value = function(self)
  return self.v % 2 == 1
end

local set = function(self, v)
    if self:value() ~= v then self:flip() end
end

local methods = {
  flip = flip, -- () -> !
  set = set, -- (bool) -> !
  merge = merge, -- (other) -> !
  value = value, -- () -> bool
}

--- CLASS

local new = function()
  local r = {v = 0}
  return setmetatable(r, {__index = methods})
end

return {
  new = new, -- (node) -> G-Boolean
}
