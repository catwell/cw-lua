local function read(self, sz)
    local sn, sb = self.s:byte(self.off), self.sb + sz
    assert(sn)
    if sb <= 8 then
        if sb == 8 then
            self.sb, self.off = 0, self.off + 1
        else
            self.sb = sb
        end
        return (sn >> (8 - sb)) & (0xff >> (8 - sz))
    else
        local b = self.sb % 8
        local r = (sn & (0xff >> b)) << (sz - (8 - b))
        self.sb, self.off = 0, self.off + 1
        return r + self:read(sz - (8 - b))
    end
end

local function read_int(self, B, accum)
    if not accum then accum = 0 end
    if not B then B = 2 end
    local b = self:read(1)
    if b == 0 then
        local r = self:read(B)
        return accum + r
    else
        return self:read_int(B + 1, accum + (1 << B))
    end
end

local methods = {
    read = read,
    read_int = read_int,
}

local mt = { __index = methods }

local function new(s)
    local self = { s = s, off = 1, sb = 0 }
    return setmetatable(self, mt)
end

return {new = new}
