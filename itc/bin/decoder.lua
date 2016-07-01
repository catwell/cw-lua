local bin_reader = require "itc.bin.reader"

local function get_i(self)
    local x = self.reader:read(2)
    if x == 0 then
        return self.reader:read(1) == 1
    elseif x == 1 then
        return {0, self:get_i()}
    elseif x == 2 then
        return {self:get_i(), 0}
    else
        return {self:get_i(), self:get_i()}
    end
end

local function get_e(self)
    if self.reader:read(1) == 1 then
        return self.reader:read_int()
    end
    local x = self.reader:read(2)
    if x == 0 then
        return {0, 0, self:get_e()}
    elseif x == 1 then
        return {0, self:get_e(), 0}
    elseif x == 2 then
        return {0, self:get_e(), self:get_e()}
    end
    if self.reader:read(1) == 1 then
        return {self.reader:read_int(), self:get_e(), self:get_e()}
    end
    if self.reader:read(1) == 0 then
        return {self.reader:read_int(), 0, self:get_e()}
    else
        return {self.reader:read_int(), self:get_e(), 0}
    end
end

local methods = {
    get_i = get_i,
    get_e = get_e,
}

local mt = { __index = methods }

local function new(args)
    assert(type(args) == "table")
    local reader = args.reader or bin_reader.new(args.data)
    local self = { reader = reader }
    return setmetatable(self, mt)
end

return {new = new}
