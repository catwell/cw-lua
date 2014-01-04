-- 2P-Set

local GSet = require "g_set"
local utils = require "utils"

--- METHODS

local has = function(self, x)
  return self.a:has(x) and not self.r:has(x)
end

local value = function(self)
  local r = self.a:value():copy()
  r:s_del(self.r:value())
  return r
end

local add = function(self, x)
  if self.r:has(x) then error("invalid") end
  self.a:add(x)
end

local del = function(self, x)
  if self.a:has(x) then
    self.r:add(x)
  else error("invalid") end
end

local merge = function(self, other)
  self.a:merge(other.a)
  self.r:merge(other.r)
end

local methods = {
  has = utils.variadify(has, utils.fold_and), -- (x) -> bool
  value = value, -- () -> LSet
  add = utils.variadify(add), -- (x) -> !
  del = utils.variadify(del), -- (x) -> !
  merge = merge, -- (other) -> !
}

--- CLASS

local new = function()
  local r = {
    a = GSet.new(),
    r = GSet.new(),
  }
  return setmetatable(r, {__index = methods})
end

return {
  new = new, -- () -> 2P-Set
}
