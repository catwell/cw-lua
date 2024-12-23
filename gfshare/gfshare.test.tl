local base2base = require "base2base"
local gfshare = require "gfshare"

local sample_data = "It works!"

-- test gfshare.combine compatibility with gfsplit

local all_sample_shares = {
    [19] = base2base.from_hex("ec3753146ebf1c373f"),
    [75] = base2base.from_hex("6e308c979329295440"),
    [112] = base2base.from_hex("bbc6f9d1b2c867659d"),
    [113] = base2base.from_hex("c4bebe4d68ee9d7cb1"),
    [248] = base2base.from_hex("b37dcbc974553aff5c"),
}

local sample_shares = {
    [19] = all_sample_shares[19],
    [112] = all_sample_shares[112],
    [248] = all_sample_shares[248],
}

assert(gfshare.combine(sample_shares) == sample_data)

-- test gfshare.split

local all_my_shares = gfshare.split(sample_data, 5, 3)

local p = 0
local my_shares_2, my_shares_3 = {}, {}
for n, buf in pairs(all_my_shares) do
    my_shares_3[n] = buf
    if p < 2 then
        my_shares_2[n] = buf
    end
    if p == 2 then break end
    p = p + 1
end

assert(gfshare.combine(all_my_shares) == sample_data)
assert(gfshare.combine(my_shares_3) == sample_data)
assert(gfshare.combine(my_shares_2) ~= sample_data)
