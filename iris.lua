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
        -- drop extra return values
        local r = assert(self.cnx:receive(sz))
        return r
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

local close = function(self)
    self:send{t_byte(OP.CLOSE)}
end

local teardown = function(self)
    self:close()
    local b
    while true do
        b = self:receive_byte()
        if b == OP.CLOSE then
            local reason = self:receive_string()
            assert(reason == "")
            break
        else
            self:process_type(b)
        end
    end
    return true
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

local req_register = function(self)
    self.client.requests[self.id] = self
end

local req_unregister = function(self)
    self.client.requests[self.id] = nil
end

local req_send = function(self, cluster, body, timeout_ms)
    self.client:send{
        t_byte(OP.REQUEST),
        t_varint(self.id),
        t_string(cluster),
        t_binary(body),
        t_varint(timeout_ms),
    }
    self._response = {nil, "pending"}
    self:register()
end

local req_process_reply = function(self)
    local timeout = self.client:receive_bool()
    if timeout then
        self._response = {nil, "timeout"}
    else
        local success = self.client:receive_bool()
        if success then
            self._response = {self.client:receive_binary()}
        else
            self._response = {nil, self.client:receive_string()}
        end
    end
    self:unregister()
    return self._response
end

local req_response = function(self)
    return table.unpack(self._response)
end

local req_methods = {
    register = req_register,
    unregister = req_unregister,
    send = req_send,
    process_reply = req_process_reply,
    response = req_response,
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

local _with_req = function(f)
    return function(self)
        local id = self:receive_varint()
        local req = self.requests[id]
        if req then
            return f(self, req)
        else
            return nil, fmt("request %d not found", id)
        end
    end
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

local tun_register = function(self)
    self.client.tunnels[self.id] = self
end

local tun_unregister = function(self)
    self.client.tunnels[self.id] = nil
end

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
    return true
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

local xfer_in_reset = function(self)
    self.chunks = {}
    self.cur_size = 0
    self.total_size = nil
end

local xfer_in_update = function(self)
    local size = self.tunnel.client:receive_varint()
    local body = self.tunnel.client:receive_binary()
    if size == 0 then
        assert(self.total_size)
    else
        assert(not self.total_size)
        self.total_size = size
    end
    self.cur_size = self.cur_size + #body
    self.chunks[#self.chunks+1] = body
    assert(self.cur_size <= self.total_size)
    if self.cur_size == self.total_size then
        local r = table.concat(self.chunks)
        self.tunnel:allow(#r)
        self:reset()
        return r
    else
        return nil
    end
end

local xfer_in_methods = {
    update = xfer_in_update,
    reset = xfer_in_reset,
}

local xfer_in_new = function(tunnel)
    local self = setmetatable({}, {__index = xfer_in_methods})
    self.tunnel = tunnel
    self:reset()
    return self
end

local tun_cosend = function(self, msg)
    local xfer = xfer_new(self, msg)
    while not xfer:run() do coroutine.yield() end
end

local tun_methods = {
    register = tun_register,
    unregister = tun_unregister,
    allow = tun_allow,
    transfer = xfer_new,
    cosend = tun_cosend,
    close = tun_close,
}

local _new_tunnel = function(client, mt)
    local self = setmetatable({}, {__index = mt})
    self.client = client
    self.allowance = 0
    self.handlers = {}
    self.starved = {}
    self.xfer_in = xfer_in_new(self)
    return self
end

local ctun_init = function(self, cluster, timeout_ms)
    self.id = self.client:new_tun_id()
    self.client:send{
        t_byte(OP.TUN_INIT),
        t_varint(self.id),
        t_string(cluster),
        t_varint(timeout_ms),
    }
    self:register()
end

local ctun_confirm = function(self)
    ensure_receive(self, OP.TUN_CONFIRM)
    local timeout = self.client:receive_bool()
    if timeout then return nil, "timeout" end
    self.chunksize = self.client:receive_varint()
    ensure_receive(self, OP.TUN_ALLOW)
    local allowance = self.client:receive_varint()
    self.allowance = self.allowance + allowance
    return true
end

local ctun_methods = setmetatable(
    {
        init = ctun_init,
        confirm = ctun_confirm,
    },
    {__index = tun_methods}
)

local new_client_tunnel = function(client, cluster, timeout_ms)
    local tun = _new_tunnel(client, ctun_methods)
    tun:init(cluster, timeout_ms)
    return tun
end

local stun_init = function(self)
    self.build_id = self.client:receive_varint()
    self.chunksize = self.client:receive_varint()
    self.id = self.client:new_tun_id()
    self:register()
end

local stun_confirm = function(self)
    self.client:send{
        t_byte(OP.TUN_CONFIRM),
        t_varint(self.build_id),
        t_varint(self.id),
    }
end

local stun_methods = setmetatable(
    {
        init = stun_init,
        confirm = stun_confirm,
    },
    {__index = tun_methods}
)

local new_server_tunnel = function(client)
    return _new_tunnel(client, stun_methods)
end

--- handlers ---

local process_request = function(self)
    local id = self:receive_varint()
    local body = self:receive_binary()
    local timeout_ms = self:receive_varint()
    -- TODO discard expired requests
    if self.handlers.request then
        local reply, err = self.handlers.request(body)
        self:send{
            t_byte(OP.REPLY),
            t_varint(id),
            t_bool(reply),
            reply and t_binary(reply) or t_string(err or "(error)"),
        }
        return body, {reply, err}
    else
        return body
    end
end

local process_reply = function(self, req)
    return req:process_reply()
end

local process_broadcast = function(self)
    local body = self:receive_binary()
    if self.handlers.broadcast then
        return body, self.handlers.broadcast(body)
    else
        return body
    end
end

local process_publish = function(self)
    local topic = self:receive_string()
    local body = self:receive_binary()
    if self.handlers.pubsub[topic] then
        return {topic, body}, self.handlers.pubsub[topic](body)
    else
        return {topic, body}
    end
end

local process_tun_init = function(self)
    local tun = new_server_tunnel(self)
    tun:init()
    tun:confirm()
    if self.handlers.tunnel then
        return tun.id, self.handlers.tunnel(tun)
    else
        return tun.id
    end
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

local _unstarve = function(tun)
    while #tun.starved > 0 do
        if coroutine.status(tun.starved[1]) == "dead" then
            table.remove(tun.starved, 1)
        else
            coroutine.resume(co)
        end
    end
end

local process_tun_allow = function(self, tun)
    local allowance = self:receive_varint()
    tun.allowance = tun.allowance + allowance
    _unstarve(tun)
    return tun.id, allowance
end

local process_tun_transfer = function(self, tun)
    local msg = tun.xfer_in:update()
    if msg and tun.handlers.message then
        local co = coroutine.create(tun.handlers.message)
        local _, r = assert(coroutine.resume(co, msg))
        tun.starved[#tun.starved+1] = co
        _unstarve(tun)
        return tun.id, msg, r
    else
        return tun.id, msg
    end
end

local process_tun_close = function(self, tun)
    local reason = self:receive_string()
    tun:unregister()
    return tun.id, reason
end

local ll_handlers = {
    [OP.REQUEST] = process_request,
    [OP.REPLY] = _with_req(process_reply),
    [OP.BROADCAST] = process_broadcast,
    [OP.PUBLISH] = process_publish,
    [OP.TUN_INIT] = process_tun_init,
    [OP.TUN_ALLOW] = _with_tun(process_tun_allow),
    [OP.TUN_TRANSFER] = _with_tun(process_tun_transfer),
    [OP.TUN_CLOSE] = _with_tun(process_tun_close),
}

local process_type = function(self, b)
    if not ll_handlers[b] then unexpected_opcode(b) end
    return b, ll_handlers[b](self)
end

local process_one = function(self, timeout)
    if timeout then self.cnx:settimeout(timeout) end
    local b, e = self.cnx:receive(1)
    if timeout then self.cnx:settimeout(nil) end
    if not b then return nil, e end
    return self:process_type(b:byte())
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
    close = close,
    teardown = teardown,
    new_req_id = new_req_id,
    new_tun_id = new_tun_id,
    request = new_request_send,
    broadcast = broadcast,
    publish = publish,
    subscribe = subscribe,
    unsubscribe = unsubscribe,
    tunnel = new_client_tunnel,
    process_type = process_type,
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
    self.requests = {}
    return self
end

return {
    new = new,
    OP = OP,
}
