-- OR-Set

local GSet = require "g_set"
local LSet = require "lua_set"
local utils = require "utils"

--- METHODS

local has = function(self, x)
  local v = self.e[x]
  return v and (v:card() > 0)
end

local value = function(self)
  local r = LSet.new()
  for k,v in pairs(self.e) do
    if v.c:card() > 0 then
      r:add(k)
    end
  end
  return r
end

local add = function(self, x)
  local uid = utils.mkuid()
  self.e[x].c:add(uid)
end

local del = function(self, x)
  local t = self.e[x].c:as_list()
  for i=1,#t do self.e[x].r:add(t[i]) end
  self.e[x].c = LSet.new()
end

local merge = function(self, other)
  for k,v in pairs(other.e) do
    -- merge adds
    local t = v.c:as_list()
    for i=1,#t do
      if not self.e[k].r:has(t[i]) then
        self.e[k].c:add(t[i])
      end
    end
    -- merge removes
    local t = v.r:value():as_list()
    for i=1,#t do
      if self.e[k].c:has(t[i]) then
        self.e[k].c:del(t[i])
      end
    end
    self.e[k].r:merge(v.r)
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

local _maker = function()
  return {
    c = LSet.new(),
    r = GSet.new(),
  }
end

local new = function(node)
  if not node then error("invalid") end
  local r = {
    node = node,
    e = utils.defmap2(_maker),
  }
  return setmetatable(r, {__index = methods})
end

return {
  new = new, -- (node) -> OR-Set
}
