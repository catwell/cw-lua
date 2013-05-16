local client = require "zerorpc.client"
local S = client.new("tcp://127.0.0.1:4242")

local scall = function(...)
  local r = {S:call(...)}
  assert(r[1])
  return select(2,unpack(r))
end

print(scall("hello","RPC"))
S:close()
