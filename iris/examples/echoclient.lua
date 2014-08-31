local iris = require "iris"

local c = iris.new(55555)
assert(c:handshake(""))

local r = assert(c:request("echo", "hello", 1000))

c:teardown()

print("reply arrived: " .. r)
