local cwtest = require "cwtest"
local iris = require "iris"
local socket = require "socket"

local OP = iris.OP
local T = cwtest.new()

local echo = function(req) return req end

T:start("request/reply"); do
    local client = iris.new()
    local server = iris.new()

    server.handlers.request = echo

    T:yes( client:handshake("") )
    T:yes( server:handshake("echo") )

    local req = client:request("echo", "hello", 1000)

    T:eq( {server:process_one()}, {OP.REQUEST, true} )

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

    T:eq( {server1:process_one()}, {OP.BROADCAST, "hello"} )
    T:eq( {server2:process_one()}, {OP.BROADCAST, "hello"} )

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

    T:eq( {server1:process_one()}, {OP.PUBLISH, "hello"} )
    T:eq( {server2:process_one()}, {OP.PUBLISH, "hello"} )

    server2:unsubscribe("topic1")
    server2:subscribe("topic2")

    socket.sleep(1)

    client:publish("topic1", "1")
    client:publish("topic2", "2")

    T:eq( {server1:process_one()}, {OP.PUBLISH, "1"} )
    T:eq( {server2:process_one()}, {OP.PUBLISH, "2"} )

    server1:teardown()
    server2:teardown()
    client:teardown()
end; T:done()

T:start("tunnel"); do
    local client = iris.new()
    local server = iris.new()

    local responses = {
        "response 1", "response 2", "response 3"
    }

    local M = {}
    server.handlers.tunnel = function(tun)
        tun:allow(1024)
        tun.handlers.message = function(msg)
            M.msg = msg
            for i=1,#responses do
                local xfer = tun:transfer(responses[i])
                while not xfer:run() do coroutine.yield() end
            end
        end
    end

    T:yes( client:handshake("") )
    T:yes( server:handshake("tunnel") )

    local tun = client:tunnel("tunnel", 1000)

    T:eq( {server:process_one()}, {OP.TUN_INIT, true} )

    T:yes( tun:confirm() )
    tun:allow(1024)

    T:eq( {server:process_one()}, {OP.TUN_ALLOW, true} )

    local xfer = tun:transfer("data")
    T:yes( xfer:run() )
    T:yes( tun:process_allow() )

    T:eq( {server:process_one()}, {OP.TUN_TRANSFER, true} )
    T:eq( M.msg, "data" )

    for i=1,#responses do
        T:eq( tun:process_transfer(), responses[i] )
        T:eq( {server:process_one()}, {OP.TUN_ALLOW, true} )
    end

    T:eq( {server:process_one(0)}, {nil, "timeout"} )

    T:yes( tun:close() )
    T:eq( {server:process_one()}, {OP.TUN_CLOSE, true} )

    server:teardown()
    client:teardown()
end; T:done()
