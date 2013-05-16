local bimap = function(t0,t)
  for i=t0,#t do t[t[i]]=i end
  return t
end

local stack = function(t)
  return t
end

return {
  bimap = bimap,
  stack = stack,
}
