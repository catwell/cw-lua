-- Optimized OR-Set (Add Wins)
--
-- See paper: An Optimized Conflict-free Replicated Set
-- Bienius, Zawirski, Preguiça, Shapiro, Baquero, Balegas & Duarte
-- http://arxiv.org/pdf/1210.3368.pdf

local LSet = require "lua_set"
local utils = require "utils"

local incr_id = function(self)
  local id = self.ids[self.node] + 1
  self.ids[self.node] = id
  return id
end

--- METHODS

local has = function(self, x)
  local p = rawget(self.payload, x)
  return not not (p and next(p))
end

local value = function(self)
  local r = LSet.new()
  for k,v in pairs(self.payload) do
    if next(v) then r:add(k) end
  end
  return r
end

local add = function(self, x)
  self.payload[x][self.node] = incr_id(self)
end

local del = function(self, x)
  self.payload[x] = nil
end

local merge = function(self, other)
  -- apply changes observed by distant node
  for k,v in pairs(other.payload) do
    for node,uid in pairs(v) do
      if uid > self.ids[node] then
        self.payload[k][node] = uid
      end
    end
  end
  -- make distant removes effective and collect garbage
  for k,v in pairs(self.payload) do
    for node,uid in pairs(v) do
      if other.ids[node] >= uid then
        -- next line strictly equivalent to:
        -- if not other.payload[k][node] then v[node] = nil end
        v[node] = other.payload[k][node]
      end
    end
    if not next(v) then v[k] = nil end
  end
  -- merge replica ids
  for k,v in pairs(other.ids) do
    if self.ids[k] < v then self.ids[k] = v end
  end
end

local methods = {
  has = utils.variadify(has, utils.fold_and), -- (x) -> bool
  value = value, -- () -> LSet
  add = utils.variadify(add), -- (x) -> !
  del = utils.variadify(del), -- (x) -> !
  merge = merge, -- (other) -> !
}

--- CLASS

local _maker = function() return {} end

local new = function(node)
  if not node then error("invalid") end
  local r = {
    node = node,
    ids = utils.defmap(0),
    payload = utils.defmap2(_maker),
  }
  return setmetatable(r, {__index = methods})
end

return {
  new = new, -- (node) -> Optimized OR-Set (Add Wins)
}
