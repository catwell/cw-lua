-- Optimized OR-Set (Remove Wins)
--
-- The idea comes from a Twitter discussion with Carlos Baquero
-- and reading slide 30 of this document:
-- www.dagstuhl.de/mat/Files/13/13081/13081.BaqueroCarlos.Slides.pdf
--
-- Not entirely sure what I implemented is exactly what
-- the authors had in mind though :)
--
-- Unlike in the OR-Set (Add Wins), empty table values in
-- the payload do mean something, so they cannot be GCd.
-- This increases the worst-case space complexity to
-- O( elements + nodes * (removes + 1) ).

local LSet = require "lua_set"
local utils = require "utils"

local cur_id = function(self)
  return self.ids[self.node]
end

local incr_id = function(self)
  local id = self.ids[self.node] + 1
  self.ids[self.node] = id
  return id
end

--- METHODS

local has = function(self, x)
  local p = rawget(self.payload, x)
  return not not (p and not next(p))
end

local value = function(self)
  local r = LSet.new()
  for k,v in pairs(self.payload) do
    if not next(v) then r:add(k) end
  end
  return r
end

local add = function(self, x)
  self.payload[x] = {}
end

local del = function(self, x)
  if self.strict and not has(self, x) then error("invalid") end
  self.payload[x][self.node] = incr_id(self)
end

local merge = function(self, other)
  -- apply changes observed by distant node
  for k,v in pairs(other.payload) do
    if not rawget(self.payload, k) then
      self.payload[k] = {}
    end
    for node,uid in pairs(v) do
      if uid > self.ids[node] then
        self.payload[k][node] = uid
      end
    end
  end
  -- make distant adds effective
  for k,v in pairs(self.payload) do
    for node,uid in pairs(v) do
      if other.ids[node] >= uid then
        -- next line strictly equivalent to:
        -- if not other.payload[k][node] then v[node] = nil end
        v[node] = other.payload[k][node]
      end
    end
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

local new = function(node, strict)
  -- strict: disallow removing members not yet observed
  if not node then error("invalid") end
  local r = {
    node = node,
    ids = utils.defmap(0),
    payload = utils.defmap2(_maker),
    strict = not not strict,
  }
  return setmetatable(r, {__index = methods})
end

return {
  new = new, -- (node) -> Optimized  OR-Set (Remove Wins)
}
