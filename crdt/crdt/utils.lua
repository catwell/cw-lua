-- Utils

local mkuid = function()
  -- for now just a random number will do
  return math.random()
end

local defmap = function(def)
  assert(def)
  return setmetatable({}, {__index = function() return def end})
end

local defmap2 = function(maker)
  assert (type(maker) == "function")
  local f = function(t, k)
    t[k] = maker(k)
    return t[k]
  end
  return setmetatable({}, {__index = f})
end

local variadify = function(f, merge)
  assert(type(f) == "function")
  if merge then assert(type(merge) == "function") end
  return function(self, ...)
    local arg = {...}
    local n = #arg
    assert(n > 0)
    if merge then
      local r = {}
      for i=1,n do r[i] = f(self, arg[i]) end
      return merge(r)
    else
      for i=1,n do f(self, arg[i]) end
    end
  end
end

local fold_and = function(t)
  local r = true
  for i=1,#t do r = r and t[i] end
  return r
end

return {
  mkuid = mkuid, -- () -> uid
  defmap = defmap, -- (defval) -> defmap
  defmap2 = defmap2, -- (defval_f) -> defmap
  variadify = variadify, -- (f) -> variadic f
  fold_and = fold_and, -- (t) -> and(*t)
}
