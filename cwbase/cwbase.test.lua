local cwtest = require "cwtest"
local cwbase = require "cwbase"
local fmt = string.format

local ok, bc, mapm, bi
ok, bc = pcall(require, "bc")
if not (ok and type(bc) == "table") then
    print("warning: bc not found, skipping")
    bc = nil
end
ok, mapm = pcall(require, "mapm")
if not (ok and type(mapm) == "table") then
    print("warning: mapm not found, skipping")
    mapm = nil
end
ok, tbi = pcall(require, "tedbigint")
if not (ok and type(tbi) == "table") then
    print("warning: tedbigint not found, skipping")
    tbi = nil
end

local T = cwtest.new()

local t_basic = function(B)
    local b36 = cwbase.base36(B)
    T:yes( B.__eq(b36:to_bignum("hello"), 29234652) )
    T:eq( b36:from_bignum(54903217), "world" )
end

local t_long = function(B)
    local b36 = cwbase.base36(B)
    local as_b36 = "thisisaverylongnumberinbase36"
    local as_bn = B.number("1111978840201019009355547421069962117833522258")
    T:yes( B.__eq(b36:to_bignum(as_b36), as_bn) )
    T:eq( b36:from_bignum(as_bn), as_b36 )
end

local tests = {
    {"basic", t_basic},
    {"long", t_long},
}

local do_tests = function(name, B)
    if not B then
        print(fmt("warning: %s not found, skipping", name))
        return
    end
    for i=1,#tests do
        T:start(name .. " - " .. tests[i][1])
        tests[i][2](B)
        T:done()
    end
end

do_tests("bc", bc)
do_tests("mapm", mapm)
do_tests("tedbigint", tbi)

T:start("hex"); do
    local t_raw, t_hex = {}, {}
    for i=0,255 do
        t_raw[i+1] = string.char(i)
        t_hex[i+1] = string.format("%02x", i)
    end
    local s_raw, s_hex = table.concat(t_raw), table.concat(t_hex)
    T:eq(#s_raw, 256)
    T:eq(#s_hex, 512)
    T:eq(cwbase.to_hex(s_raw), s_hex)
    T:eq(cwbase.from_hex(s_hex), s_raw)
end; T:done()

T:exit()
