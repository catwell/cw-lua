-- OR-Set

local USet = require "u_set"
local GSet = require "g_set"
local LSet = require "lua_set"
local utils = require "utils"

--- METHODS

local uses = function(self,x)
  if not self.e[x] then
    self.e[x] = {
      c = USet.new(),
      r = GSet.new(),
    }
  end
end

local add = function(self,x)
  uses(self,x)
  local uid = utils.mkuid()
  self.e[x].c:add(uid)
end

local del = function(self,x)
  uses(self,x)
  local t = self.e[x].c:value():as_list()
  for i=1,#t do self.e[x].r:add(t[i]) end
  self.e[x].c = USet.new()
end

local merge = function(self,other)
  for k,v in pairs(other.e) do
    uses(self,k)
    local t = v.c:value():as_list()
    for i=1,#t do
      if not self.e[k].r:has(t[i]) then
        self.e[k].c:add(t[i])
      end
    end
    self.e[k].r:merge(v.r)
  end
end

local value = function(self)
  local r = LSet.new()
  for k,v in pairs(self.e) do
    if v.c:value():card() > 0 then
      r:add(k)
    end
  end
  return r
end

local methods = {
  add = add, -- (x) -> !
  del = del, -- (x) -> !
  merge = merge, -- (other) -> !
  value = value, -- () -> LSet
}

--- CLASS

local new = function(node)
  if not node then error("invalid") end
  local r = {node = node,e = {}}
  return setmetatable(r,{__index = methods})
end

return {
  new = new, -- (node) -> OR-Set
}
