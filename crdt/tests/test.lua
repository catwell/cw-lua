package.path = package.path .. ";./src/?.lua"
require "pl.strict"

local GCounter = require "g_counter"
local PNCounter = require "pn_counter"
local GSet = require "g_set"
local TwoPSet = require "2p_set"
local ORSet = require "or_set"
local OptORSet = require "opt_or_set"

local printf = function(p,...)
  io.stdout:write(string.format(p,...)); io.stdout:flush()
end

local ctr_test = function(ctr,expected)
  local val = ctr:value()
  assert(
    val == expected,
    string.format("wrong value %g, expected %g",val,expected)
  )
end

local set_test = function(s,vals)
  local set = s:value()
  local card = set:card()
  assert(
    card == #vals,
    string.format("wrong cardinal %g, expected %g",card,#vals)
  )
  for i=1,card do
    assert(
      set:has(vals[i]),
      string.format("value not in set: %s",tostring(vals[i]))
    )
  end
end

--- COUNTERS

local ca,cb

printf("G-Counter tests ")

printf(".")
ca = GCounter.new("a")
ca:incr(1)
ca:incr(1)
ctr_test(ca,2)

printf(".")
cb = GCounter.new("b")
cb:merge(ca)
ctr_test(cb,2)

printf(".")
cb:incr(3)
cb:merge(ca)
ctr_test(cb,5)
ctr_test(ca,2)
ca:merge(cb)
ctr_test(ca,5)

print(" OK")

printf("PN-Counter tests ")

printf(".")
ca = PNCounter.new("a")
ca:incr(1)
ca:incr(3)
ca:decr(2)
ctr_test(ca,2)

printf(".")
cb = PNCounter.new("b")
cb:merge(ca)
ctr_test(cb,2)

printf(".")
cb:incr(3)
cb:merge(ca)
ctr_test(cb,5)
ctr_test(ca,2)
ca:merge(cb)
ctr_test(ca,5)

printf(".")
ca:decr(8)
cb:merge(ca)
ctr_test(cb,-3)

print(" OK")

--- SETS

local sa,sb

printf("G-Set tests ")

printf(".")
sa = GSet.new()
sa:add(6)
sa:add(9)
set_test(sa,{6,9})

printf(".")
sb = GSet.new()
sb:add(6)
sb:add(2)
sb:add(4)
set_test(sb,{2,4,6})

printf(".")
sb:merge(sa)
set_test(sb,{2,4,6,9})

printf(".")
sa:add(1)
sb:merge(sa)
set_test(sa,{1,6,9})
sa:add(3)
sa:merge(sb)
set_test(sa,{1,2,3,4,6,9})

print(" OK")

printf("2P-Set tests ")

printf(".")

sa = TwoPSet.new()
sb = TwoPSet.new()
sa:add("a")
sa:add("b")
sa:del("a")
sb:add("c")
sb:merge(sa)
sa:merge(sb)
set_test(sa,{"b","c"})
set_test(sb,{"b","c"})

print(" OK")

printf("OR-Set tests ")

printf(".")

sa = ORSet.new("a")
sb = ORSet.new("b")
sc = ORSet.new("c")

sb:add("a")
sa:add("a")
sc:merge(sb)
sc:merge(sa)
sa:del("a")
sa:merge(sb)
sc:merge(sa)

set_test(sa,{"a"})
set_test(sc,{"a"})

print(" OK")

printf("Optimized OR-Set tests ")

printf(".")

sa = OptORSet.new("a")
sb = OptORSet.new("b")
sc = OptORSet.new("c")

sb:add("a")
sa:add("a")
sc:merge(sb)
sc:merge(sa)
sa:del("a")
sa:merge(sb)
sc:merge(sa)

set_test(sa,{"a"})
set_test(sc,{"a"})

print(" OK")
