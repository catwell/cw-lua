local socket = require "socket"
local fmt = string.format

--- output buffer

local obuf_append = function(self, s)
    assert(type(s) == "string")
    if self.head then
        self.tail = self.tail + 1
        self[self.tail] = s
    else
        self.head, self.tail, self.index, self[1] = 1, 1, 1, s
    end
end

local obuf_consume = function(self, bytes)
    local ix, all = self.index + bytes, #self[self.head] + 1
    if ix == all then
        self[self.head] = nil
        if self.tail == self.head then
            self.head, self.tail, self.index = nil, nil, nil
        else
            self.head, self.index = self.head + 1, 1
        end
    elseif ix < all then
        self.index = ix
    else error("overflow") end
end

local obuf_mt = { __index = {append = obuf_append, consume = obuf_consume} }

local obuf_new = function()
    local self = {empty = true}
    return setmetatable(self, obuf_mt)
end

--- session

local _pack = function(...)
    return select('#', ...), {...}
end

local _as_print = function(n, t)
    for i=1,n do t[i] = tostring(t[i]) end
    return table.concat(t, "\t") .. "\n"
end

local sess_message = function(self, ...)
    self.out:append(fmt(
        "\r%s \r%s%s> ",
        self.username:gsub(".", " "), -- erase username properly
        _as_print(_pack(...)), self.username
    ))
end

local sess_new = function(mode)
    local self = {mode = mode, out = obuf_new()}
    if mode == "chat" then self.message = sess_message end
    return self
end

--- logic

local sessions = {}

local handle_line_chat = function(line, s)
    local sess = sessions[s]
    if sess.username then
        for k,v in pairs(sessions) do
            if k ~= s and v.username then
                v:message(fmt("%s> %s", sess.username, line))
            end
        end
    else
        sess.username = line
    end
    sess.out:append(fmt("%s> ", sess.username))
end

local _lua_printer = function(sess)
    return function(...)
        sess.out:append(_as_print(_pack(...)))
    end
end

local chat_sessions = function()
    local r = {}
    for _,v in pairs(sessions) do
        if v.mode == "chat" then r[#r+1] = v end
    end
    return r
end

local _lua_env = {chat_sessions = chat_sessions}
for k,v in pairs(_G) do _lua_env[k] = v end

local handle_line_lua = function(line, s)
    local sess = sessions[s]
    if sess.chunk then
        sess.chunk = sess.chunk .. "\n" .. line
    elseif line:sub(1,1) == "=" then
        sess.chunk = "return " .. line:sub(2)
    else
        sess.chunk = line
    end
    _lua_env.print = _lua_printer(sess)
    local c, e = load(sess.chunk, "=input", "t", _lua_env)
    if (not c) and (e:sub(-5) == "<eof>") then
        sess.out:append(">> ")
    else
        local n, t = _pack(pcall(c))
        if n > 1 then -- error or return
            sess.out:append(_as_print(n-1, {select(2, unpack(t))}))
        end
        sess.out:append("> ")
        sess.chunk = nil
    end
end

local handle_client = function(s)
    local line, e, partial = s:receive("*l")
    local sess = sessions[s]
    if line then
        if sess.partial then
            sess.partial[#sess.partial+1] = line
            line = table.concat(sess.partial)
            sess.partial = nil
        end
        if sess.mode == "chat" then
            handle_line_chat(line, s)
        else
            assert(sess.mode == "lua")
            handle_line_lua(line, s)
        end
    else
        if e == "closed" then
            sessions[s] = nil
        else
            if not sess.partial then
                sess.partial = {partial}
            else
                sess.partial[#sess.partial+1] = partial
            end
        end
    end
end

local handle_write = function(s)
    local b = sessions[s].out
    assert(b.head)
    local r, e, n = s:send(b[b.head], b.index)
    if r then
        n = r
    elseif e == "closed" then
        sessions[s] = nil
    else assert(e == "timeout", e) end
    b:consume(n - b.index + 1)
end

--- main loop

local chatserver = assert(socket.bind("*", tonumber(arg[1]) or 3333))
chatserver:settimeout(0)

local luaserver = assert(socket.bind("*", tonumber(arg[1]) or 3334))
luaserver:settimeout(0)

local e, tr, tw, s
while true do
    local reading, writing = {chatserver, luaserver}, {}
    for k, v in pairs(sessions) do
        reading[#reading+1] = k
        if v.out.head then writing[#writing+1] = k end
    end
    tr, tw, e = socket.select(reading, writing)
    for i=1,#tw do
        handle_write(tw[i])
    end
    for i=1,#tr do
        if sessions[tr[i]] then -- a client
            handle_client(tr[i])
        else -- a server
            s, e = tr[i]:accept()
            if s then
                if tr[i] == chatserver then
                    sessions[s] = sess_new("chat")
                    sessions[s].out:append("username? ")
                else
                    assert(tr[i] == luaserver)
                    sessions[s] = sess_new("lua")
                    sessions[s].out:append("> ")
                end
            else assert(e == "timeout", e) end
        end
    end
end
