local sha1 = require "sha1"
local zlib = require "zlib"

-- use lua-zlib, available at https://github.com/brimworks/lua-zlib

_DEBUG = false -- LuaPosix
local posix = require "posix"
local ERRNO = require "posix.errno"

local compress = function(s)
    return zlib.deflate()(s, "finish")
end

local decompress = function(s)
    return zlib.inflate()(s)
end

local mkdir = function(path)
    local ok, err, errcode = posix.mkdir(path)
    if ok or errcode == ERRNO.EEXIST then
        return true
    else
        return nil, err, errcode
    end
end

local read_file = function(path)
    local f, r, e
    f, e = io.open(path, "rb")
    if not f then return f, e end
    r, e = f:read("*all")
    f:close()
    return r, e
end

local write_file = function(path, data)
    local f, r, e
    f, e = io.open(path, "wb")
    if not f then return f, e end
    r, e = f:write(data)
    f:close()
    return r, e
end

return {
    sha1 = sha1,
    compress = compress,
    decompress = decompress,
    mkdir = mkdir,
    read_file = read_file,
    write_file = write_file,
}
