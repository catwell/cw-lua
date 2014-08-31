local cwtest = require "cwtest"
local iris = require "iris"

local T = cwtest.new()

local echo = function(req) return req end

T:start("request/reply"); do
    local client = iris.new()
    local server = iris.new()

    server.handlers.request = echo

    T:yes( client:handshake("") )
    T:yes( server:handshake("echo") )

    local id = client:send_request("echo", "hello", 1000)

    T:yes( server:process_one() )

    T:eq( client:receive_reply(id), "hello" )

    server:teardown()
    client:teardown()
end; T:done()

T:start("broadcast"); do
    local client = iris.new()
    local server1 = iris.new()
    local server2 = iris.new()

    server1.handlers.broadcast = echo
    server2.handlers.broadcast = echo

    T:yes( client:handshake("") )
    T:yes( server1:handshake("bcst") )
    T:yes( server2:handshake("bcst") )

    T:yes( client:broadcast("bcst", "hello") )

    T:eq( server1:process_one(), "hello" )
    T:eq( server2:process_one(), "hello" )

    server1:teardown()
    server2:teardown()
    client:teardown()
end; T:done()
