local bin_writer = require "itc.bin.writer"

local function add_i(self, t)
    if type(t) == "boolean" then
        self.writer:write(0, 2)
        self.writer:write(t and 1 or 0, 1)
    else
        assert(type(t) == "table" and #t == 2)
        if t[1] == 0 then
            self.writer:write(1, 2)
            self:add_i(t[2])
        elseif t[2] == 0 then
            self.writer:write(2, 2)
            self:add_i(t[1])
        else
            self.writer:write(3, 2)
            self:add_i(t[1])
            self:add_i(t[2])
        end
    end
end

local function add_e(self, t)
    if type(t) == "number" then
        self.writer:write(1, 1)
        self.writer:write_int(t)
    else
        assert(type(t) == "table" and #t == 3)
        self.writer:write(0, 1)
        if t[1] == 0 then
            if t[2] == 0 then
                self.writer:write(0, 2)
                self:add_e(t[3])
            elseif t[3] == 0 then
                self.writer:write(1, 2)
                self:add_e(t[2])
            else
                self.writer:write(2, 2)
                self:add_e(t[2])
                self:add_e(t[3])
            end
        else
            self.writer:write(3, 2)
            if t[2] == 0 then
                self.writer:write(0, 1)
                self.writer:write(0, 1)
                self.writer:write_int(t[1])
                self:add_e(t[3])
            elseif t[3] == 0 then
                self.writer:write(0, 1)
                self.writer:write(1, 1)
                self.writer:write_int(t[1])
                self:add_e(t[2])
            else
                self.writer:write(1, 1)
                self.writer:write_int(t[1])
                self:add_e(t[2])
                self:add_e(t[3])
            end
        end
    end
end

local function data(self)
    return self.writer:data()
end

local methods = {
    add_i = add_i,
    add_e = add_e,
    data = data,
}

local mt = { __index = methods }

local function new(args)
    args = args or {}
    local writer = args.writer or bin_writer.new()
    local self = { writer = writer }
    return setmetatable(self, mt)
end

return {new = new}
