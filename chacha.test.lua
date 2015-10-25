local cwtest = require "cwtest"
local chacha = require "chacha"

local T = cwtest.new()

local S = { -- https://tools.ietf.org/html/rfc7539#section-2.4.1
    plaintext = table.concat {
        "Ladies and Gentlemen of the class of '99: If I could ",
        "offer you only one tip for the future, sunscreen would be it."
    }
}
do
    local t = {}
    for i=0x00, 0x1f do t[#t+1] = i end
    S.key = string.char(table.unpack(t))
    S.ref_iv = string.char(0, 0, 0, 0x4a, 0, 0x02, 0, 0)
    S.ietf_iv = string.char(0, 0, 0, 0, 0, 0, 0, 0x4a, 0, 0, 0, 0)
end

local ietf_241_expected = [[
6e 2e 35 9a 25 68 f9 80 41 ba 07 28 dd 0d 69 81
e9 7e 7a ec 1d 43 60 c2 0a 27 af cc fd 9f ae 0b
f9 1b 65 c5 52 47 33 ab 8f 59 3d ab cd 62 b3 57
16 39 d6 24 e6 51 52 ab 8f 53 0c 35 9f 08 61 d8
07 ca 0d bf 50 0d 6a 61 56 a3 8e 08 8a 22 b6 5e
52 bc 51 4d 16 cc f8 06 81 8c e9 1a b7 79 37 36
5a f9 0b bf 74 a3 5b e6 b4 0b 8e ed f2 78 5e 42
87 4d
]]
do
    local s, t = ietf_241_expected, {}
    for x in s:gmatch("[%S]+") do t[#t+1] = tonumber(x, 16) end
    ietf_241_expected = string.char(table.unpack(t))
end

T:start("basics"); do
    local rounds = {8, 12, 20}
    for i=1, #rounds do
        local _crypt = function(plaintext)
            return chacha.ref_crypt(rounds[i], S.key, S.ref_iv, plaintext)
        end
        T:eq(_crypt(_crypt(S.plaintext)), S.plaintext)
    end
end; T:done()

T:start("ChaCha20 RFC7539 2.4.2"); do
    local c_1 = string.pack("I4", 1)
    local ciphertext = chacha.ietf_crypt(20, S.key, S.ietf_iv, S.plaintext, c_1)
    T:eq(ciphertext, ietf_241_expected)
    T:eq(
        chacha.ietf_crypt(20, S.key, S.ietf_iv, ciphertext, c_1), S.plaintext
    )
end; T:done()

T:start("counter"); do
    local c_0, c_1 = string.pack("I8", 0), string.pack("I8", 1)
    local ciphertext_1 = chacha.ref_crypt(20, S.key, S.ref_iv, S.plaintext)
    local ciphertext_2 = chacha.ref_crypt(20, S.key, S.ref_iv, S.plaintext, c_0)
    T:eq(ciphertext_2, ciphertext_1)
    local ciphertext_3 = chacha.ref_crypt(20, S.key, S.ref_iv, S.plaintext, c_1)
    T:neq(ciphertext_3, ciphertext_1)
    local b_1 = S.plaintext:sub(64 + 1)
    local ciphertext_4 = chacha.ref_crypt(20, S.key, S.ref_iv, b_1, c_1)
    T:eq(ciphertext_4, ciphertext_1:sub(64 + 1))
end; T:done()

T:exit()

