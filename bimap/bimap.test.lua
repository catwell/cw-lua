local cwtest = require "cwtest"
local bimap = require "bimap"

local len_works_on_tables -- 5.2 feature
do
  local t = setmetatable({}, {__len = function() return 42 end})
  len_works_on_tables = (#t == 42)
end

local T = cwtest.new()

local test_foo_bar_baz = function(l, r)
  T:eq( l["bar"], 2 )
  T:eq( r[2], "bar" )
  T:eq( r("len"), 3 )
  if len_works_on_tables then
    T:eq( #r, 3 )
  end
  T:eq( r("raw"), {"foo", "bar", "baz"} )
  T:eq( l("raw"), {foo = 1, bar = 2, baz = 3} )
  l.baz = nil
  r[r("len")] = nil
  T:eq( r("len"), 1 )
  T:eq( r("raw"), {"foo"} )
  T:eq( l("raw"), {foo = 1} )
  l.spam = "eggs"
  r.eggs = "chunky"
  l["chunky"] = "bacon"
  T:eq( l["chunky"], "bacon" )
  T:eq( r["bacon"], "chunky" )
  T:eq( l["spam"], nil )
  T:eq( r["eggs"], nil )
  T:eq( r("raw"), {"foo", bacon = "chunky"} )
  T:eq( l("raw"), {foo = 1, chunky = "bacon"} )
  local pretty = require "pl.pretty"
  T:err(function() l.evil = 1 end, {
    matching = "cannot assign value \"1\" to key \"evil\": " ..
               "already assigned to key \"foo\""
  })
end

T:start("bimap"); do
  local l, r = bimap.new()
  l.foo = 1
  l.bar = 2
  l.baz = 3
  test_foo_bar_baz(l, r)
  l, r = bimap.new{"foo", "bar", "baz"}
  test_foo_bar_baz(r, l)
end; T:done()
