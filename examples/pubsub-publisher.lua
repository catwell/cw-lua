local iris = require "iris"
local socket = require "socket"

local c = iris.new()
assert(c:handshake(""))

for i=1,5 do
    c:publish("somechan", "message " .. i)
    socket.sleep(1)
end

c:teardown()
