local cwtest = require "cwtest"
local iris = require "iris"
local socket = require "socket"

local T = cwtest.new()

local echo = function(req) return req end

T:start("request/reply"); do
    local client = iris.new()
    local server = iris.new()

    server.handlers.request = echo

    T:yes( client:handshake("") )
    T:yes( server:handshake("echo") )

    local req = client:request("echo", "hello", 1000)

    T:yes( server:process_one() )

    T:eq( req:receive_reply(), "hello" )

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

T:start("publish/subscribe"); do
    local client = iris.new()
    local server1 = iris.new()
    local server2 = iris.new()

    server1.handlers.pubsub.topic1 = echo
    server1.handlers.pubsub.topic2 = echo
    server2.handlers.pubsub.topic1 = echo
    server2.handlers.pubsub.topic2 = echo

    T:yes( client:handshake("") )
    T:yes( server1:handshake("anything") )
    T:yes( server2:handshake("whatever") )

    server1:subscribe("topic1")
    server2:subscribe("topic1")

    socket.sleep(1)

    client:publish("topic1", "hello")

    T:eq( server1:process_one(), "hello" )
    T:eq( server2:process_one(), "hello" )

    server2:unsubscribe("topic1")
    server2:subscribe("topic2")

    socket.sleep(1)

    client:publish("topic1", "1")
    client:publish("topic2", "2")

    T:eq( server1:process_one(), "1" )
    T:eq( server2:process_one(), "2" )

    server1:teardown()
    server2:teardown()
    client:teardown()
end; T:done()

T:start("tunnel"); do
    local client = iris.new()
    local server = iris.new()

    T:yes( client:handshake("") )
    T:yes( server:handshake("tunnel") )

    local tun = client:tunnel("tunnel", 1000)

    T:yes( server:process_one() )

    T:yes( tun:confirm() )

    T:yes( server:process_one() )

    T:yes( tun:close() )

    T:yes( server:process_one() )

    server:teardown()
    client:teardown()
end; T:done()
