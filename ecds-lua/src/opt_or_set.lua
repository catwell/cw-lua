-- Optimized OR-Set
-- See paper: An Optimized Conflict-free Replicated Set
-- Bienius, Zawirski, Preguiça, Shapiro, Baquero, Balegas & Duarte
-- http://arxiv.org/pdf/1210.3368.pdf

local LSet = require "lua_set"
local utils = require "utils"

local next_uid = function(self)
  local x = self.ids[self.node] + 1
  self.ids[self.node] = x
  return x
end

--- METHODS

local add = function(self, x)
  self.payload[x][self.node] = next_uid(self)
end

local del = function(self, x)
  self.payload[x][self.node] = nil
end

local merge = function(self,other)
  -- merge adds
  for k,v in pairs(other.payload) do
    for node, uid in pairs(v) do
      if uid > self.ids[node] then
        self.payload[k][node] = uid
      end
    end
  end
  -- merge removes
  for k,v in pairs(self.payload) do
    for node, uid in pairs(v) do
      if other.ids[node] >= uid then
        v[node] = other.payload[k][node]
      end
    end
  end
  -- merge replica ids
  for k,v in pairs(other.ids) do
    if self.ids[k] < v then self.ids[k] = v end
  end
end

local has = function(self, x)
  return not not next(self.payload[x])
end

local value = function(self)
  local r = LSet.new()
  for k,v in pairs(self.payload) do
    if next(v) then r:add(k) end
  end
  return r
end

local methods = {
  add = add, -- (x) -> !
  del = del, -- (x) -> !
  has = has, -- (x) -> bool
  merge = merge, -- (other) -> !
  value = value, -- () -> LSet
}

--- CLASS

local new = function(node)
  if not node then error("invalid") end
  local r = {
    node = node,
    ids = utils.defmap(0),
    payload = utils.defmap_of_tables(),
  }
  return setmetatable(r,{__index = methods})
end

return {
  new = new, -- (node) -> Optimized  OR-Set
}
