local unpack = table.unpack

local function write(self, n, b)
    local sn, sb = self.sn, self.sb + b
    if sb <= 8 then
        sn = sn | (n << (8 - sb))
    else
        sb = sb - 8
        table.insert(self.r, sn | (n >> sb))
        while sb > 8 do
            sb = sb - 8
            table.insert(self.r, (n >> sb) & 0xff)
        end
        sn = (n << (8 - sb)) & 0xff
    end
    if sb == 8 then
        table.insert(self.r, sn)
        sn, sb = 0, 0
    end
    self.sn, self.sb = sn, sb
end

local function write_int(self, n, B)
    if not B then B = 2 end
    if (n >> B) == 0 then
        self:write(0, 1)
        self:write(n, B)
    else
        self:write(1, 1)
        return self:write_int(n - (1 << B), B + 1)
    end
end

local function data(self)
    return string.char(unpack(self.r)) .. string.char(self.sn), self.sb
end

local methods = {
    write = write,
    write_int = write_int,
    data = data,
}

local mt = { __index = methods }

local function new()
    local self = { r = {}, sn = 0, sb = 0 }
    return setmetatable(self, mt)
end

return {new = new}
