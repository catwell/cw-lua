local iris = require "iris"

local c = iris.new()
assert(c:handshake("bcst"))

c.handlers.broadcast = function(msg)
    print("message arrived: " .. msg)
end

for i=1,5 do c:process_one() end

c:teardown()
