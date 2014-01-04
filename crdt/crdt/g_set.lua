-- G-Set

local LSet = require "lua_set"
local utils = require "utils"

--- METHODS

local has = function(self, x)
  return self.e:has(x)
end

local value = function(self)
  return self.e
end

local add = function(self, x)
  self.e:add(x)
end

local merge = function(self, other)
  self.e:s_add(other:value())
end

local methods = {
  has = utils.variadify(has, utils.fold_and), -- (x) -> bool
  value = value, -- () -> LSet
  add = utils.variadify(add), -- (x) -> !
  merge = merge, -- (other) -> !
}

--- CLASS

local new = function()
  local r = {e = LSet.new()}
  return setmetatable(r, {__index = methods})
end

return {
  new = new, -- () -> G-Set
}
