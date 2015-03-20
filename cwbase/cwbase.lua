--- Base-to-base converter by Pierre 'catwell' Chapuis
--- MIT licensed (see LICENSE.txt)

local letters = "abcdefghijklmnopqrstuvwxyz"
local figures = "0123456789"
local ascii = {}; for i=1,256 do ascii[i] = i-1 end

local ALPHABET_B62 = figures .. letters .. letters:upper()
local ALPHABET_B64 = letters:upper() .. letters .. figures .. "+/"
local ALPHABET_B64URL = ALPHABET_B64:sub(1,62) .. "-_"
local ALPHABET_B256 = string.char(table.unpack(ascii))

local _iszero = function(B)
    if B.iszero then return B.iszero end
    assert(B.__eq)
    return function(x)
        return B.__eq(x, 0)
    end
end

local to_bignum = function(self, source)
    assert(type(source) == "string")
    local B = self.bignum
    local s = B.number(0)
    local m = B.number(1)
    local b = B.number(self.base)
    local n
    for i=#source,1,-1 do
        n = self.value[source:byte(i)]
        s = B.add(s, B.mul(n, m))
        m = B.mul(m, b)
    end
    return s
end

local from_bignum = function(self, n)
    local B = self.bignum
    if type(n) == "number" then n = B.number(n) end
    local iszero = _iszero(B)
    local div = assert(B.idiv or B.div)
    local b = self.base
    local r = {}
    while not iszero(n) do
        r[#r+1] = self.alphabet:byte(B.tonumber(B.mod(n, b)) + 1)
        n = div(n, b)
    end
    return string.char(table.unpack(r)):reverse()
end

local methods = {
    to_bignum = to_bignum,
    from_bignum = from_bignum,
}

local converter = function(alphabet, bignum)
    local r = {
        bignum = bignum or (require "bc"),
        alphabet = alphabet,
        base = #alphabet,
        value = {},
    }
    for i=1,r.base do r.value[r.alphabet:byte(i)] = i-1 end
    return setmetatable(r, {__index = methods})
end

local _converter = function(alphabet)
    return function(bignum)
        return converter(alphabet, bignum)
    end
end

return {
    converter = converter,
    base62 = _converter(ALPHABET_B62),
    base36 = _converter(ALPHABET_B62:sub(1,36)),
    base10 = _converter(ALPHABET_B62:sub(1,10)),
    base16 = _converter(ALPHABET_B62:sub(1,16)),
    base64 = _converter(ALPHABET_B64),
    base64url = _converter(ALPHABET_B64URL),
    base256 = _converter(ALPHABET_B256),
}
