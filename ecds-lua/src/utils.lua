-- Utils

local mkuid = function()
  -- for now just a random number will do
  return math.random()
end

return {
  mkuid = mkuid, -- () -> uid
}
