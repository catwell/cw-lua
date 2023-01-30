local iris = require "iris"

local c = iris.new()
assert(c:handshake(""))

local tun = c:tunnel("tunnel", 1000)
tun:confirm()
tun:allow(1024)

tun.handlers.message = function(msg)
    if msg == "data" then
        print("got data")
    elseif msg == "continue" then
        print("got continue, sending request")
        tun:cosend("request")
    elseif msg == "bye" then
        print("got bye, quitting")
        tun:close()
    else
        print("got invalid message: " .. msg)
        tun:close()
    end
end

local xfer = tun:transfer("request")
while not xfer:run() do c:process_one() end

local op
while op ~= iris.OP.TUN_CLOSE do op = c:process_one() end

c:teardown()
