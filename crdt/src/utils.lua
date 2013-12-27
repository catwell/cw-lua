-- Utils

local mkuid = function()
  -- for now just a random number will do
  return math.random()
end

local defmap = function(def)
  assert(def)
  return setmetatable({}, {__index = function() return def end})
end

local defmap_of_tables = function()
  local f = function(t, k)
    t[k] = {}
    return t[k]
  end
  return setmetatable({}, {__index = f})
end

return {
  mkuid = mkuid, -- () -> uid
  defmap = defmap, -- ([def]) -> defmap
  defmap_of_tables = defmap_of_tables, -- () -> defmap
}
