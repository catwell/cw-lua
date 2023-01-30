local iris = require "iris"

local c = iris.new()
assert(c:handshake("echo"))

c.handlers.request = function(req)
    print("request arrived: " .. req)
    return req
end

for i=1,5 do c:process_one() end

c:teardown()
