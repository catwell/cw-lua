local mp = require "luajit-msgpack-pure"
local pretty = require "pl.pretty"

local decode = function(data)
  local offset,r
  if data then
    offset,r = mp.unpack(data)
    assert(offset == #data)
    return r
  else return nil end
end

return {
  server = "localhost",
  port = 11300,
  tube = os.getenv("MY_TUBE") or "default",
  decode = decode,
  encode = function(x) return mp.pack(x) end,
  as_string = function(x) return pretty.write(x,"") end,
  valid = function(x) return (type(x) == "table") end,
}
