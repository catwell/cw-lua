local fakeredis = require "fakeredis"
local R = fakeredis.new()

local printf = function(p,...)
  io.stdout:write(string.format(p,...)); io.stdout:flush()
end

local do_test_silent = function(v1,v2)
  if v1 ~= v2 then
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

local do_test_table = function(t1,t2)
  printf(".")
  do_test_silent(#t1,#t2)
  table.sort(t1); table.sort(t2)
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
do_test_table(R:hgetall("foo"),{})
do_test_table(R:hkeys("foo"),{})
do_test_table(R:hvals("foo"),{})
do_test_nil_hash("foo","bar")
do_test(R:hset("foo","spam","eggs"),true)
do_test(R:exists("foo"),true)
do_test(R:hexists("foo","spam"),true)
do_test(R:type("foo"),"hash")
do_test(R:hget("foo","bar"),nil)
do_test(R:hset("foo","bar","baz"),true)
do_test(R:hget("foo","bar"),"baz")
do_test(R:hlen("foo"),2)
do_test_table(R:hkeys("foo"),{"spam","bar"})
do_test_table(R:hvals("foo"),{"eggs","baz"})
do_test_table(R:hgetall("foo"),{spam="eggs",bar="baz"})
do_test(R:hdel("foo","bar"),1)
do_test_nil_hash("foo","bar")
do_test(R:del("foo"),0)
do_test_nil_hash("foo","bar")
do_test_nil("foo")
print(" OK")

-- server

printf("server ")
do_test(R:echo("foo"),"foo")
do_test(R:ping(),"PONG")
print(" OK")
