local iris = require "iris"

local c = iris.new()
assert(c:handshake(""))

c:broadcast("bcst", "hello")
c:teardown()
