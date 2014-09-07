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

local make_chunks = function(s, sz)
    local r = {}
    for i=1,#s,sz do
        r[#r+1] = s:sub(i,i+sz-1)
    end
    return r
end

local now_ms = function()
    return socket.gettime() * 1000
end

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

local new_tun_id = function(self)
    self.tun_ctr = self.tun_ctr + 1
    return self.tun_ctr
end

local ensure_receive = function(s, expected)
    -- s is a handler instance (tun or req)
    local b = s.client:receive_byte()
    if b ~= expected then
        unexpected_opcode(b)
    end
    local id = s.client:receive_varint()
    if id ~= s.id then
        bail("unexpected ID %d", id)
    end
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
    ensure_receive(self, OP.REPLY)
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

--- tunnel ---

local tun_close = function(self)
    self.client:send{
        t_byte(OP.TUN_CLOSE),
        t_varint(self.id),
     }
end

local tun_allow = function(self, n)
    self.client:send{
        t_byte(OP.TUN_ALLOW),
        t_varint(self.id),
        t_varint(n),
     }
end

local tun_send_transfer = function(self, size, body)
    self.client:send{
        t_byte(OP.TUN_TRANSFER),
        t_varint(self.id),
        t_varint(size),
        t_binary(body)
    }
end

local tun_drain = function(self, sz)
    if self.allowance >= sz then
        self.allowance = self.allowance - sz
        return true
    else
        return false
    end
end

local ctun_send_init = function(self, cluster, timeout_ms)
    self.client:send{
        t_byte(OP.TUN_INIT),
        t_varint(self.id),
        t_string(cluster),
        t_varint(timeout_ms),
    }
end

local ctun_process_allow = function(self)
    ensure_receive(self, OP.TUN_ALLOW)
    local allowance = self.client:receive_varint()
    self.allowance = self.allowance + allowance
    return true
end

local ctun_confirm = function(self)
    ensure_receive(self, OP.TUN_CONFIRM)
    local timeout = self.client:receive_bool()
    if timeout then return nil, "timeout" end
    self.chunksize = self.client:receive_varint()
    return ctun_process_allow(self)
end

local xfer_run = function(self)
    for i=self.sent+1,#self.chunks do
        if tun_drain(self.tunnel, #self.chunks[i]) then
            tun_send_transfer(
                self.tunnel,
                (i == 1 and self.size or 0),
                self.chunks[i]
            )
            self.sent = i
        else
            return nil, "not enough allowance"
        end
    end
    return ctun_process_allow(self.tunnel)
end

local xfer_methods = {run = xfer_run}

local xfer_new = function(tunnel, body)
    local size = #body
    assert(size > 0)
    local self = setmetatable({}, {__index = xfer_methods})
    self.tunnel = tunnel
    self.size = size
    self.chunks = make_chunks(body, tunnel.chunksize)
    self.sent = 0
    return self
end

local ctun_close = function(self)
    tun_close(self)
    ensure_receive(self, OP.TUN_CLOSE)
    local reason = self.client:receive_string()
    return reason
end

local ctun_methods = {
    init = ctun_send_init,
    confirm = ctun_confirm,
    allow = tun_allow,
    transfer = xfer_new,
    close = ctun_close,
}

local new_client_tunnel = function(client)
    local self = setmetatable({}, {__index = ctun_methods})
    self.client = client
    self.allowance = 0
    self.id = client:new_tun_id()
    return self
end

local new_client_tunnel_init = function(client, cluster, timeout_ms)
    local tun = new_client_tunnel(client)
    tun:init(cluster, timeout_ms)
    return tun
end

local stun_init = function(self)
    self.build_id = self.client:receive_varint()
    self.chunksize = self.client:receive_varint()
    self.id = self.client:new_tun_id()
end

local stun_confirm = function(self)
    self.client:send{
        t_byte(OP.TUN_CONFIRM),
        t_varint(self.build_id),
        t_varint(self.id),
    }
end

local stun_register = function(self)
    self.client.tunnels[self.id] = self
end

local stun_unregister = function(self)
    self.client.tunnels[self.id] = nil
end

local stun_update_transfer = function(self, size, body)
    if size then
        self.xfer = {
            total_size = size,
            cur_size = 0,
            chunks = {},
        }
    end
    self.xfer.cur_size = self.xfer.cur_size + #body
    self.xfer.chunks[#self.xfer.chunks+1] = body
    if self.xfer.cur_size > self.xfer.total_size then
        error("invalid transfer!")
    elseif self.cur_size == self.total_size then
        return table.concat(self.xfer.chunks)
    else
        return nil
    end
end

local stun_methods = {
    init = stun_init,
    confirm = stun_confirm,
    allow = tun_allow,
    register = stun_register,
    unregister = stun_unregister,
    update_transfer = stun_update_transfer,
    close = tun_close,
}

local new_server_tunnel = function(client)
    local self = setmetatable({}, {__index = stun_methods})
    self.client = client
    self.allowance = 0
    self.handlers = {}
    return self
end

--- handlers ---

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
        return nil, fmt("no handler for topic %s", topic)
    end
end

local process_tun_init = function(self)
    local tun = new_server_tunnel(self)
    tun:init()
    tun:register()
    tun:confirm()
    if not self.handlers.tunnel then
        bail("got tunnel but no handler set")
    end
    self.handlers.tunnel(tun)
    return true
end

local _with_tun = function(f)
    return function(self)
        local id = self:receive_varint()
        local tun = self.tunnels[id]
        if tun then
            return f(self, tun)
        else
            return nil, fmt("tunnel %d not found", id)
        end
    end
end

local process_tun_allow = function(self, tun)
    local allowance = self:receive_varint()
    tun.allowance = tun.allowance + allowance
    return true
end

local process_tun_transfer = function(self, tun)
    local size = self:receive_varint()
    local data = self:receive_binary()
    local r = tun:update_transfer(size, data)
    if r then
        if not tun.handlers.message then
            bail("got message but no handler set")
        end
        tun:allow(#r)
        return tun.handlers.message(r)
    end
end

local process_tun_close = function(self, tun)
    local reason = self:receive_string() -- TODO
    tun:unregister()
    return true
end

local ll_handlers = {
    [OP.REQUEST] = process_request,
    [OP.BROADCAST] = process_broadcast,
    [OP.PUBLISH] = process_publish,
    [OP.TUN_INIT] = process_tun_init,
    [OP.TUN_ALLOW] = _with_tun(process_tun_allow),
    [OP.TUN_TRANSFER] = _with_tun(process_tun_transfer),
    [OP.TUN_CLOSE] = _with_tun(process_tun_close),
}

local process_one = function(self)
    local b = self:receive_byte()
    if ll_handlers[b] then
        return {b, ll_handlers[b](self)}
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
    new_tun_id = new_tun_id,
    request = new_request_send,
    broadcast = broadcast,
    publish = publish,
    subscribe = subscribe,
    unsubscribe = unsubscribe,
    tunnel = new_client_tunnel_init,
    process_one = process_one,
}

local new = function(port)
    port = port or 55555
    local self = setmetatable({}, {__index = methods})
    self:connect(port)
    self.req_ctr = 0
    self.tun_ctr = 0
    self.handlers = {pubsub = {}}
    self.tunnels = {}
    return self
end

return {
    new = new,
    OP = OP,
}
