local bin_encoder = require "itc.bin.encoder"
local bin_decoder = require "itc.bin.decoder"

local function encode(i, e)
    local encoder = bin_encoder.new()
    encoder:add_i(i)
    encoder:add_e(e)
    return encoder:data()
end

local function decode(s)
    local decoder = bin_decoder.new {data = s}
    return decoder:get_i(), decoder:get_e()
end

return {
    encode = encode,
    decode = decode,
}
