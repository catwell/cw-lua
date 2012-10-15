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
  local v,t = self[k].value,self[k].ktype
  if t == nil then
    return true
  elseif t == "string" then
    return not v[1]
  elseif t == "hash" then
    for _,_ in pairs(v) do return false end
    return true
  else print(self.ktype); error("unsupported") end
end

--- Commands

-- keys

local del = function(self,...)
  local arg = {...}
  assert(#arg > 0)
  local r = 0
  for i=1,#arg do
    if self[arg[i]] then r = r + 1 end
    self[arg[i]] = nil
  end
  return r
end

local exists = function(self,k)
  return not not self[k]
end

local _type = function(self,k)
  return (self[k] and self[k].ktype) and self[k].ktype or "none"
end

-- strings

local get = function(self,k)
  local x = xgetr(self,k,"string")
  return x[1]
end

local set = function(self,k,v)
  assert(type(v) == "string")
  self[k] = {ktype="string",value={v}}
  return true
end

local strlen = function(self,k)
  local x = xgetr(self,k,"string")
  return x[1] and #x[1] or 0
end

-- hashes

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
  if empty(self,k) then self[k] = nil end
  return r
end

local hget
local hexists = function(self,k,k2)
  return not not hget(self,k,k2)
end

hget = function(self,k,k2)
  assert((type(k2) == "string"))
  local x = xgetr(self,k,"hash")
  return x[k2]
end

local hgetall = function(self,k)
  local x = xgetr(self,k,"hash")
  local r = {}
  for k,v in pairs(x) do r[k] = v end
  return r
end

local hkeys = function(self,k)
  local x = xgetr(self,k,"hash")
  local r = {}
  for k,_ in pairs(x) do r[#r+1] = k end
  return r
end

local hlen = function(self,k)
  local x = xgetr(self,k,"hash")
  local r = 0
  for _,_ in pairs(x) do r = r + 1 end
  return r
end

local hmget = function(self,k,k2s)
  assert((type(k2s) == "table"))
  local r = {}
  local x = xgetr(self,k,"hash")
  for i=1,#k2s do r[i] = x[k2s[i]] end
  return r
end

local hmset = function(self,k,m)
  assert((type(m) == "table"))
  local x = xgetw(self,k,"hash")
  for k,v in pairs(m) do
    assert((type(k) == "string") and (type(v) == "string"))
    x[k] = v
  end
  return true
end

local hset = function(self,k,k2,v)
  assert((type(k2) == "string") and (type(v) == "string"))
  local x = xgetw(self,k,"hash")
  x[k2] = v
  return true
end

local hsetnx = function(self,k,k2,v)
  assert((type(k2) == "string") and (type(v) == "string"))
  local x = xgetw(self,k,"hash")
  if x[k2] == nil then
    x[k2] = v
    return true
  else
    return false
  end
end

local hvals = function(self,k)
  local x = xgetr(self,k,"hash")
  local r = {}
  for _,v in pairs(x) do r[#r+1] = v end
  return r
end

-- connection

local echo = function(self,v)
  assert(type(v) == "string")
  return v
end

local ping = function(self)
  return "PONG"
end

-- server

local flushdb = function(self)
  for k,_ in pairs(self) do self[k] = nil end
  return true
end

--- Class

local methods = {
  -- keys
  del = del,
  exists = exists,
  ["type"] = _type,
  -- strings
  get = get,
  set = set,
  strlen = strlen,
  -- hashes
  hdel = hdel,
  hexists = hexists,
  hget = hget,
  hgetall = hgetall,
  hkeys = hkeys,
  hlen = hlen,
  hmget = hmget,
  hmset = hmset,
  hset = hset,
  hsetnx = hsetnx,
  hvals = hvals,
  -- connection
  echo = echo,
  ping = ping,
  -- server
  flushall = flushdb,
  flushdb = flushdb,
}

local new = function()
  local r = {}
  return setmetatable(r,{__index = methods})
end

return {
  new = new,
}

