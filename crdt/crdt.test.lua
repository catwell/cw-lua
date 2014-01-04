local cwtest = require "cwtest"
package.path = package.path .. ";./crdt/?.lua"
local GCounter = require "g_counter"
local PNCounter = require "pn_counter"
local GSet = require "g_set"
local TwoPSet = require "2p_set"
local ORSet = require "or_set"
local OptORSet = require "opt_or_set"
local OptORSetRW = require "opt_or_set_rw"

local T = cwtest.new()

T.seq2 = function(self, s, y)
  local x = s:value():as_list()
  local ok = cwtest.compare_no_order(x, y)
  local r = (ok and self.pass_eq or self.fail_eq)(self, x, y)
  return r
end

--- COUNTERS

T:start("G-Counter"); do

  local ca = GCounter.new("a")
  ca:incr(1)
  ca:incr(1)
  T:eq(ca:value(), 2)

  local cb = GCounter.new("b")
  cb:merge(ca)
  T:eq(cb:value(), 2)

  cb:incr(3)
  cb:merge(ca)
  T:eq(cb:value(), 5)
  T:eq(ca:value(), 2)
  ca:merge(cb)
  T:eq(ca:value(), 5)

end; T:done()

T:start("PN-Counter"); do

  local ca = PNCounter.new("a")
  ca:incr(1)
  ca:incr(3)
  ca:decr(2)
  T:eq(ca:value(), 2)

  local cb = PNCounter.new("b")
  cb:merge(ca)
  T:eq(cb:value(), 2)

  cb:incr(3)
  cb:merge(ca)
  T:eq(cb:value(), 5)
  T:eq(ca:value(), 2)
  ca:merge(cb)
  T:eq(ca:value(), 5)

  ca:decr(8)
  cb:merge(ca)
  T:eq(cb:value(), -3)

end; T:done()

--- SETS

T:start("G-Set"); do

  local sa = GSet.new()
  sa:add(6,9)
  T:seq2(sa, {6,9})

  local sb = GSet.new()
  sb:add(6,2,4)
  T:seq2(sb, {2,4,6})

  sb:merge(sa)
  T:seq2(sb, {2,4,6,9})

  sa:add(1)
  sb:merge(sa)
  T:seq2(sa, {1,6,9})
  sa:add(3)
  sa:merge(sb)
  T:seq2(sa, {1,2,3,4,6,9})

end; T:done()

T:start("2P-Set"); do

  local sa = TwoPSet.new()
  local sb = TwoPSet.new()
  sa:add("a","b")
  sa:del("a")
  sb:add("c")
  sb:merge(sa)
  sa:merge(sb)
  T:seq2(sa, {"b","c"})
  T:seq2(sb, {"b","c"})

end; T:done()

local test_or_set_aw = function(name, class)
  T:start(name); do

    local sa, sb, sc

    sa = class.new("a")
    sb = class.new("b")

    sa:add("a")
    sb:merge(sa)
    T:seq2(sb, {"a"})
    sb:del("a")
    T:seq2(sb, {})
    sa:merge(sb)
    T:seq2(sa, {})

    sa = class.new("a")
    sb = class.new("b")
    sc = class.new("c")

    sb:add("a")
    sa:add("a")
    sc:merge(sb)
    sc:merge(sa)
    sa:del("a")
    sa:merge(sb)
    sc:merge(sa)

    T:seq2(sa, {"a"})
    T:seq2(sc, {"a"})
    T:yes(sc:has("a"))
    T:no(sc:has("b"))

  end; T:done()
end

test_or_set_aw("OR-Set", ORSet)
test_or_set_aw("Optimized OR-Set - Add Wins", OptORSet)

T:start("Optimized OR-Set - Remove Wins"); do

    local sa, sb, sc

    sa = OptORSetRW.new("a")
    sb = OptORSetRW.new("b")

    sa:add("a")
    sb:merge(sa)
    T:seq2(sb, {"a"})
    sb:del("a")
    T:seq2(sb, {})
    sa:merge(sb)
    T:seq2(sa, {})

    sa = OptORSetRW.new("a")
    sb = OptORSetRW.new("b")

    sa:del("a")
    sb:add("a")
    sb:merge(sa)
    T:seq2(sb, {})

    sa = OptORSetRW.new("a", true) -- strict
    T:err(function() sa:del("a") end)

    sa = OptORSetRW.new("a")
    sb = OptORSetRW.new("b")

    sa:add(1,2,3)
    sb:merge(sa)
    sa:del(1,4,5)
    sb:del(2,4)
    sb:add(4,6)
    T:seq2(sb, {1,3,4,6})
    sb:merge(sa)
    T:seq2(sa, {2,3})
    T:seq2(sb, {3,6})
    sa:merge(sb)
    T:seq2(sa, {3,6})

    sa = OptORSetRW.new("a", true)
    sb = OptORSetRW.new("b", true)

    sa:add(7)
    sb:merge(sa)
    T:seq2(sb, {7})
    sa:del(7)
    sb:merge(sa)
    T:seq2(sb, {})
    sa:add(7)
    sb:merge(sa)
    T:seq2(sb, {7})
    sb:del(7)
    sb:merge(sa)
    T:seq2(sb, {})

    sa = OptORSetRW.new("a")
    sb = OptORSetRW.new("b")
    sc = OptORSetRW.new("c")

    sb:add("a")
    sa:add("a")
    sc:merge(sb)
    sc:merge(sa)
    T:yes(sc:has("a"))
    T:no(sc:has("b"))
    sa:del("a")
    sa:merge(sb)
    sc:merge(sa)

    T:seq2(sa, {})
    T:seq2(sc, {})

end; T:done()
