local fakeredis = require "fakeredis"
local cwtest = require "cwtest"

local R = fakeredis.new()
local T = cwtest.new()

T.rk_nil = function(self,k)
  local r
  if (
    (R:get(k) == nil) and
    (R:type(k) == "none") and
    (R:exists(k) == false)
  ) then
    r = self.pass_tpl(self," (value for %s is nil)",k)
  else
    r = self.fail_tpl(self," (value for %s is not nil)",k)
  end
  return r
end

T.rk_nil_hash = function(self,k,k2)
  local r
  if (
    (R:hget(k,k2) == nil) and
    (R:hexists(k,k2) == false)
  ) then
    r = self.pass_tpl(self," (value for %s[%s] is nil)",k,k2)
  else
    r = self.fail_tpl(self," (value for %s[%s] is not nil)",k,k2)
  end
  return r
end

--- strings (and some key commands)

T:start("strings")
T:eq(R:flushdb(),true)
T:eq(R:randomkey(),nil)
T:rk_nil("foo")
T:eq(R:strlen("foo"),0)
T:eq(R:set("foo","bar"),true)
T:eq(R:exists("foo"),true)
T:eq(R:get("foo"),"bar")
T:eq(R:type("foo"),"string")
T:eq(R:strlen("foo"),3)
T:eq(R:randomkey(),"foo")
T:eq(R:del("foo"),1)
T:rk_nil("foo")
T:eq(R:hset("foo","spam","eggs"),true)
T:eq(R:type("foo"),"hash")
T:eq(R:set("foo","bar"),true)
T:eq(R:get("foo"),"bar")
T:eq(R:type("foo"),"string")
T:eq(R:renamenx("foo","chunky"),true)
T:eq(R:set("spam","eggs"),true)
T:eq(R:renamenx("chunky","spam"),false)
T:eq(R:get("spam"),"eggs")
T:eq(R:rename("chunky","spam"),true)
T:rk_nil("chunky")
T:eq(R:get("spam"),"bar")
T:eq(R:renamenx("spam","foo"),true)
T:rk_nil("spam")
T:eq(R:get("foo"),"bar")
T:eq(R:append("foo",""),3)
T:eq(R:append("foo","bar"),6)
T:eq(R:get("foo"),"barbar")
T:eq(R:append("spam","eggs"),4)
T:eq(R:get("spam"),"eggs")
T:eq(R:mget("foo","chunky","spam"),{"barbar",nil,"eggs"})
T:eq(R:mset("chunky","bacon","foo","bar"),true)
T:eq(R:mget("foo","chunky","spam"),{"bar","bacon","eggs"})
T:eq(R:setnx("chunky","bacon"),false)
T:eq(R:del("chunky"),1)
T:eq(R:setnx("chunky","bacon"),true)
T:eq(R:get("chunky"),"bacon")
T:eq(R:del("chunky"),1)
T:eq(R:del("spam"),1)
T:eq(R:msetnx("chunky","bacon","foo","bar"),false)
T:eq(R:mget("foo","chunky","spam"),{"bar",nil,nil})
T:eq(R:del("foo"),1)
T:eq(R:msetnx("chunky","bacon","foo","bar"),true)
T:eq(R:mget("foo","chunky","spam"),{"bar","bacon",nil})
T:eq(R:getset("foo","foobar"),"bar")
T:eq(R:getset("spam","eggs"),nil)
T:eq(R:set("foo","This is a string"),true)
T:eq(R:getrange("foo",100,150),"")
T:eq(R:getrange("foo",0,3),"This")
T:eq(R:getrange("foo",-3,-1),"ing")
T:eq(R:getrange("foo",0,-1),"This is a string")
T:eq(R:getrange("foo",9,100000)," string")
T:eq(R:set("foo","Hello World!"),true)
T:eq(R:setrange("foo",6,"Redis"),12)
T:eq(R:get("foo"),"Hello Redis!")
T:eq(R:del("foo"),1)
T:eq(R:setrange("foo",10,"bar"),13)
T:eq(R:get("foo"),"\0\0\0\0\0\0\0\0\0\0bar")
T:eq(R:set("foo","bar"),true)
T:eq(R:setrange("foo",1,"A"),3)
T:eq(R:get("foo"),"bAr")
T:eq(R:del("foo","chunky","spam"),3)
T:rk_nil("foo"); T:rk_nil("spam"); T:rk_nil("chunky")
T:done()

--- hashes

T:start("hashes")
T:rk_nil("foo")
T:eq(R:hlen("foo"),0)
T:eq(R:hget("foo","bar"),nil)
T:eq(R:hgetall("foo"),{})
T:seq(R:hkeys("foo"),{})
T:seq(R:hvals("foo"),{})
T:rk_nil_hash("foo","bar")
T:eq(R:hset("foo","spam","eggs"),true)
T:eq(R:exists("foo"),true)
T:eq(R:hexists("foo","spam"),true)
T:eq(R:type("foo"),"hash")
T:eq(R:hget("foo","bar"),nil)
T:eq(R:hset("foo","bar","baz"),true)
T:eq(R:hget("foo","bar"),"baz")
T:eq(R:hlen("foo"),2)
T:seq(R:hkeys("foo"),{"spam","bar"})
T:seq(R:hvals("foo"),{"eggs","baz"})
T:eq(R:hgetall("foo"),{spam="eggs",bar="baz"})
T:eq(R:hmget("foo",{"spam","trap","bar"}),{"eggs",nil,"baz"})
T:eq(R:hmset("foo",{bar="biz",chunky="bacon"}),true)
T:eq(R:hgetall("foo"),{spam="eggs",bar="biz",chunky="bacon"})
T:eq(R:hdel("foo","bar"),1)
T:rk_nil_hash("foo","bar")
T:eq(R:hdel("foo","bar"),0)
T:eq(R:hget("foo","spam"),"eggs")
T:eq(R:hsetnx("foo","spam","spam"),false)
T:eq(R:hsetnx("foo","bar","baz"),true)
T:eq(R:hgetall("foo"),{spam="eggs",bar="baz",chunky="bacon"})
T:eq(R:hset("foo","spam","eggs"),false)
T:eq(R:hdel("foo","spam","bar"),2)
T:eq(R:hdel("foo","bar"),0)
T:eq(R:hdel("foo","chunky"),1)
T:eq(R:del("foo"),0)
T:rk_nil_hash("foo","bar")
T:rk_nil("foo")
T:done()

--- lists

T:start("lists")
T:rk_nil("foo")
T:eq(R:llen("foo"),0)
T:eq(R:lrange("foo",0,-1),{})
T:eq(R:lindex("foo",0),nil)
T:eq(R:lindex("foo",-1),nil)
T:eq(R:lpop("foo"),nil)
T:eq(R:rpop("foo"),nil)
T:eq(R:lpush("foo","A"),1)
T:eq(R:llen("foo"),1)
T:eq(R:lrange("foo",0,-1),{"A"})
T:eq(R:lindex("foo",0),"A")
T:eq(R:lindex("foo",-1),"A")
T:eq(R:lindex("foo",1),nil)
T:eq(R:lindex("foo",-2),nil)
T:eq(R:lpop("foo"),"A")
T:rk_nil("foo")
T:eq(R:lpush("foo","A"),1)
T:eq(R:rpop("foo"),"A")
T:rk_nil("foo")
T:eq(R:rpush("foo","A"),1)
T:eq(R:llen("foo"),1)
T:eq(R:lrange("foo",0,-1),{"A"})
T:eq(R:lindex("foo",0),"A")
T:eq(R:lindex("foo",-1),"A")
T:eq(R:lindex("foo",1),nil)
T:eq(R:lindex("foo",-2),nil)
T:eq(R:rpop("foo"),"A")
T:rk_nil("foo")
T:eq(R:rpush("foo","A"),1)
T:eq(R:lpop("foo"),"A")
T:rk_nil("foo")
T:eq(R:lpush("foo","A"),1)
T:eq(R:lpush("foo","B"),2)
T:eq(R:lpush("foo","C"),3)
T:eq(R:llen("foo"),3)
T:eq(R:lrange("foo",0,-1),{"C","B","A"})
T:eq(R:lrange("foo",0,0),{"C"})
T:eq(R:lrange("foo",0,1),{"C","B"})
T:eq(R:lrange("foo",0,2),{"C","B","A"})
T:eq(R:lrange("foo",1,2),{"B","A"})
T:eq(R:lrange("foo",2,2),{"A"})
T:eq(R:lrange("foo",2,0),{})
T:eq(R:lpop("foo"),"C")
T:eq(R:llen("foo"),2)
T:eq(R:rpop("foo"),"A")
T:eq(R:llen("foo"),1)
T:eq(R:rpush("foo","X"),2)
T:eq(R:lpop("foo"),"B")
T:eq(R:lpop("foo"),"X")
T:eq(R:llen("foo"),0)
T:eq(R:lpop("foo"),nil)
T:rk_nil("foo")
T:eq(R:rpush("foo","A"),1)
T:eq(R:rpush("foo","B"),2)
T:eq(R:rpush("foo","C"),3)
T:eq(R:llen("foo"),3)
T:eq(R:lrange("foo",0,-1),{"A","B","C"})
T:eq(R:lrange("foo",0,0),{"A"})
T:eq(R:lrange("foo",0,1),{"A","B"})
T:eq(R:lrange("foo",0,2),{"A","B","C"})
T:eq(R:lrange("foo",0,3),{"A","B","C"})
T:eq(R:lrange("foo",1,2),{"B","C"})
T:eq(R:lrange("foo",2,2),{"C"})
T:eq(R:lrange("foo",2,0),{})
T:eq(R:lrange("foo",-1,-2),{})
T:eq(R:lrange("foo",-1,-1),{"C"})
T:eq(R:lrange("foo",-2,-1),{"B","C"})
T:eq(R:lrange("foo",-3,-1),{"A","B","C"})
T:eq(R:lrange("foo",-4,-1),{"A","B","C"})
T:eq(R:lindex("foo",0),"A")
T:eq(R:lindex("foo",-3),"A")
T:eq(R:lindex("foo",1),"B")
T:eq(R:lindex("foo",-2),"B")
T:eq(R:lindex("foo",2),"C")
T:eq(R:lindex("foo",-1),"C")
T:eq(R:lindex("foo",3),nil)
T:eq(R:lindex("foo",-4),nil)
T:eq(R:rpop("foo"),"C")
T:eq(R:llen("foo"),2)
T:eq(R:lpop("foo"),"A")
T:eq(R:llen("foo"),1)
T:eq(R:lpush("foo","X"),2)
T:eq(R:rpop("foo"),"B")
T:eq(R:rpop("foo"),"X")
T:eq(R:llen("foo"),0)
T:eq(R:rpop("foo"),nil)
T:rk_nil("foo")
T:done()

--- sets

T:start("sets")
T:rk_nil("foo")
T:eq(R:scard("foo"),0)
T:eq(R:sismember("foo","A"),false)
T:seq(R:smembers("foo"),{})
T:eq(R:srandmember("foo"),nil)
T:eq(R:spop("foo"),nil)
T:eq(R:sadd("foo","A"),1)
T:eq(R:exists("foo"),true)
T:eq(R:type("foo"),"set")
T:eq(R:scard("foo"),1)
T:eq(R:srandmember("foo"),"A")
T:eq(R:spop("foo"),"A")
T:eq(R:spop("foo"),nil)
T:rk_nil("foo")
T:eq(R:sadd("foo","A"),1)
T:eq(R:sadd("foo","B"),1)
T:eq(R:scard("foo"),2)
T:eq(R:sadd("foo","A","C","D"),2)
T:eq(R:scard("foo"),4)
T:seq(R:smembers("foo"),{"A","B","C","D"})
T:eq(R:sismember("foo","B"),true)
T:eq(R:srem("foo","B"),1)
T:eq(R:srem("foo","B"),0)
T:eq(R:srem("foo","B","C","D","E"),2)
T:eq(R:scard("foo"),1)
T:seq(R:smembers("foo"),{"A"})
T:eq(R:sismember("foo","B"),false)
T:eq(R:del("foo"),1)
T:eq(R:sadd("foo","A","B"),2)
T:eq(R:srem("foo","A","B"),2)
T:eq(R:del("foo"),0)
T:eq(R:sismember("foo","A"),false)
T:seq(R:smembers("foo"),{})
T:rk_nil("foo")
T:eq(R:sadd("S1","A","B","C","D","E"),5)
T:eq(R:sadd("S2","A","B","F"),3)
T:eq(R:sadd("S3","A","C","D"),3)
T:seq(R:sdiff("S1","S2","S3"),{"E"})
T:seq(R:sinter("S1","S2","S3"),{"A"})
T:seq(R:sunion("S1","S2","S3"),{"A","B","C","D","E","F"})
T:eq(R:sdiffstore("S0","S1","S2","S3"),1)
T:seq(R:smembers("S0"),{"E"})
T:eq(R:sinterstore("S0","S1","S2","S3"),1)
T:seq(R:smembers("S0"),{"A"})
T:eq(R:sunionstore("S0","S1","S2","S3"),6)
T:seq(R:smembers("S0"),{"A","B","C","D","E","F"})
local _cur = {A = true,B = true,C = true,D = true,E = true,F = true}
local _x
for i=1,6 do
  _x = R:srandmember("S0")
  T:eq(_cur[_x],true)
  _x = R:spop("S0")
  T:eq(_cur[_x],true)
  _cur[_x] = false
  T:eq(R:scard("S0"),6-i)
end
T:eq(R:smove("S2","S3","F"),true)
T:eq(R:smove("S2","S3","F"),false)
T:seq(R:smembers("S2"),{"A","B"})
T:seq(R:smembers("S3"),{"A","C","D","F"})
T:eq(R:del("S0","S1","S2","S3"),3)
T:done()

--- server

T:start("server")
T:eq(R:echo("foo"),"foo")
T:eq(R:ping(),"PONG")
T:done()

--- remaining key commands

T:start("keys")
-- 'keys' command
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
T:eq(R:mset(unpack(_ks2)),true)
for i=1,#_cases/2 do
  T:seq(R:keys(_cases[2*i-1]),_cases[2*i])
end
-- 'randomkey' command
local _ks_set = {}
for i=1,#_ks do _ks_set[_ks[i]] = true end
local _cur,_prev
local _founddiff,_notakey = false,false
for i=1,100 do
  _cur = R:randomkey()
  if not _ks_set[_cur] then _notakey = true end
  if _cur ~= _prev then _founddiff = true end
  _prev = _cur
end
T:eq(_notakey,false)
T:eq(_founddiff,true)
T:done()
