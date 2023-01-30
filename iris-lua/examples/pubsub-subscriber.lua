local iris = require "iris"
local socket = require "socket"

local c = iris.new()
assert(c:handshake(""))

c.handlers.pubsub.somechan = function(msg)
    print("message arrived: " .. msg)
end

c:subscribe("somechan")

for i=1,5 do c:process_one() end

c:teardown()
