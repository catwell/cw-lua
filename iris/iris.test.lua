local cwtest = require "cwtest"
local iris = require "iris"

local T = cwtest.new()

T:start("request/reply"); do
    local client = iris.new(55555)
    local server = iris.new(55555)

    server.handlers.request = function(req) return req end

    T:yes( client:handshake("") )
    T:yes( server:handshake("echo") )

    local id = client:send_request("echo", "hello", 1000)

    T:yes( server:process_one() )

    T:eq( client:receive_reply(id), "hello" )

    server:teardown()
    client:teardown()
end; T:done()
