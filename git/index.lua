local util = require "util"
local fmt = string.format

-- see format documentation in Git repo, under:
-- Documentation/technical/index-format.txt

local parse_header = function(self)
    local signature, version, entries_count =
        string.unpack(">c4I4I4", self._raw)
    assert(signature == "DIRC")
    return {
        version = version,
        entries_count = entries_count,
    }
end

local parse_entries = function(self, n)
    local offset, r = 13, {}
    for i=1, n do
        local e = {}
        e.ctime_sec, e.ctime_nsec, e.mtime_sec, e.mtime_nsec,
        e.dev, e.ino, e.mode, e.uid, e.gid, e.file_size,
        e.hash, e.flags, e.path, offset =
            string.unpack(">!8I4I4I4I4I4I4I4I4I4I4c20I2z", self._raw, offset)
        r[i] = e
    end
    return r
end

local parse = function(self)
    -- TODO deal with extensions and versions 3 and 4
    local header = self:parse_header()
    assert(header.version == 2)
    local entries = self:parse_entries(header.entries_count)
    return {
        version = header.version,
        entries = entries,
    }
end

local methods = {
    parse_header = parse_header,
    parse_entries = parse_entries,
    parse = parse,
}

local _new = function(self)
    assert(self._raw)
    return setmetatable(self,  {__index = methods})
end

local from_raw = function(r) return _new({_raw = r}) end

return {
    from_raw = from_raw,
}
