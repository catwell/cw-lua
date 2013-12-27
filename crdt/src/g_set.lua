-- G-Set

local LSet = require "lua_set"

--- METHODS

local add = function(self,x)
  self.e:add(x)
end

local has = function(self,x)
  return self.e:has(x)
end

local merge = function(self,other)
  self.e:s_add(other:value())
end

local value = function(self)
  return self.e
end

local methods = {
  add = add, -- (x) -> !
  has = has, -- (x) -> bool
  merge = merge, -- (other) -> !
  value = value, -- () -> LSet
}

--- CLASS

local new = function()
  local r = {e = LSet.new()}
  return setmetatable(r,{__index = methods})
end

return {
  new = new, -- () -> G-Set
}
