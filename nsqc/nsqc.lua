local socket = require "socket"

local FRAMETYPE = {RESPONSE = 0, ERROR = 1, MESSAGE = 2}

---- validation

local is_posint = function(x)
  return ( (type(x) == "number") and (math.floor(x) == x) and (x >= 0) )
end

local valid_topic = function(s)
    if type(s) ~= "string" then return false end
    local l = #s
    if l == 0 or l > 32 then return false end
    return not not s:match("^[.a-zA-Z0-9_-]+$")
end

local valid_channel = function(s)
    if type(s) ~= "string" then return false end
    local l = #s
    if l == 0 or l > 32 then return false end
    if s:sub(-10) == "#ephemeral" then s = s:sub(1, -11) end
    return not not s:match("^[.a-zA-Z0-9_-]+$")
end

local valid_message_id = function(s)
    if (type(s) ~= "string") or (#s ~= 16) then return false end
    return not not s:match("^[a-f0-9]+$")
end

---- helpers

local command = function(cmd, params, body)
    local _body = ""
    local _params = ""

    if params and next(params) then
        _params = " " .. table.concat(params, " ")
    end

    assert(not body, "unimplemented")

    return table.concat({cmd, _params, "\n", _body})
end

local decode_big_endian_uint = function(str, bytes)
    assert(
        (type(str) == "string") and
        is_posint(bytes) and
        (#str >= bytes)
    )
    local r = 0
    for i=1,bytes do
      r = r * 256 + str:byte(i)
    end
    return r
end

local decode_message = function(data)
    local ts = decode_big_endian_uint(data, 8)
    data = data:sub(9)
    local attempts = decode_big_endian_uint(data, 2)
    data = data:sub(3)
    local id = data:sub(1,16)
    assert(valid_message_id(id), id)
    data = data:sub(17)
    return {
        ts = ts,
        attempts = attempts,
        id = id,
        body = data,
    }
end

local read_u32 = function(self)
    return decode_big_endian_uint(self.cnx:receive(4), 4)
end

local read_frame = function(self)
    local size = read_u32(self)
    assert(size >= 4)
    local frame_type = read_u32(self)
    local data = self.cnx:receive(size - 4)
    if frame_type == FRAMETYPE.RESPONSE then
        return data
    elseif frame_type == FRAMETYPE.ERROR then
        return nil, data
    else
        assert(frame_type == FRAMETYPE.MESSAGE)
        return decode_message(data)
    end
end

---- lowlevel

local connect = function(self, server, port)
  self.cnx = socket.tcp()
  self.cnx:connect(server, port)
  self.cnx:send("  V2")
end

local call = function(self, ...)
    return self.cnx:send(command(...))
end

local subscribe = function(self, topic, channel)
    assert(valid_topic(topic) and valid_channel(channel))
    call(self, "SUB", {topic, channel})
    assert(read_frame(self) == "OK")
end

local ready = function(self, count)
    assert(is_posint(count))
    call(self, "RDY", {count})
end

local finish = function(self, id)
    assert(valid_message_id(id))
    call(self, "FIN", {id})
end

local requeue = function(self, id, timeout)
    assert(valid_message_id(id) and is_posint(timeout))
    call(self, "REQ", {id, timeout})
end

---- highlevel

local consume_one = function(self, handler)
    assert(type(handler) == "function")
    ready(self, 1)
    local msg = assert(read_frame(self))
    if type(msg) == "string" then
        assert(msg == "_heartbeat_")
        call(self, "NOP")
    else
        assert(
            (type(msg) == "table") and
            (type(msg.id) == "string")
        )
        local ok, ok2, timeout = pcall(handler, msg)
        if not ok then print(ok2) end
        if ok and ok2 then
            finish(self, msg.id)
        else
            requeue(self, msg.id, timeout or 0)
        end
    end
end

local methods = {
    connect = connect,
    subscribe = subscribe,
    consume_one = consume_one,
}

local new = function(server, port)
    local self = {}
    setmetatable(self, {__index = methods})
    self:connect(server, port)
    return self
end

return {
    new = new,
}
