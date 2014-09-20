local iris = require "iris"

local c = iris.new()
assert(c:handshake("tunnel"))

local MAX_COUNT = 3
local count = 0

c.handlers.tunnel = function(tun)
    tun:allow(1024)
    tun.handlers.message = function(msg)
        if msg == "request" then
            if count < MAX_COUNT then
                count = count + 1
                print(string.format(
                    "got request, sending %dx data then continue", count
                ))
                for i=1,count do tun:cosend("data") end
                tun:cosend("continue")
            else
                print("got request, sending bye")
                tun:cosend("bye")
            end
        else
            print("got invalid message: " .. msg)
            tun:close()
        end
    end
end

local op
while op ~= iris.OP.TUN_CLOSE do op = c:process_one() end

c:teardown()
