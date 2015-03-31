local socket = require "socket"
local fmt = string.format

--- output buffer

local obuf_append = function(self, s)
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

local obuf_mt = { __index = {append = obuf_append, consume = obuf_consume}}

local obuf_new = function()
    local self = {empty = true}
    return setmetatable(self, obuf_mt)
end

--- logic

local sessions = {}

local handle_line = function(line, s)
    if sessions[s].username then
        for k,v in pairs(sessions) do
            if k ~= s and v.username then
                v.out:append(fmt(
                    "\r%s \r%s> %s\n%s> ",
                    v.username:gsub(".", " "), -- erase username properly
                    sessions[s].username, line, v.username
                ))
            end
        end
    else
        sessions[s].username = line
    end
    sessions[s].out:append(fmt("%s> ", sessions[s].username))
end

local handle_client = function(s)
    local line, e, partial = s:receive("*l")
    if line then
        if sessions[s].partial then
            local p = sessions[s].partial
            p[#p+1] = line
            line = table.concat(p)
            sessions[s].partial = nil
        end
        handle_line(line, s)
    else
        if e == "closed" then
            sessions[s] = nil
        else
            if not sessions[s].partial then
                sessions[s].partial = {partial}
            else
                sessions[s].partial[#sessions[s].partial+1] = partial
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

local server = assert(socket.bind("*", tonumber(arg[1]) or 3333))
server:settimeout(0)

local e, tr, tw, c
while true do
    local reading, writing = {server}, {}
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
            c, e = tr[i]:accept()
            if c then
                sessions[c] = {out = obuf_new()}
                sessions[c].out:append("username? ")
            else assert(e == "timeout", e) end
        end
    end
end
