-- Utils

local mkuid = function()
  -- for now just a random number will do
  return math.random()
end

local defmap = function(def)
  assert(def)
  return setmetatable({}, {__index = function() return def end})
end

return {
  mkuid = mkuid, -- () -> uid
  defmap = defmap, -- ([def]) -> defmap
}
