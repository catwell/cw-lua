local iris = require "iris"

local c = iris.new()
assert(c:handshake(""))

local req = c:request("echo", "hello", 1000)
c:process_one()
local r = assert(req:response())

c:teardown()

print("reply arrived: " .. r)
