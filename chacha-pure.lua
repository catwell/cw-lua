local rotl32 = function(x, n)
    return ((x << n) & 0xffffffff) | (x >> (32 - n))
end

local quarterround = function(a, b, c, d)
    a = (a + b) & 0xffffffff; d = rotl32(d ~ a, 16)
    c = (c + d) & 0xffffffff; b = rotl32(b ~ c, 12)
    a = (a + b) & 0xffffffff; d = rotl32(d ~ a, 8)
    c = (c + d) & 0xffffffff; b = rotl32(b ~ c, 7)
    return a, b, c, d
end

local i_k = function(key)
    local lk = #key
    if lk == 32 then
        -- "expand 32-byte k"
        return 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574,
            string.unpack("<I4I4I4I4I4I4I4I4", key)
    else
        assert(lk == 16)
        local k1, k2, k3, k4 = string.unpack("<I4I4I4I4", key)
        -- "expand 16-byte k"
        return 0x61707865, 0x3120646e, 0x79622d36, 0x6b206574,
            k1, k2, k3, k4, k1, k2, k3, k4
    end
end

local _block = function(
    rounds, j0, j1, j2, j3, j4, j5, j6, j7, j8, j9, j10, j11, j12, j13, j14, j15
)
    local x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 =
        j0, j1, j2, j3, j4, j5, j6, j7, j8, j9, j10, j11, j12, j13, j14, j15
    for _ = 1, rounds // 2 do
        j0, j4, j8, j12 = quarterround(j0, j4, j8, j12)
        j1, j5, j9, j13 = quarterround(j1, j5, j9, j13)
        j2, j6, j10, j14 = quarterround(j2, j6, j10, j14)
        j3, j7, j11, j15 = quarterround(j3, j7, j11, j15)
        j0, j5, j10, j15 = quarterround(j0, j5, j10, j15)
        j1, j6, j11, j12 = quarterround(j1, j6, j11, j12)
        j2, j7, j8, j13 = quarterround(j2, j7, j8, j13)
        j3, j4, j9, j14 = quarterround(j3, j4, j9, j14)
    end
    x0, x1 = (x0 + j0) & 0xffffffff, (x1 + j1) & 0xffffffff
    x2, x3 = (x2 + j2) & 0xffffffff, (x3 + j3) & 0xffffffff
    x4, x5 = (x4 + j4) & 0xffffffff, (x5 + j5) & 0xffffffff
    x6, x7 = (x6 + j6) & 0xffffffff, (x7 + j7) & 0xffffffff
    x8, x9 = (x8 + j8) & 0xffffffff, (x9 + j9) & 0xffffffff
    x10, x11 = (x10 + j10) & 0xffffffff, (x11 + j11) & 0xffffffff
    x12, x13 = (x12 + j12) & 0xffffffff, (x13 + j13) & 0xffffffff
    x14, x15 = (x14 + j14) & 0xffffffff, (x15 + j15) & 0xffffffff
    return x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15
end

local _crypt = function(ietf, rounds, key, iv, plaintext, counter)
    local j0, j1, j2, j3, j4, j5, j6, j7, j8, j9, j10, j11 = i_k(key)
    local j12, j13, j14, j15
    if ietf then
        j12, j13, j14, j15 = 0, string.unpack("<I4I4I4", iv)
        if counter then
            assert(#counter == 4)
            j12 = string.unpack("<I4", counter)
        end
    else
        j12, j13, j14, j15 = 0, 0, string.unpack("<I4I4", iv)
        if counter then
            assert(#counter == 8)
            j12, j13 =  string.unpack("<I4I4", counter)
        end
    end
    local pl, r = #plaintext, {}
    local x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15
    local y0, y1, y2, y3, y4, y5, y6, y7, y8, y9, y10, y11, y12, y13, y14, y15
    if pl % 64 ~= 0 then
        plaintext = plaintext .. string.pack(
            "<I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4",
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        )
    end
    for i = 0, (pl - 1) // 64 do
        x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 =
            _block(rounds, j0, j1, j2, j3, j4, j5, j6, j7, j8,
                   j9, j10, j11, j12, j13, j14, j15)
        y0, y1, y2, y3, y4, y5, y6, y7, y8, y9, y10, y11, y12, y13, y14, y15 =
            string.unpack(
                "<I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4", plaintext, i * 64 + 1
            )
        r[i + 1] = string.pack(
            "<I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4",
            x0 ~ y0, x1 ~ y1, x2 ~ y2, x3 ~ y3,
            x4 ~ y4, x5 ~ y5, x6 ~ y6, x7 ~ y7,
            x8 ~ y8, x9 ~ y9, x10 ~ y10, x11 ~ y11,
            x12 ~ y12, x13 ~ y13, x14 ~ y14, x15 ~ y15
        )
        j12 = (j12 + 1) & 0xffffffff
        if not ietf and j12 == 0 then
            j13 = (j13 + 1) & 0xffffffff
        end
    end
    if pl % 64 ~= 0 then
        local i = pl // 64
        r[i + 1] = r[i + 1]:sub(1, pl % 64)
    end
    return table.concat(r)
end

local ref_crypt = function(rounds, key, iv, plaintext, counter)
    assert((rounds == 20 or rounds == 12 or rounds == 8) and #iv == 8)
    return _crypt(false, rounds, key, iv, plaintext, counter)
end

local ietf_crypt = function(rounds, key, iv, plaintext, counter)
    assert(rounds == 20 and #iv == 12)
    return _crypt(true, rounds, key, iv, plaintext, counter)
end

return {
    ref_crypt = ref_crypt,
    ietf_crypt = ietf_crypt,
}
