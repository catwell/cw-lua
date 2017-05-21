local IV = { -- RFC 7693 2.6 & Appendix C
    0x6a09e667f3bcc908, 0xbb67ae8584caa73b,
    0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
    0x510e527fade682d1, 0x9b05688c2b3e6c1f,
    0x1f83d9abfb41bd6b, 0x5be0cd19137e2179,
};

local SIGMA = { -- RFC 7693 2.7
    {  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15 },
    { 14, 10,  4,  8,  9, 15, 13,  6,  1, 12,  0,  2, 11,  7,  5,  3 },
    { 11,  8, 12,  0,  5,  2, 15, 13, 10, 14,  3,  6,  7,  1,  9,  4 },
    {  7,  9,  3,  1, 13, 12, 11, 14,  2,  6,  5, 10,  4,  0, 15,  8 },
    {  9,  0,  5,  7,  2,  4, 10, 15, 14,  1, 11, 12,  6,  8,  3, 13 },
    {  2, 12,  6, 10,  0, 11,  8,  3,  4, 13,  7,  5, 15, 14,  1,  9 },
    { 12,  5,  1, 15, 14, 13,  4, 10,  0,  7,  6,  3,  9,  2,  8, 11 },
    { 13, 11,  7, 14, 12,  1,  3,  9,  5,  0, 15,  4,  8,  6,  2, 10 },
    {  6, 15, 14,  9, 11,  3,  0,  8, 12,  2, 13,  7,  1,  4, 10,  5 },
    { 10,  2,  8,  4,  7,  6,  1,  5, 15, 11,  9, 14,  3, 12, 13 , 0 },
}

for i = 1, 10 do for j = 1, 16 do
    SIGMA[i][j] = SIGMA[i][j] + 1 -- This is Lua.
end end

SIGMA[11] = SIGMA[1]
SIGMA[12] = SIGMA[2]

local function rotr(x, n) -- RFC 7693 2.3
    return (x >> n) ~ (x << (64 - n))
end

local function G(v, a, b, c, d, x, y) -- RFC 7693 3.1 & 2.1
    -- Note: we rely on integer overflow behavior here!
    v[a] = v[a] + v[b] + x
    v[d] = rotr(v[d] ~ v[a], 32)
    v[c] = v[c] + v[d]
    v[b] = rotr(v[b] ~ v[c], 24)
    v[a] = v[a] + v[b] + y
    v[d] = rotr(v[d] ~ v[a], 16)
    v[c] = v[c] + v[d]
    v[b] = rotr(v[b] ~ v[c], 63)
end

local function F(h, m, t, f) -- - RFC 7693 3.2
    -- h is the internal state
    -- m is a message block of 16 i8, possibly padded
    -- t is the offset counter
    -- f is a boolean indicating if this is the final block

    local v = {} -- 16-word local work vector
    for i = 1, 8 do v[i] = h[i] end
    for i = 1, 8 do v[i + 8] = IV[i] end

    v[13] = v[13] ~ t
    if f then v[15] = ~v[15] end -- last block

    for i = 1, 12 do -- 12 rounds in BLAKE2b
        local s = SIGMA[i]
        G( v, 1, 5,  9, 13, m[s[ 1]], m[s[ 2]] )
        G( v, 2, 6, 10, 14, m[s[ 3]], m[s[ 4]] )
        G( v, 3, 7, 11, 15, m[s[ 5]], m[s[ 6]] )
        G( v, 4, 8, 12, 16, m[s[ 7]], m[s[ 8]] )
        G( v, 1, 6, 11, 16, m[s[ 9]], m[s[10]] )
        G( v, 2, 7, 12, 13, m[s[11]], m[s[12]] )
        G( v, 3, 8,  9, 14, m[s[13]], m[s[14]] )
        G( v, 4, 5, 10, 15, m[s[15]], m[s[16]] )
    end

    for i = 1, 8 do h[i] = h[i] ~ v[i] ~ v[i + 8] end
end

local function block_for(buf)
    local m = { string.unpack("<i8i8i8i8i8i8i8i8i8i8i8i8i8i8i8i8", buf) }
    m[17] = nil
    return m
end

local function pad(buf)
    local l = #buf
    assert(l < 16 * 8)
    local r = {buf}
    for i = 2, 16 * 8 - l + 1 do r[i] = "\0" end
    return table.concat(r)
end

local function compress(S) -- RFC 7693 3.3
    if #S.buf > 16 * 8 then
        S.S.t = S.t + 16 * 8
        F(S.h, block_for(S.buf), S.t, false)
        S.buf = S.buf:sub(16 * 8)
        return compress(S)
    end
end

local function update(self, data) -- RFC 7693 3.3
    assert(not self.S.finalized)
    local datalen = #data
    if datalen == 0 then return end
    self.S.buf = self.S.buf .. data
    compress(self.S)
end

local function final(self) -- RFC 7693 3.3
    local S = self.S
    if not S.finalized then
        S.t = S.t + #S.buf
        F(S.h, block_for(pad(S.buf)), S.t, true)
        S.finalized = true
    end
    local d = string.pack("<i8i8i8i8i8i8i8i8", table.unpack(S.h))
    return d:sub(1, self.outlen)
end

local methods = {
    update = update,
    final = final,
}

local MT = { __index = methods }

local function initial_state(self)
    local S = {
        -- `t`: total bytes. We only support input up to 2^64 - 1 bytes,
        -- whereas RFC supports up to 2^128 - 1.
        t = 0,
        buf = "",
        finalized = false,
    }

    -- Initial state. See RFC 7693 2.5 & 3.3
    S.h = { IV[1] ~ 0x01010000 ~ (self.keylen << 8) ~ self.outlen }
    for i = 2, 8 do S.h[i] = IV[i] end
    return S
end

local function new(params)
    local self = {}

    assert(params.outlen > 0 and params.outlen <= 64)
    self.outlen = params.outlen

    if params.key then
        assert(type(params.key) == "string")
        self.keylen = #params.key
        assert(self.keylen > 0 and self.keylen <= 64)
        self.key = params.key
    else
        self.keylen = 0
    end

    self.S = initial_state(self)

    if self.key then
        self.S.buf = pad(self.key)
    end

    return setmetatable(self, MT)
end

local function digest(outlen, input, key)
    local h = new { outlen = outlen, key = key }
    h:update(input)
    return h:final()
end

return {
    new = new,
    digest = digest,
}
