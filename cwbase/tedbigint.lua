-- This is a bigint library by Ted Unangst, modified by Pierre Chapuis.
-- Original license follows.

--
-- Copyright (c) 2010 Ted Unangst <ted.unangst@gmail.com>
--
-- Permission to use, copy, modify, and distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
-- ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
-- ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
-- OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
--

--
-- Lua version ported/copied from the C version, copyright as follows.
--
-- Copyright (c) 2000 by Jef Poskanzer <jef@mail.acme.com>.
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
-- OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
-- LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
-- OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
-- SUCH DAMAGE.
--

--
-- Usage is pretty obvious.  bigint(n) constructs a bigint.  n can be
-- a number or a string.  The regular operators are all overridden via
-- metatable, and also generally work with regular numbers too.
-- Note that comparisons between bigints and numbers *don't* work.
-- bigint() uses a small cache, so bigint(constant) should be fast.
--
-- Only the basic operations are here.  No gcd, factorial, prime test, ...
--
-- Technical notes:
-- Primary difference from the C version is the obvious 1 indexing, this
-- shows up in a variety of ways and places, along with slightly different
-- handling of pre-allocated comps arrays.
-- I made a brief effort to sync some of the comments, but you're better
-- off just reading the C code.
-- C version homepage: http://www.acme.com/software/bigint/
--

local bigint

-- two functions to help make Lua act more like C
local function fl(x)
    if x < 0 then
        return math.ceil(x) + 0 -- make -0 go away
    else
        return math.floor(x)
    end
end

local function cmod(a, b)
    local x = a % b
    if a < 0 and x > 0 then
        x = x - b
    end
    return x
end


local radix = 2^24 -- maybe up to 2^26 is safe?
local radix_sqrt = fl(math.sqrt(radix))

local bigintmt -- forward decl

local function alloc()
    local bi = {}
    setmetatable(bi, bigintmt)
    bi.comps = {}
    bi.sign = 1;
    return bi
end

local function clone(a)
    local bi = alloc()
    bi.sign = a.sign
    local c = bi.comps
    local ac = a.comps
    for i = 1, #ac do
        c[i] = ac[i]
    end
    return bi
end

local function normalize(bi, notrunc)
    local c = bi.comps
    local v
    -- borrow for negative components
    for i = 1, #c - 1 do
        v = c[i]
        if v < 0 then
            c[i+1] = c[i+1] + fl(v / radix) - 1
            v = cmod(v, radix)
            if v ~= 0 then
                c[i] = v + radix
            else
                c[i] = v
                c[i+1] = c[i+1] + 1
            end
        end
    end
    -- is top component negative?
    if c[#c] < 0 then
        -- switch the sign and fix components
        bi.sign = -bi.sign
        for i = 1, #c - 1 do
            v = c[i]
            c[i] = radix - v
            c[i+1] = c[i+1] + 1
        end
        c[#c] = -c[#c]
    end
    -- carry for components larger than radix
    for i = 1, #c do
        v = c[i]
        if v > radix then
            c[i+1] = (c[i+1] or 0) + fl(v / radix)
            c[i] = cmod(v, radix)
        end
    end
    -- trim off leading zeros
    if not notrunc then
        for i = #c, 2, -1 do
            if c[i] == 0 then
                c[i] = nil
            else
                break
            end
        end
    end
    -- check for -0
    if #c == 1 and c[1] == 0 and bi.sign == -1 then
        bi.sign = 1
    end
end

local function negate(a)
    local bi = clone(a)
    bi.sign = -bi.sign
    return bi
end

local function compare(a, b)
    local ac, bc = a.comps, b.comps
    local as, bs = a.sign, b.sign
    if ac == bc then
        return 0
    elseif as > bs then
        return 1
    elseif as < bs then
        return -1
    elseif #ac > #bc then
        return as
    elseif #ac < #bc then
        return -as
    end
    for i = #ac, 1, -1 do
        if ac[i] > bc[i] then
            return as
        elseif ac[i] < bc[i] then
            return -as
        end
    end
    return 0
end

local function lt(a, b)
    return compare(a, b) < 0
end

local function eq(a, b)
    return compare(a, b) == 0
end

local function le(a, b)
    return compare(a, b) <= 0
end

local function addint(a, n)
    local bi = clone(a)
    if bi.sign == 1 then
        bi.comps[1] = bi.comps[1] + n
    else
        bi.comps[1] = bi.comps[1] - n
    end
    normalize(bi)
    return bi
end

local function add(a, b)
    if type(a) == "number" then
        return addint(b, a)
    elseif type(b) == "number" then
        return addint(a, b)
    end
    local bi = clone(a)
    local sign = bi.sign == b.sign
    local c = bi.comps
    for i = #c + 1, #b.comps do
        c[i] = 0
    end
    local bc = b.comps
    for i = 1, #bc do
        local v = bc[i]
        if sign then
            c[i] = c[i] + v
        else
            c[i] = c[i] - v
        end
    end
    normalize(bi)
    return bi
end

local function sub(a, b)
    if type(b) == "number" then
        return addint(a, -b)
    elseif type(a) == "number" then
        a = bigint(a)
    end
    return add(a, negate(b))
end

local function mulint(a, b)
    local bi = clone(a)
    if b < 0 then
        b = -b
        bi.sign = -bi.sign
    end
    local bc = bi.comps
    for i = 1, #bc do
        bc[i] = bc[i] * b
    end
    normalize(bi)
    return bi
end

local function multiply(a, b)
    local bi = alloc()
    local c = bi.comps
    local ac, bc = a.comps, b.comps
    for i = 1, #ac + #bc do
        c[i] = 0
    end
    for i = 1, #ac do
        for j = 1, #bc do
            c[i+j-1] = c[i+j-1] + ac[i] * bc[j]
        end
        -- keep the zeroes
        normalize(bi, true)
    end
    normalize(bi)
    if bi ~= bigint(0) then
        bi.sign = a.sign * b.sign
    end
    return bi
end

local function kmul(a, b)
    local ac, bc = a.comps, b.comps
    local an, bn = #a.comps, #b.comps
    local bi, bj, bk, bl = alloc(), alloc(), alloc(), alloc()
    local ic, jc, kc, lc = bi.comps, bj.comps, bk.comps, bl.comps

    local n = fl((math.max(an, bn) + 1) / 2)
    for i = 1, n do
        ic[i] = (i + n <= an) and ac[i+n] or 0
        jc[i] = (i <= an) and ac[i] or 0
        kc[i] = (i + n <= bn) and bc[i+n] or 0
        lc[i] = (i <= bn) and bc[i] or 0
    end
    normalize(bi)
    normalize(bj)
    normalize(bk)
    normalize(bl)
    local ik = bi * bk
    local jl = bj * bl
    local mid = (bi + bj) * (bk + bl) - ik - jl
    local mc = mid.comps
    local ikc = ik.comps
    local jlc = jl.comps
    for i = 1, #ikc + n*2 do -- fill it up
        jlc[i] = jlc[i] or 0
    end
    for i = 1, #mc do
        jlc[i+n] = jlc[i+n] + mc[i]
    end
    for i = 1, #ikc do
        jlc[i+n*2] = jlc[i+n*2] + ikc[i]
    end
    jl.sign = a.sign * b.sign
    normalize(jl)
    return jl
end

local kthresh = 12

local function mul(a, b)
    if type(a) == "number" then
        return mulint(b, a)
    elseif type(b) == "number" then
        return mulint(a, b)
    end
    if #a.comps < kthresh or #b.comps < kthresh then
        return multiply(a, b)
    end
    return kmul(a, b)
end

local function divint(numer, denom)
    local bi = clone(numer)
    if denom < 0 then
        denom = -denom
        bi.sign = -bi.sign
    end
    local r = 0
    local c = bi.comps
    for i = #c, 1, -1 do
        r = r * radix + c[i]
        c[i] = fl(r / denom)
        r = cmod(r, denom)
    end
    normalize(bi)
    return bi
end

local function multi_divide(numer, denom)
    local n = #denom.comps
    local approx = divint(numer, denom.comps[n])
    for i = n, #approx.comps do
        approx.comps[i - n + 1] = approx.comps[i]
    end
    for i = #approx.comps, #approx.comps - n + 2, -1 do
        approx.comps[i] = nil
    end
    local rem = approx * denom - numer
    if rem < denom then
        quotient = approx
    else
        quotient = approx - multi_divide(rem, denom)
    end
    return quotient
end

local function multi_divide_wrap(numer, denom)
    -- we use a successive approximation method, but it doesn't work
    -- if the high order component is too small.  adjust if needed.
    if denom.comps[#denom.comps] < radix_sqrt then
        numer = mulint(numer, radix_sqrt)
        denom = mulint(denom, radix_sqrt)
    end
    return multi_divide(numer, denom)
end

local function div(numer, denom)
    if type(denom) == "number" then
        if denom == 0 then
            error("divide by 0", 2)
        end
        return divint(numer, denom)
    elseif type(numer) == "number" then
        numer = bigint(numer)
    end
    -- check signs and trivial cases
    local sign = 1
    local cmp = compare(denom, bigint(0))
    if cmp == 0 then
        error("divide by 0", 2)
    elseif cmp == -1 then
        sign = -sign
        denom = negate(denom)
    end
    cmp = compare(numer, bigint(0))
    if cmp == 0 then
        return bigint(0)
    elseif cmp == -1 then
        sign = -sign
        numer = negate(numer)
    end
    cmp = compare(numer, denom)
    if cmp == -1 then
        return bigint(0)
    elseif cmp == 0 then
        return bigint(sign)
    end
    local bi
    -- if small enough, do it the easy way
    if #denom.comps == 1 then
        bi = divint(numer, denom.comps[1])
    else
        bi = multi_divide_wrap(numer, denom)
    end
    if sign == -1 then
        bi = negate(bi)
    end
    return bi
end

local function intrem(bi, m)
    if m < 0 then
        m = -m
    end
    local rad_r = 1
    local r = 0
    local bc = bi.comps
    for i = 1, #bc do
        local v = bc[i]
        r = cmod(r + v * rad_r, m)
        rad_r = cmod(rad_r * radix, m)
    end
    if bi.sign < 1 then
        r = -r
    end
    return r
end

local function intmod(bi, m)
    local r = intrem(bi, m)
    if r < 0 then
        r = r + m
    end
    return r
end

local function rem(bi, m)
    if type(m) == "number" then
        return bigint(intrem(bi, m))
    elseif type(bi) == "number" then
        bi = bigint(bi)
    end
    return bi - ((bi / m) * bi)
end

local function mod(a, m)
    local bi = rem(a, m)
    if bi.sign == -1 then
        bi = bi + m
    end
    return bi
end

local printscale = 10000000
local printscalefmt = string.format("%%.%dd", math.log10(printscale))
local function makestr(bi, s)
    if bi >= bigint(printscale) then
        makestr(divint(bi, printscale), s)
    end
    table.insert(s, string.format(printscalefmt, intmod(bi, printscale)))
end

local function biginttostring(bi)
    local s = {}
    if bi < bigint(0) then
        bi = negate(bi)
        table.insert(s, "-")
    end
    makestr(bi, s)
    s = table.concat(s):gsub("^0*", "")
    if s == "" then s = "0" end
    return s
end

bigintmt = {
    __add = add,
    __sub = sub,
    __mul = mul,
    __div = div,
    __mod = mod,
    __unm = negate,
    __eq = eq,
    __lt = lt,
    __le = le,
    __tostring = biginttostring
}

local cache = {}
local ncache = 0

bigint = function(n)
    if cache[n] then
        return cache[n]
    end
    local bi
    if type(n) == "string" then
        local digits = { n:byte(1, -1) }
        for i = 1, #digits do
            digits[i] = string.char(digits[i])
        end
        local start = 1
        local sign = 1
        if digits[1] == '-' then
            sign = -1
            start = 2
        end
        bi = bigint(0)
        for i = start, #digits do
            bi = addint(mulint(bi, 10), tonumber(digits[i]))
        end
        bi = mulint(bi, sign)
    else
        bi = alloc()
        bi.comps[1] = n
        normalize(bi)
    end
    if ncache > 100 then
        cache = {}
        ncache = 0
    end
    cache[n] = bi
    ncache = ncache + 1
    return bi
end

return {
    number = bigint,
    add = add,
    mul = mul,
    div = div,
    mod = mod,
    __eq = function(a, b)
        if type(a) == "number" then a = bigint(a) end
        if type(b) == "number" then b = bigint(b) end
        return a == b
    end,
    ["tonumber"] = function(n)
        return tonumber(biginttostring(n))
    end
}
