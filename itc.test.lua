local unpack = table.unpack
local base2base = require "base2base"
local cwtest = require "cwtest"

local T = cwtest.new()

local int_samples = {
    {{0}, "00"}, {{1}, "20"}, {{2}, "40"}, {{3}, "60"},
    {{4}, "80"}, {{5}, "88"}, {{6}, "90"}, {{7}, "98"},
    {{8}, "a0"}, {{9}, "a8"}, {{10}, "b0"}, {{11}, "b8"},
    {{12}, "c0"}, {{13}, "c2"}, {{14}, "c4"}, {{15}, "c6"},
    {{16}, "c8"}, {{17}, "ca"}, {{18}, "cc"}, {{19}, "ce"},
    {{20}, "d0"}, {{21}, "d2"}, {{22}, "d4"}, {{23}, "d6"},
    {{24}, "d8"}, {{25}, "da"}, {{26}, "dc"}, {{27}, "de"},
    {{28}, "e000"}, {{29}, "e080"}, {{30}, "e100"}, {{31}, "e180"},
    {{32}, "e200"}, {{33}, "e280"}, {{34}, "e300"}, {{35}, "e380"},
    {{36}, "e400"}, {{37}, "e480"}, {{38}, "e500"}, {{39}, "e580"},
    {{40}, "e600"}, {{41}, "e680"}, {{42}, "e700"}, {{43}, "e780"},
    {{44}, "e800"}, {{45}, "e880"}, {{46}, "e900"}, {{47}, "e980"},
    {{48}, "ea00"}, {{49}, "ea80"}, {{50}, "eb00"}, {{51}, "eb80"},
    {{0, 1}, "04"},
    {{1000}, "fef600"},
}

T:start("bin.writer", #int_samples); do
    local bin_writer = require "itc.bin.writer"
    local _ints = function(...)
        local arg = {...}
        local w = bin_writer.new()
        for i = 1, #arg do w:write_int(arg[i]) end
        return base2base.to_hex(w:data())
    end
    for _, s in ipairs(int_samples) do
        T:eq( _ints(unpack(s[1])), s[2] )
    end
end; T:done()

T:start("bin.reader", #int_samples + 1); do
    local bin_reader = require "itc.bin.reader"
    for _, s in ipairs(int_samples) do
        local r = bin_reader.new(base2base.from_hex(s[2]))
        for _, n in ipairs(s[1]) do
            T:eq( r:read_int(), n )
        end
    end
end; T:done()

local itc_samples = {
    { 1, 0 },
    { {1, 0}, 0 },
    { {0, 1}, 0 },
    { {1, 1}, 0 },
    { 1, {0, 0, 2} },
    { 1, {0, 2, 0} },
    { 1, {0, 2, 2} },
    { 1, {2, 0, 2} },
    { 1, {2, 2, 0} },
    { 1, {2, 2, 2} },
    { {{0, {1, 0}}, {1, 0}}, {1, 2, {0, {1, 0, 2}, 0}} },
}

local function i2b(s)
    if s == 1 then
        return true
    elseif s == 0 then
        return false
    else
        return {i2b(s[1]), i2b(s[2])}
    end
end

for _, s in ipairs(itc_samples) do s[1] = i2b(s[1]) end

T:start("bin", 2 * #itc_samples); do
    local bin = require "itc.bin"
    local stamp = require "itc.stamp"
    for _, s in ipairs(itc_samples) do
        local e = bin.encode(unpack(s))
        T:eq( {bin.decode(e)}, s )
        T:eq( stamp.decode(e):encode(), e )
    end
end; T:done()

T:start("id", 2); do
    local itc_id = require "itc.id"
    local x = itc_id.new({ data = i2b({{0, {1, 0}}, {{{1, 1}, 1}, 0}}) })
    T:eq( x:repr() , "((0, (1, 0)), (((1, 1), 1), 0))" )
    x:normalize()
    T:eq( x:repr() , "((0, (1, 0)), (1, 0))" )
end; T:done()

T:start("event", 14); do
    local event = require "itc.event"
    local x = event.new({ data = {1, 2, {0, {1, 0, 2}, 0}} })
    x:normalize()
    T:eq( x:repr() , "(1, 2, (0, (1, 0, 2), 0))" )
    x = event.new({ data = {2, 1, 1} })
    x:normalize()
    T:eq( x:repr() , "3" )
    x = event.new({ data = {2, {2, 1, 0}, 3} })
    x:normalize()
    T:eq( x:repr() , "(4, (0, 1, 0), 1)" )
    local y = event.new({ data = 5 })
    x = event.new({ data = 3 })
    T:yes( y:dominates(x) )
    T:no( x:dominates(y) )
    T:yes( y:dominates(y) )
    x = event.new({ data = {4, {0, 1, 0}, 1} })
    T:yes( y:dominates(x) )
    T:no( x:dominates(y) )
    x = event.new({ data = {4, {0, 2, 0}, 1} })
    T:no( y:dominates(x) )
    T:no( x:dominates(y) )
    y = event.new({ data = {3, {0, 3, 0}, 2} })
    T:no( y:dominates(x) )
    T:yes( x:dominates(y) )
    y = event.new({ data = {3, 2, {0, 3, 0}} })
    T:no( y:dominates(x) )
    T:no( x:dominates(y) )
end; T:done()

T:start("example-5.1", 15); do
    local stamp = require "itc.stamp"
    local s1 = stamp.new()
    T:eq( s1:repr(), "[1, 0]" )
    local s2 = s1:fork()
    T:eq( s1:repr(), "[(1, 0), 0]" )
    T:eq( s2:repr(), "[(0, 1), 0]" )
    s1:event()
    s2:event()
    s2:event()
    T:eq( s1:repr(), "[(1, 0), (0, 1, 0)]" )
    T:eq( s2:repr(), "[(0, 1), (0, 0, 2)]" )
    local s3 = s1:fork()
    T:eq( s1:repr(), "[((1, 0), 0), (0, 1, 0)]" )
    T:eq( s3:repr(), "[((0, 1), 0), (0, 1, 0)]" )
    s1:event()
    T:eq( s1:repr(), "[((1, 0), 0), (0, (1, 1, 0), 0)]" )
    s2:join(s3)
    T:yes( s3.dead )
    T:eq( s2:repr(), "[((0, 1), 1), (1, 0, 1)]" )
    s3 = s2:fork()
    T:eq( s2:repr(), "[((0, 1), 0), (1, 0, 1)]" )
    T:eq( s3:repr(), "[(0, 1), (1, 0, 1)]" )
    s1:join(s2)
    T:yes( s2.dead )
    T:eq( s1:repr(), "[(1, 0), (1, (0, 1, 0), 1)]" )
    s1:event()
    T:eq( s1:repr(), "[(1, 0), 2]" )
end; T:done()

T:start("example-5.3.4", 3); do
    local itc = require "itc"
    local i = i2b { {1, 0}, {{0, 1}, 0} }
    local e = {1, 1, {0, {2, 0, 1}, 0}}
    local s = itc.stamp.new {
        id = itc.id.new {data = i},
        ev = itc.event.new {data = e},
    }
    T:eq( s:repr(), "[((1, 0), ((0, 1), 0)), (1, 1, (0, (2, 0, 1), 0))]" )
    s:event()
    T:eq( s:repr(), "[((1, 0), ((0, 1), 0)), (1, 1, (0, (2, 0, 2), 0))]" )
    T:eq( s:peek():repr(), "[0, (1, 1, (0, (2, 0, 2), 0))]" )
end; T:done()

T:exit()
