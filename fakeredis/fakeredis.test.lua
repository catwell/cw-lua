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

do_test_listset = function(t1,t2)
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
do_test(R:del("foo"),1)
do_test_nil("foo")
print(" OK")

-- hashes

printf("hashes ")
do_test_nil("foo")
do_test(R:hlen("foo"),0)
do_test(R:hget("foo","bar"),nil)
do_test_hash(R:hgetall("foo"),{})
do_test_listset(R:hkeys("foo"),{})
do_test_listset(R:hvals("foo"),{})
do_test_nil_hash("foo","bar")
do_test(R:hset("foo","spam","eggs"),true)
do_test(R:exists("foo"),true)
do_test(R:hexists("foo","spam"),true)
do_test(R:type("foo"),"hash")
do_test(R:hget("foo","bar"),nil)
do_test(R:hset("foo","bar","baz"),true)
do_test(R:hget("foo","bar"),"baz")
do_test(R:hlen("foo"),2)
do_test_listset(R:hkeys("foo"),{"spam","bar"})
do_test_listset(R:hvals("foo"),{"eggs","baz"})
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

-- server

printf("server ")
do_test(R:echo("foo"),"foo")
do_test(R:ping(),"PONG")
print(" OK")
