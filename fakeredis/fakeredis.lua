--- Helpers

local xdefv = function(ktype)
  if ktype == "list" then
    return {head=0,tail=0}
  else return {} end
end

local xgetr = function(self,k,ktype)
  if self[k] then
    assert(
      (self[k].ktype == ktype),
      "ERR Operation against a key holding the wrong kind of value"
    )
    assert(self[k].value)
    return self[k].value
  else return xdefv(ktype) end
end

local xgetw = function(self,k,ktype)
  if self[k] and self[k].value then
    assert(self[k].ktype == ktype)
  else
    self[k] = {ktype=ktype,value=xdefv(ktype)}
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
  elseif t == "list" then
    return v.head == v.tail
  else print(self.ktype); error("unsupported") end
end

local chkarg = function(x)
  if type(x) == "number" then x = tostring(x) end
  assert(type(x) == "string")
  return x
end

local chkargs = function(n,...)
  local arg = {...}
  assert(#arg == n)
  for i=1,n do arg[i] = chkarg(arg[i]) end
  return unpack(arg)
end

local getargs = function(...)
  local arg = {...}
  local n = #arg; assert(n > 0)
  for i=1,n do arg[i] = chkarg(arg[i]) end
  return arg
end

local getargs_as_map = function(...)
  local arg,r = getargs(...),{}
  assert(#arg%2 == 0)
  for i=0,#arg/2-1 do r[arg[2*i+1]] = arg[2*i+2] end
  return r
end

local chkargs_wrap = function(f,n)
  assert( (type(f) == "function") and (type(n) == "number") )
  return function(self,...) return f(self,chkargs(n,...)) end
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
  assert(type(pattern) == "string")
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
  return self[k] and self[k].ktype or "none"
end

local randomkey = function(self)
  local ks = lset_to_list(self)
  local n = #ks
  if n > 0 then
    return ks[math.random(1,n)]
  else return nil end
end

local rename = function(self,k,k2)
  assert((k ~= k2) and self[k])
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
  local x = xgetw(self,k,"string")
  x[1] = (x[1] or "") .. v
  return #x[1]
end

local get = function(self,k)
  local x = xgetr(self,k,"string")
  return x[1]
end

local getrange = function(self,k,i1,i2)
  k = chkarg(k)
  assert( (type(i1) == "number") and (type(i2) == "number") )
  local x = xgetr(self,k,"string")
  x = x[1] or ""
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

local setrange = function(self,k,i,s)
  local k,s = chkargs(2,k,s)
  assert( (type(i) == "number") and  (i >= 0) )
  local x = xgetw(self,k,"string")
  local y = x[1] or ""
  local ly,ls = #y,#s
  if i > ly then -- zero padding
    local t = {}
    for i=1,i-ly do t[i] = "\0" end
    y = y .. table.concat(t) .. s
  else
    y = y:sub(1,i) .. s .. y:sub(i+ls+1,ly)
  end
  x[1] = y
  return #y
end

local strlen = function(self,k)
  local x = xgetr(self,k,"string")
  return x[1] and #x[1] or 0
end

-- hashes

local hdel = function(self,k,...)
  k = chkarg(k)
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
  local x = xgetr(self,k,"hash")
  return x[k2]
end

local hgetall = function(self,k)
  local x = xgetr(self,k,"hash")
  local r = {}
  for _k,v in pairs(x) do r[_k] = v end
  return r
end

local hkeys = function(self,k)
  local x = xgetr(self,k,"hash")
  local r = {}
  for _k,_ in pairs(x) do r[#r+1] = _k end
  return r
end

local hlen = function(self,k)
  local x = xgetr(self,k,"hash")
  return nkeys(x)
end

local hmget = function(self,k,k2s)
  k = chkarg(k)
  assert((type(k2s) == "table"))
  local r = {}
  local x = xgetr(self,k,"hash")
  for i=1,#k2s do r[i] = x[chkarg(k2s[i])] end
  return r
end

local hmset = function(self,k,m)
  k = chkarg(k)
  assert((type(m) == "table"))
  local x = xgetw(self,k,"hash")
  for _k,v in pairs(m) do x[chkarg(_k)] = chkarg(v) end
  return true
end

local hset = function(self,k,k2,v)
  local x = xgetw(self,k,"hash")
  local r = not x[k2]
  x[k2] = v
  return r
end

local hsetnx = function(self,k,k2,v)
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

-- lists (head = left, tail = right)

local _l_real_i = function(x,i)
  if i < 0 then
    return x.tail+i+1
  else
    return x.head+i+1
  end
end

local _l_len = function(x)
  return x.tail - x.head
end

local lindex = function(self,k,i)
  k = chkarg(k)
  assert(type(i) == "number")
  local x = xgetr(self,k,"list")
  return x[_l_real_i(x,i)]
end

local llen = function(self,k)
  local x = xgetr(self,k,"list")
  return _l_len(x)
end

local lpop = function(self,k)
  local x = xgetw(self,k,"list")
  local l,r = _l_len(x),x[x.head+1]
  if l > 1 then
    x.head = x.head + 1
    x[x.head] = nil
  else self[k] = nil end
  return r
end

local lpush = function(self,k,v)
  local x = xgetw(self,k,"list")
  x[x.head] = v
  x.head = x.head - 1
  return _l_len(x)
end

local lrange = function(self,k,i1,i2)
  k = chkarg(k)
  assert( (type(i1) == "number") and (type(i2) == "number") )
  local x,r = xgetr(self,k,"list"),{}
  i1 = math.max(_l_real_i(x,i1),x.head+1)
  i2 = math.min(_l_real_i(x,i2),x.tail)
  if i1 <= i2 then
    for i=i1,i2 do r[#r+1] = x[i] end
  end
  return r
end

local rpop = function(self,k)
  local x = xgetw(self,k,"list")
  local l,r = _l_len(x),x[x.tail]
  if l > 1 then
    x[x.tail] = nil
    x.tail = x.tail - 1
  else self[k] = nil end
  return r
end

local rpush = function(self,k,v)
  local x = xgetw(self,k,"list")
  x.tail = x.tail + 1
  x[x.tail] = v
  return _l_len(x)
end

-- sets

local sadd = function(self,k,...)
  k = chkarg(k)
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
  k = chkarg(k)
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
  k2 = chkarg(k2)
  local x = _sdiff(self,k,...)
  self[k2] = {ktype="set",value=x}
  return nkeys(x)
end

local _sinter = function(self,k,...)
  k = chkarg(k)
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
  k2 = chkarg(k2)
  local x = _sinter(self,k,...)
  self[k2] = {ktype="set",value=x}
  return nkeys(x)
end

local sismember = function(self,k,v)
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
  k = chkarg(k)
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
  k2 = chkarg(k2)
  local x = _sunion(self,k,...)
  self[k2] = {ktype="set",value=x}
  return nkeys(x)
end

-- connection

local echo = function(self,v)
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
  del = del, -- (...) -> #removed
  exists = chkargs_wrap(exists,1), -- (k) -> exists?
  keys = keys, -- (pattern) -> list of keys
  ["type"] = chkargs_wrap(_type,1), -- (k) -> [string|list|set|zset|hash|none]
  randomkey = randomkey, -- () -> [k|nil]
  rename = chkargs_wrap(rename,2), -- (k,k2) -> true
  renamenx = chkargs_wrap(renamenx,2), -- (k,k2) -> renamed? (i.e. !existed? k2)
  -- strings
  append = chkargs_wrap(append,2), -- (k,v) -> #new
  get = chkargs_wrap(get,1), -- (k) -> [v|nil]
  getrange = getrange, -- (k,start,end) -> string
  getset = chkargs_wrap(getset,2), -- (k,v) -> [oldv|nil]
  mget = mget, -- (k1,...) -> {v1,...}
  mset = mset, -- (k1,v1,...) -> true
  msetnx = msetnx, -- (k1,v1,...) -> worked? (i.e. !existed? any k)
  set = chkargs_wrap(set,2), -- (k,v) -> true
  setnx = chkargs_wrap(setnx,2), -- (k,v) -> worked? (i.e. !existed?)
  setrange = setrange, -- (k,offset,val) -> #new
  strlen = chkargs_wrap(strlen,1), -- (k) -> [#v|0]
  -- hashes
  hdel = hdel, -- (k,sk1,...) -> #removed
  hexists = chkargs_wrap(hexists,2), -- (k,sk) -> exists?
  hget = chkargs_wrap(hget,2), -- (k,sk) -> v
  hgetall = chkargs_wrap(hgetall,1), -- (k) -> map
  hkeys = chkargs_wrap(hkeys,1), -- (k) -> keys
  hlen = chkargs_wrap(hlen,1), -- (k) -> [#sk|0]
  hmget = hmget, -- (k,{sk1,...}) -> {v1,...}
  hmset = hmset, -- (k,{sk1=v1,...}) -> true
  hset = chkargs_wrap(hset,3), -- (k,sk1,v1) -> !existed?
  hsetnx = chkargs_wrap(hsetnx,3), -- (k,sk1,v1) -> worked? (i.e. !existed?)
  hvals = chkargs_wrap(hvals,1), -- (k) -> values
  -- lists
  lindex = lindex, -- (k,i) -> v
  llen = chkargs_wrap(llen,1), -- (k) -> #list
  lpop = chkargs_wrap(lpop,1), -- (k) -> v
  lpush = chkargs_wrap(lpush,2), -- (k,v1) -> #list (after) -- TODO variadic
  lrange = lrange, -- (k,start,stop) -> list
  rpop = chkargs_wrap(rpop,1), -- (k) -> v
  rpush = chkargs_wrap(rpush,2), -- (k,v1) -> #list (after) -- TODO variadic
  -- sets
  sadd = sadd, -- (k,v1,...) -> #added
  scard = chkargs_wrap(scard,1), -- (k) -> [n|0]
  sdiff = sdiff, -- (k1,...) -> set (of elements in k1 & not in any of ...)
  sdiffstore = sdiffstore, -- (k0,k1,...) -> #set at k0
  sinter = sinter, -- (k1,...) -> set
  sinterstore = sinterstore, -- (k0,k1,...) -> #set at k0
  sismember = chkargs_wrap(sismember,2), -- (k,v) -> member?
  smembers = chkargs_wrap(smembers,1), -- (k) -> set
  smove = chkargs_wrap(smove,3), -- (k1,k2,v) -> moved? (i.e. !member? k1)
  spop = chkargs_wrap(spop,1), -- (k) -> [v|nil]
  srandmember = chkargs_wrap(srandmember,1), -- (k) -> v -- TODO support count
  srem = srem, -- (k,v1,...) -> #removed
  sunion = sunion, -- (k1,...) -> set
  sunionstore = sunionstore, -- (k0,k1,...) -> #set at k0
  -- connection
  echo = chkargs_wrap(echo,1), -- (v) -> v
  ping = ping, -- () -> PONG
  -- server
  flushall = flushdb, -- () -> true
  flushdb = flushdb, -- () -> true
}

local new = function()
  local r = {}
  return setmetatable(r,{__index = methods})
end

return {
  new = new,
}
