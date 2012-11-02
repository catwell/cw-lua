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
  elseif (t == "hash") or (t == "set") then
    for _,_ in pairs(v) do return false end
    return true
  else print(self.ktype); error("unsupported") end
end

local getargs = function(...)
  local arg = {...}
  local n = #arg; assert(n > 0)
  for i=1,n do assert(type(arg[i]) == "string") end
  return arg
end

local getargs_as_map = function(...)
  local arg,r = getargs(...),{}
  if (#arg == 1) and type(arg[1] == "table") then
    r = arg[1]
  else
    assert(#arg%2 == 0)
    for i=0,#arg/2-1 do r[arg[2*i+1]] = arg[2*i+2] end
  end
  return r
end

local lset_to_list = function(s)
  local r = {}
  for v,_ in pairs(s) do r[#r+1] = v end
  return r
end

local nkeys = function(x)
  local r = 0
  for _,_ in pairs(x) do r = r + 1 end
  return r
end

--- Commands

-- keys

local del = function(self,...)
  local arg = getargs(...)
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

local keys = function(self,pattern)
  -- We want to convert the Redis pattern to a Lua pattern.
  -- Start by escaping dashes *outside* character classes.
  -- We also need to escape percents here.
  local t,p,n = {},1,#pattern
  local p1,p2
  while true do
    p1,p2 = pattern:find("%[.+%]",p)
    if p1 then
      if p1 > p then
        t[#t+1] = {true,pattern:sub(p,p1-1)}
      end
      t[#t+1] = {false,pattern:sub(p1,p2)}
      p = p2+1
      if p > n then break end
    else
      t[#t+1] = {true,pattern:sub(p,n)}
      break
    end
  end
  for i=1,#t do
    if t[i][1] then
      t[i] = t[i][2]:gsub("[%%%-]","%%%0")
    else t[i] = t[i][2]:gsub("%%","%%%%") end
  end
  -- Remaining Lua magic chars are: '^$().[]*+?' ; escape them except '*?[]'
  -- Then convert '\' to '%', '*' to '.*' and '?' to '.'. Leave '[]' as is.
  -- Wrap in '^$' to enforce bounds.
  local lp = "^" .. table.concat(t):gsub("[%^%$%(%)%.%+]","%%%0")
    :gsub("\\","%%"):gsub("%*","%.%*"):gsub("%?","%.") .. "$"
  local r = {}
  for k,_ in pairs(self) do
    if k:match(lp) then r[#r+1] = k end
  end
  return r
end

local _type = function(self,k)
  return (self[k] and self[k].ktype) and self[k].ktype or "none"
end

local randomkey = function(self)
  local ks = lset_to_list(self)
  local n = #ks
  if n > 0 then
    return ks[math.random(1,n)]
  else return nil end
end

local rename = function(self,k,k2)
  assert((k ~= k2) and self[k] and (type(k2) == "string"))
  self[k2] = self[k]
  self[k] = nil
  return true
end

local renamenx = function(self,k,k2)
  if self[k2] then
    return false
  else
    return rename(self,k,k2)
  end
end

-- strings

local set

local append = function(self,k,v)
  assert(type(v) == "string")
  local x = xgetw(self,k,"string")
  x[1] = (x[1] or "") .. v
  return #x[1]
end

local get = function(self,k)
  local x = xgetr(self,k,"string")
  return x[1]
end

local getrange = function(self,k,i1,i2)
  local x = xgetr(self,k,"string")
  x = x[1] or ""
  i1,i2 = tonumber(i1),tonumber(i2)
  assert(i1 and i2)
  if i1 >= 0 then i1 = i1 + 1 end
  if i2 >= 0 then i2 = i2 + 1 end
  return x:sub(i1,i2)
end

local getset = function(self,k,v)
  local r = get(self,k)
  set(self,k,v)
  return r
end

local mget = function(self,...)
  local arg,r = getargs(...),{}
  for i=1,#arg do r[i] = get(self,arg[i]) end
  return r
end

local mset = function(self,...)
  local argmap = getargs_as_map(...)
  for k,v in pairs(argmap) do set(self,k,v) end
  return true
end

local msetnx = function(self,...)
  local argmap = getargs_as_map(...)
  for k,_ in pairs(argmap) do
    if self[k] then return false end
  end
  for k,v in pairs(argmap) do set(self,k,v) end
  return true
end

set = function(self,k,v)
  assert(type(v) == "string")
  self[k] = {ktype="string",value={v}}
  return true
end

local setnx = function(self,k,v)
  if self[k] then
    return false
  else
    return set(self,k,v)
  end
end

local strlen = function(self,k)
  local x = xgetr(self,k,"string")
  return x[1] and #x[1] or 0
end

-- hashes

local hdel = function(self,k,...)
  local arg = getargs(...)
  local r = 0
  local x = xgetw(self,k,"hash")
  for i=1,#arg do
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
  return nkeys(x)
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

-- sets

local sadd = function(self,k,...)
  local arg = getargs(...)
  local x,r = xgetw(self,k,"set"),0
  for i=1,#arg do
    if not x[arg[i]] then
      x[arg[i]] = true
      r = r + 1
    end
  end
  return r
end

local scard = function(self,k)
  local x = xgetr(self,k,"set")
  return nkeys(x)
end

local _sdiff = function(self,k,...)
  local arg = getargs(...)
  local x = xgetr(self,k,"set")
  local r = {}
  for v,_ in pairs(x) do r[v] = true end
  for i=1,#arg do
    x = xgetr(self,arg[i],"set")
    for v,_ in pairs(x) do r[v] = nil end
  end
  return r
end

local sdiff = function(self,k,...)
  return lset_to_list(_sdiff(self,k,...))
end

local sdiffstore = function(self,k2,k,...)
  assert(type(k2) == "string")
  local x = _sdiff(self,k,...)
  self[k2] = {ktype="set",value=x}
  return nkeys(x)
end

local _sinter = function(self,k,...)
  local arg = getargs(...)
  local x = xgetr(self,k,"set")
  local r = {}
  local y
  for v,_ in pairs(x) do
    r[v] = true
    for i=1,#arg do
      y = xgetr(self,arg[i],"set")
      if not y[v] then r[v] = nil; break end
    end
  end
  return r
end

local sinter = function(self,k,...)
  return lset_to_list(_sinter(self,k,...))
end

local sinterstore = function(self,k2,k,...)
  assert(type(k2) == "string")
  local x = _sinter(self,k,...)
  self[k2] = {ktype="set",value=x}
  return nkeys(x)
end

local sismember = function(self,k,v)
  assert((type(v) == "string"))
  local x = xgetr(self,k,"set")
  return not not x[v]
end

local smembers = function(self,k)
  local x = xgetr(self,k,"set")
  return lset_to_list(x)
end

local smove = function(self,k,k2,v)
  local x = xgetr(self,k,"set")
  if x[v] then
    local y = xgetw(self,k2,"set")
    x[v] = nil
    y[v] = true
    return true
  else return false end
end

local spop = function(self,k)
  local x,r = xgetw(self,k,"set"),nil
  local l = lset_to_list(x)
  local n = #l
  if n > 0 then
    r = l[math.random(1,n)]
    x[r] = nil
  end
  if empty(self,k) then self[k] = nil end
  return r
end

local srandmember = function(self,k)
  local x = xgetr(self,k,"set")
  local l = lset_to_list(x)
  local n = #l
  if n > 0 then
    return l[math.random(1,n)]
  else return nil end
end

local srem = function(self,k,...)
  local arg = getargs(...)
  local x,r = xgetw(self,k,"set"),0
  for i=1,#arg do
    if x[arg[i]] then
      x[arg[i]] = nil
      r = r + 1
    end
  end
  if empty(self,k) then self[k] = nil end
  return r
end

local _sunion = function(self,...)
  local arg = getargs(...)
  local r = {}
  local x
  for i=1,#arg do
    x = xgetr(self,arg[i],"set")
    for v,_ in pairs(x) do r[v] = true end
  end
  return r
end

local sunion = function(self,k,...)
  return lset_to_list(_sunion(self,k,...))
end

local sunionstore = function(self,k2,k,...)
  assert(type(k2) == "string")
  local x = _sunion(self,k,...)
  self[k2] = {ktype="set",value=x}
  return nkeys(x)
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
  keys = keys,
  ["type"] = _type,
  randomkey = randomkey,
  rename = rename,
  renamenx = renamenx,
  -- strings
  append = append,
  get = get,
  getrange = getrange,
  getset = getset,
  mget = mget,
  mset = mset,
  msetnx = msetnx,
  set = set,
  setnx = setnx,
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
  -- sets
  sadd = sadd,
  scard = scard,
  sdiff = sdiff,
  sdiffstore = sdiffstore,
  sinter = sinter,
  sinterstore = sinterstore,
  sismember = sismember,
  smembers = smembers,
  smove = smove,
  spop = spop,
  srandmember = srandmember,
  srem = srem,
  sunion = sunion,
  sunionstore = sunionstore,
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
