local base2base = require "base2base"
local blake2b = require "blake2b"

local hash = blake2b.digest(64, "abc")

-- RFC 7693 Appendix A
assert(
    base2base.to_hex(blake2b.digest(64, "abc")) ==
        "ba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d1" ..
        "7d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923"
)
