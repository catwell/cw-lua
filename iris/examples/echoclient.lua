local iris = require "iris"

local c = iris.new()
assert(c:handshake(""))

local r = assert(c:request("echo", "hello", 1000):receive_reply())

c:teardown()

print("reply arrived: " .. r)
