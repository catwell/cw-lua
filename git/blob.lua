local util = require "util"
local fmt = string.format

local data = function(self)
    if not self._data then
        local s = assert(self:raw():match("^blob (%d+)\0"))
        local l, n = #s, assert(tonumber(s))
        assert(#self._raw == 6 + l + n)
        self._len, self._data = l, self._raw:sub(6 + l)
    end
    return self._data
end

local len = function(self)
    if not self._len then
        self._len = #self:data()
    end
    return self._len
end

local raw = function(self)
    if not self._raw then
        if self._data then
            self._raw = fmt("blob %d\0%s", self:len(), self._data)
        else
            assert(self._compressed)
            self._raw = util.decompress(self._compressed)
        end
    end
    return self._raw
end

local hash = function(self)
    if not self._hash then
        self._hash = util.sha1(self:raw())
    end
    return self._hash
end

local compressed = function(self)
    if not self._compressed then
        self._compressed = util.compress(self:raw())
    end
    return self._compressed
end

local methods = {
    raw = raw,
    data = data,
    len = len,
    hash = hash,
    compressed = compressed,
}

local _new = function(self)
    assert(self._data or self._raw or self._compressed)
    return setmetatable(self,  {__index = methods})
end

local from_data = function(s) return _new({_data = s}) end
local from_raw = function(r) return _new({_raw = r}) end
local from_compressed  = function(c) return _new({_compressed = c}) end

return {
    from_data = from_data,
    from_raw = from_raw,
    from_compressed = from_compressed,
}
