local fakeredis = require "fakeredis"
local R = fakeredis.new()

local printf = function(p,...)
  io.stdout:write(string.format(p,...)); io.stdout:flush()
end

local do_test_silent = function(v1,v2)
  if type(v1) ~= type(v2) then
    error(string.format("expected %s, got %s",type(v2),type(v1)))
  elseif v1 ~= v2 then
    error(string.format("expected %s, got %s",tostring(v2),tostring(v1)))
  end
end

local do_test = function(v1,v2)
  printf(".")
  do_test_silent(v1,v2)
end

local do_test_nil = function(k)
  printf(".")
  do_test_silent(R:get(k),nil)
  do_test_silent(R:type(k),"none")
  do_test_silent(R:exists(k),false)
end

local do_test_nil_hash = function(k,k2)
  printf(".")
  do_test_silent(R:hget(k,k2),nil)
  do_test_silent(R:hexists(k,k2),false)
end

local do_test_list = function(t1,t2,n)
  printf(".")
  for k,_ in pairs(t1) do do_test_silent(type(k),"number") end
  for k,_ in pairs(t2) do do_test_silent(type(k),"number") end
  if not n then
    do_test_silent(#t1,#t2)
    n = #t1
  end
  for i=1,n do do_test_silent(t1[i],t2[i]) end
end

do_test_set = function(t1,t2)
  printf(".")
  do_test_silent(#t1,#t2)
  table.sort(t1); table.sort(t2)
  for k,v in pairs(t1) do do_test_silent(v,t2[k]) end
  for k,v in pairs(t2) do do_test_silent(v,t1[k]) end
end

local do_test_hash = function(t1,t2)
  printf(".")
  do_test_silent(#t1,0)
  do_test_silent(#t2,0)
  for k,v in pairs(t1) do do_test_silent(v,t2[k]) end
  for k,v in pairs(t2) do do_test_silent(v,t1[k]) end
end

-- strings

printf("strings ")
do_test(R:flushdb(),true)
do_test_nil("foo")
do_test(R:strlen("foo"),0)
do_test(R:set("foo","bar"),true)
do_test(R:exists("foo"),true)
do_test(R:get("foo"),"bar")
do_test(R:type("foo"),"string")
do_test(R:strlen("foo"),3)
do_test(R:del("foo"),1)
do_test_nil("foo")
do_test(R:hset("foo","spam","eggs"),true)
do_test(R:type("foo"),"hash")
do_test(R:set("foo","bar"),true)
do_test(R:get("foo"),"bar")
do_test(R:type("foo"),"string")
do_test(R:renamenx("foo","chunky"),true)
do_test(R:set("spam","eggs"),true)
do_test(R:renamenx("chunky","spam"),false)
do_test(R:get("spam"),"eggs")
do_test(R:rename("chunky","spam"),true)
do_test_nil("chunky")
do_test(R:get("spam"),"bar")
do_test(R:renamenx("spam","foo"),true)
do_test_nil("spam")
do_test(R:get("foo"),"bar")
do_test(R:append("foo",""),3)
do_test(R:append("foo","bar"),6)
do_test(R:get("foo"),"barbar")
do_test(R:append("spam","eggs"),4)
do_test(R:get("spam"),"eggs")
do_test_list(R:mget("foo","chunky","spam"),{"barbar",nil,"eggs"},3)
do_test(R:mset("chunky","bacon","foo","bar"),true)
do_test_list(R:mget("foo","chunky","spam"),{"bar","bacon","eggs"},3)
do_test(R:setnx("chunky","bacon"),false)
do_test(R:del("chunky"),1)
do_test(R:setnx("chunky","bacon"),true)
do_test(R:get("chunky"),"bacon")
do_test(R:del("chunky"),1)
do_test(R:del("spam"),1)
do_test(R:msetnx("chunky","bacon","foo","bar"),false)
do_test_list(R:mget("foo","chunky","spam"),{"bar",nil,nil},3)
do_test(R:del("foo"),1)
do_test(R:msetnx("chunky","bacon","foo","bar"),true)
do_test_list(R:mget("foo","chunky","spam"),{"bar","bacon",nil},3)
do_test(R:del("foo","chunky","spam"),2)
do_test_nil("foo"); do_test_nil("spam"); do_test_nil("chunky")
print(" OK")

-- hashes

printf("hashes ")
do_test_nil("foo")
do_test(R:hlen("foo"),0)
do_test(R:hget("foo","bar"),nil)
do_test_hash(R:hgetall("foo"),{})
do_test_set(R:hkeys("foo"),{})
do_test_set(R:hvals("foo"),{})
do_test_nil_hash("foo","bar")
do_test(R:hset("foo","spam","eggs"),true)
do_test(R:exists("foo"),true)
do_test(R:hexists("foo","spam"),true)
do_test(R:type("foo"),"hash")
do_test(R:hget("foo","bar"),nil)
do_test(R:hset("foo","bar","baz"),true)
do_test(R:hget("foo","bar"),"baz")
do_test(R:hlen("foo"),2)
do_test_set(R:hkeys("foo"),{"spam","bar"})
do_test_set(R:hvals("foo"),{"eggs","baz"})
do_test_hash(R:hgetall("foo"),{spam="eggs",bar="baz"})
do_test_list(R:hmget("foo",{"spam","trap","bar"}),{"eggs",nil,"baz"},3)
do_test(R:hmset("foo",{bar="biz",chunky="bacon"}),true)
do_test_hash(R:hgetall("foo"),{spam="eggs",bar="biz",chunky="bacon"})
do_test(R:hdel("foo","bar"),1)
do_test_nil_hash("foo","bar")
do_test(R:hdel("foo","bar"),0)
do_test(R:hget("foo","spam"),"eggs")
do_test(R:hsetnx("foo","spam","spam"),false)
do_test(R:hsetnx("foo","bar","baz"),true)
do_test_hash(R:hgetall("foo"),{spam="eggs",bar="baz",chunky="bacon"})
do_test(R:hdel("foo","spam"),1)
do_test(R:hdel("foo","bar"),1)
do_test(R:hdel("foo","bar"),0)
do_test(R:hdel("foo","chunky"),1)
do_test(R:del("foo"),0)
do_test_nil_hash("foo","bar")
do_test_nil("foo")
print(" OK")

-- sets

printf("sets ")
do_test_nil("foo")
do_test(R:scard("foo"),0)
do_test(R:sismember("foo","A"),false)
do_test_set(R:smembers("foo"),{})
do_test(R:sadd("foo","A"),1)
do_test(R:exists("foo"),true)
do_test(R:type("foo"),"set")
do_test(R:scard("foo"),1)
do_test(R:sadd("foo","B"),1)
do_test(R:scard("foo"),2)
do_test(R:sadd("foo","A","C","D"),2)
do_test(R:scard("foo"),4)
do_test_set(R:smembers("foo"),{"A","B","C","D"})
do_test(R:sismember("foo","B"),true)
do_test(R:srem("foo","B"),1)
do_test(R:srem("foo","B"),0)
do_test(R:srem("foo","B","C","D","E"),2)
do_test(R:scard("foo"),1)
do_test_set(R:smembers("foo"),{"A"})
do_test(R:sismember("foo","B"),false)
do_test(R:del("foo"),1)
do_test(R:sadd("foo","A","B"),2)
do_test(R:srem("foo","A","B"),2)
do_test(R:del("foo"),0)
do_test(R:sismember("foo","A"),false)
do_test_set(R:smembers("foo"),{})
do_test_nil("foo")
do_test(R:sadd("S1","A","B","C","D","E"),5)
do_test(R:sadd("S2","A","B","F"),3)
do_test(R:sadd("S3","A","C","D"),3)
do_test_set(R:sdiff("S1","S2","S3"),{"E"})
do_test_set(R:sinter("S1","S2","S3"),{"A"})
do_test_set(R:sunion("S1","S2","S3"),{"A","B","C","D","E","F"})
do_test(R:sdiffstore("S0","S1","S2","S3"),1)
do_test_set(R:smembers("S0"),{"E"})
do_test(R:sinterstore("S0","S1","S2","S3"),1)
do_test_set(R:smembers("S0"),{"A"})
do_test(R:sunionstore("S0","S1","S2","S3"),6)
do_test_set(R:smembers("S0"),{"A","B","C","D","E","F"})
do_test(R:smove("S2","S3","F"),true)
do_test(R:smove("S2","S3","F"),false)
do_test_set(R:smembers("S2"),{"A","B"})
do_test_set(R:smembers("S3"),{"A","C","D","F"})
do_test(R:del("S0","S1","S2","S3"),4)
print(" OK")

-- server

printf("server ")
do_test(R:echo("foo"),"foo")
do_test(R:ping(),"PONG")
print(" OK")

-- 'keys' command
printf("keys ")
local _ks = {
  "",
  "foo",
  "afoo",
  "bar",
  "some-key",
  "foo:1",
  "foo:1:bar",
  "foo:2:bar",
  "this%is-really:tw][sted",
}
local _cases = {
  "",{""},
  "notakey",{},
  "*",_ks,
  "???",{"foo","bar"},
  "foo:*:*",{"foo:1:bar","foo:2:bar"},
  "*f[a-z]o",{"foo","afoo"},
  "*s%is-rea[j-m]??:*",{"this%is-really:tw][sted"},
}
local _ks2 = {}
for i=1,#_ks do
  _ks2[#_ks2+1] = _ks[i]
  _ks2[#_ks2+1] = "x"
end
do_test(R:mset(unpack(_ks2)),true)
for i=1,#_cases/2 do
  do_test_set(R:keys(_cases[2*i-1]),_cases[2*i])
end
print(" OK")
