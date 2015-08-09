local util = require "util"
local fmt = string.format

local OBJ = util.bimap({
    COMMIT = 1,
    TREE = 2,
    BLOB = 3,
    TAG = 4,
    OFS_DELTA = 6,
    REF_DELTA = 7,
})

local _unpack_tlint = function(s, offset)
    if not offset then offset = 1 end
    local b0 = s:byte(offset)
    local more, objtype, sz = b0 >> 7 & 0x01, b0 >> 4 & 0x07, b0 & 0x0f
    local n, extra = 0
    while more > 0 do
        b0 = s:byte(offset + n + 1)
        more, extra = b0 >> 7 & 0x01, b0 & 0x7f
        sz = sz + (extra << (4 + n * 7))
        n = n + 1
    end
    return objtype, sz, offset + n + 1
end

local check_hash = function(self)
    return util.sha1.binary(self._raw:sub(1, -21)) == self._raw:sub(-20)
end

local parse_header = function(self)
    local signature, version, objects_count =
        string.unpack(">c4I4I4", self._raw)
    assert(signature == "PACK")
    return {
        version = version,
        objects_count = objects_count,
    }
end

local parse_objects = function(self, n)
    local offset, r, data_size, bytes_read, eof = 13, {}
    for i=1, n do
        local o = {}
        o.type, data_size, offset = _unpack_tlint(self._raw, offset)
        if o.type == OBJ.OFS_DELTA then
            o.offset, offset = _unpack_tlint(self._raw, offset)
        elseif o.type == OBJ.REF_DELTA then
            o.base, offset = string.unpack("c20", self._raw, offset)
        end
        o.data, eof, bytes_read = util.decompress(self._raw:sub(offset))
        assert(#o.data == data_size and eof)
        offset = offset + bytes_read
        r[i] = o
    end
    return r
end

local parse = function(self)
    -- TODO deal with extensions and versions 3 and 4
    local header = self:parse_header()
    assert(header.version == 2)
    local objects = self:parse_objects(header.objects_count)
    return {
        version = header.version,
        objects = objects,
    }
end

local methods = {
    check_hash = check_hash,
    parse_header = parse_header,
    parse_objects = parse_objects,
    parse = parse,
}

local new = function(raw)
    return setmetatable({_raw = raw}, {__index = methods})
end

return {
    new = new,
}
