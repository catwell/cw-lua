local socket = require "socket"

-- NOTE: draft 2 actually says v1-draft2,
-- but the server expects v1.0-draft2
local PROTO_VERSION = "v1.0-draft2"
local CLIENT_MAGIC = "iris-client-magic"
local RELAY_MAGIC = "iris-relay-magic"

local operations = {
    "INIT", "DENY", "CLOSE", "BROADCAST", "REQUEST",
    "REPLY", "SUBSCRIBE", "UNSUBSCRIBE", "PUBLISH",
    "TUN_INIT", "TUN_CONFIRM", "TUN_ALLOW", "TUN_TRANSFER", "TUN_CLOSE"
}

local OP = {}
for i=1,#operations do OP[operations[i]] = i-1 end

local op_name = function(opcode)
    return operations[opcode+1]
end

local fmt = function(p, ...)
    if select("#", ...) == 0 then
        return p
    else
        return string.format(p, ...)
    end
end

local bail = function(...)
    return error(fmt(...))
end

local printf = function(...)
    print(fmt(...))
end

local unexpected_opcode = function(x)
    local s = op_name(x)
    if s then
        bail("unexpected operation %s", s)
    else
        bail("unexpected byte %d (expected opcode)", x)
    end
end

local is_posint = function(x)
  return ( (type(x) == "number") and (math.floor(x) == x) and (x >= 0) )
end

local t_byte = function(x)
    return string.char(x)
end

local t_bool = function(x)
    if x then
        return t_byte(1)
    else
        return t_byte(0)
    end
end

local t_varint = function(x)
    assert(is_posint(x))
    local t = {}
    local r
    while x > 127 do
        r = x % 128
        t[#t+1] = r + 128
        x = (x - r) / 128
    end
    t[#t+1] = x
    return string.char(table.unpack(t))
end

local t_binary = function(x)
    return t_varint(#x) .. x
end

local t_string = t_binary

local connect = function(self, port)
  self.cnx = socket.tcp()
  self.cnx:connect("localhost", port)
  return true
end

local send = function(self, t)
    self.cnx:send(table.concat(t))
end

local receive_byte = function(self)
    local x = assert(self.cnx:receive(1))
    return x:byte()
end

local receive_bool = function(self)
    local b = self:receive_byte()
    if b == 1 then
        return true
    elseif b == 0 then
        return false
    else
        bail("unexpected byte: %d (expected boolean)", b)
    end
end

local receive_varint = function(self)
    local r, m = 0, 1
    while true do
        local b = self:receive_byte()
        if b < 128 then
            return b * m + r
        else
            r = r + (b - 128) * m
            m = m * 128
        end
    end
end

local receive_binary = function(self)
    local sz = self:receive_varint()
    if sz == 0 then
        return ""
    else
        return assert(self.cnx:receive(sz))
    end
end

local receive_string = receive_binary

local handshake = function(self, cluster)
    self:send{
        t_byte(OP.INIT),
        t_string(CLIENT_MAGIC),
        t_string(PROTO_VERSION),
        t_string(cluster),
    }
    local b = self:receive_byte()
    if b == OP.INIT then
        local magic = self:receive_string()
        assert(magic == RELAY_MAGIC)
        local version = self:receive_string()
        return true, version
    elseif b == OP.DENY then
        local magic = self:receive_string()
        assert(magic == RELAY_MAGIC)
        local reason = self:receive_string()
        return nil, reason
    else
        unexpected_opcode(b)
    end
end

local teardown = function(self)
    self:send{t_byte(OP.CLOSE)}
    local b = self:receive_byte()
    if b == OP.CLOSE then
        local reason = self:receive_string()
        assert(reason == "")
    else
        -- TODO keep processing
        unexpected_opcode(b)
    end
end

local new_req_id = function(self)
    self.req_ctr = self.req_ctr + 1
    return self.req_ctr
end

--- request ---

local req_send = function(self, cluster, body, timeout_ms)
    self.client:send{
        t_byte(OP.REQUEST),
        t_varint(self.id),
        t_string(cluster),
        t_binary(body),
        t_varint(timeout_ms),
    }
end

local req_receive_reply = function(self)
    local b = self.client:receive_byte()
    if b ~= OP.REPLY then
        -- TODO keep processing
        unexpected_opcode(b)
    end
    local id = self.client:receive_varint()
    if id ~= self.id then
        bail("unexpected request ID %d", id)
    end
    local timeout = self.client:receive_bool()
    if timeout then
        return nil, "timeout"
    else
        local success = self.client:receive_bool()
        if success then
            return self.client:receive_binary()
        else
            return nil, self.client:receive_string()
        end
    end
end

local req_methods = {
    send = req_send,
    receive_reply = req_receive_reply,
}

local new_request = function(client)
    local self = setmetatable({}, {__index = req_methods})
    self.client = client
    self.id = client:new_req_id()
    return self
end

local new_request_send = function(client, cluster, body, timeout_ms)
    local req = new_request(client)
    req:send(cluster, body, timeout_ms)
    return req
end

local broadcast = function(self, cluster, body)
    self:send{
        t_byte(OP.BROADCAST),
        t_string(cluster),
        t_binary(body),
    }
    return true
end

local publish = function(self, topic, body)
    self:send{
        t_byte(OP.PUBLISH),
        t_string(topic),
        t_binary(body),
    }
end

local subscribe = function(self, topic, handler)
    self:send{
        t_byte(OP.SUBSCRIBE),
        t_string(topic),
    }
end

local unsubscribe = function(self, topic)
    self:send{
        t_byte(OP.UNSUBSCRIBE),
        t_string(topic),
    }
end

local process_request = function(self)
    local id = self:receive_varint()
    local body = self:receive_binary()
    local timeout_ms = self:receive_varint()
    -- TODO discard expired requests
    if not self.handlers.request then
        bail("got request but no handler set")
    end
    local reply, err = self.handlers.request(body)
    self:send{
        t_byte(OP.REPLY),
        t_varint(id),
        t_bool(reply),
        reply and t_binary(reply) or t_string(err or "(error)"),
    }
    return true
end

local process_broadcast = function(self)
    local body = self:receive_binary()
    if not self.handlers.broadcast then
        bail("got broadcast but no handler set")
    end
    return self.handlers.broadcast(body)
end

local process_publish = function(self)
    local topic = self:receive_string()
    local body = self:receive_binary()
    if self.handlers.pubsub[topic] then
        return self.handlers.pubsub[topic](body)
    else
        return nil, fmt("no handler for topic %s)", topic)
    end
end

local ll_handlers = {
    [OP.REQUEST] = process_request,
    [OP.BROADCAST] = process_broadcast,
    [OP.PUBLISH] = process_publish,
}

local process_one = function(self)
    local b = self:receive_byte()
    if ll_handlers[b] then
        return ll_handlers[b](self)
    else
        unexpected_opcode(b)
    end
end

local methods = {
    connect = connect,
    send = send,
    receive_byte = receive_byte,
    receive_bool = receive_bool,
    receive_varint = receive_varint,
    receive_binary = receive_binary,
    receive_string = receive_string,
    handshake = handshake,
    teardown = teardown,
    new_req_id = new_req_id,
    request = new_request_send,
    broadcast = broadcast,
    publish = publish,
    subscribe = subscribe,
    unsubscribe = unsubscribe,
    process_one = process_one,
}

local new = function(port)
    port = port or 55555
    local self = setmetatable({}, {__index = methods})
    self:connect(port)
    self.req_ctr = 0
    self.handlers = {pubsub = {}}
    return self
end

return {
    new = new,
    OP = OP,
}
