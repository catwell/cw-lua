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
    t[k] = maker()
    return t[k]
  end
  return setmetatable({}, {__index = f})
end

return {
  mkuid = mkuid, -- () -> uid
  defmap = defmap, -- (defval) -> defmap
  defmap2 = defmap2, -- (defval_f) -> defmap
}
