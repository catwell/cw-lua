-- Plain Lua Set

--- METHODS

local methods -- filled at bottom

local add = function(self, x)
  self[x] = true
end

local as_list = function(self)
  local r = {}
  for k,_ in pairs(self) do r[#r+1] = k end
  return r
end

local card = function(self)
  local r = 0
  for k,_ in pairs(self) do r = r+1 end
  return r
end

local copy = function(self)
  local r = {}
  for k,_ in  pairs(self) do r[k] = true end
  return setmetatable(r, {__index = methods})
end

local del = function(self, x)
  self[x] = nil
end

local has = function(self, x)
  return not not self[x]
end

local s_add = function(self, other)
  for k,_ in pairs(other) do self[k] = true end
end

local s_del = function(self, other)
  for k,_ in pairs(other) do self[k] = nil end
end

local s_inter = function(self, other)
  for k,_ in pairs(self) do
    if not other[k] then self[k] = nil end
  end
end

methods = {
  add = add, -- (x) !
  as_list = as_list, -- () -> set as list
  card = card, -- () -> cardinal
  copy = copy, -- () -> copy
  del = del, -- (x) !
  has = has, -- (x) -> bool
  s_add = s_add, -- (set) -> ! union
  s_del = s_del, -- (set) -> ! difference
  s_inter = s_inter, -- (set) -> ! intersection
}

--- CLASS

local new = function()
  local r = {}
  return setmetatable(r, {__index = methods})
end

return {
  new = new,
}
