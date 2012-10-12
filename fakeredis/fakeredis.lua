--- Helpers

local xgetr = function(self,k,ktype)
  if self[k] then
    assert(self[k].ktype == ktype)
    assert(self[k].value)
    return self[k].value
  else return {} end
end

local xgetw = function(self,k,ktype)
  if self[k] and self[k].value then
    assert(self[k].ktype == ktype)
  else
    self[k] = {ktype=ktype,value={}}
  end
  return self[k].value
end

local empty = function(self,k)
  return #self[k].value == 0
end

-- keys

local del = function(self,...)
  local arg = {...}
  assert(#arg > 0)
  local r = 0
  for i=1,#arg do
    if self[arg[i]] and (not empty(self,arg[i])) then r = r + 1 end
    self[arg[i]] = nil
  end
  return r
end

local flushdb = function(self)
  for k,_ in pairs(self) do self[k] = nil end
  return true
end

-- strings

local set = function(self,k,v)
  assert(type(v) == "string")
  local x = xgetw(self,k,"string")
  x[1] = v
  return true
end

local get = function(self,k)
  local x = xgetr(self,k,"string")
  return x[1]
end

-- hashes

local hset = function(self,k,k2,v)
  assert((type(k2) == "string") and (type(v) == "string"))
  local x = xgetw(self,k,"hash")
  x[k2] = v
  return true
end

local hget = function(self,k,k2)
  assert((type(k2) == "string"))
  local x = xgetr(self,k,"hash")
  return x[k2]
end

local hdel = function(self,k,...)
  local arg = {...}
  assert(#arg > 0)
  local r = 0
  local x = xgetw(self,k,"hash")
  for i=1,#arg do
    assert((type(arg[i]) == "string"))
    if x[arg[i]] then r = r + 1 end
    x[arg[i]] = nil
  end
  return r
end

-- sets

local methods = {
  -- keys
  flushall = flushdb,
  flushdb = flushdb,
  del = del,
  -- strings
  get = get,
  set = set,
  -- hashes
  hget = hget,
  hset = hset,
  hdel = hdel,
}

--- Class

local new = function()
  local r = {}
  return setmetatable(r,{__index = methods})
end

return {
  new = new,
}

