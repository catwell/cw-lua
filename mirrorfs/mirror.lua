local flu = require "flu"
local posix = require "posix"
local fmt = string.format

local SCRIPT_NAME = arg[0]

local usage = function()
    io.stderr:write(fmt(
        "USAGE: %s /absolute/path/to/source mountpoint\n", SCRIPT_NAME
    ))
    os.exit(1)
end

local log = function(...)
    local f = assert(io.open("/tmp/mirrorfs.log", "ab"))
    f:write(fmt(...))
    f:write("\n")
    f:close()
end

local check = function(...)
    local value, err = ...
    if not value then error(err, 2) end
    return ...
end

local pcheck = function(r, e_msg, e_code)
    if not r then error(e_code, 2) end
    return r
end

local fs = {}
local descriptors = {}

local get_descriptor = function(i, offset)
    local d = descriptors[i]
    if i == 0 or not d then
        error(flu.errno.EINVAL, 2)
    end
    if offset then
        if not d.offset then error(error.EINVAL, 2) end
        if d.offset ~= offset then
            pcheck(posix.lseek(d.fd, offset, posix.SEEK_SET))
            d.offset = offset
        end
    end
    return d
end

local _modestr = function(mode)
    local r = {
        mode.rusr and "r" or "-",
        mode.wusr and "w" or "-",
        mode.xusr and "x" or "-",
        mode.rgrp and "r" or "-",
        mode.wgrp and "w" or "-",
        mode.xgrp and "x" or "-",
        mode.roth and "r" or "-",
        mode.woth and "w" or "-",
        mode.xoth and "x" or "-",
    }
    return table.concat(r)
end

local root = ...
if not (root and root:sub(1,1) == "/") then
    usage()
end

--------------------------------

fs.getattr = function(path)
    local st = posix.lstat(path)
    check(st, flu.errno.ENOENT)
    local r = {
        dev = st.st_dev,
        ino = st.st_ino,
        nlink = st.st_nlink,
        uid = st.st_uid,
        gid = st.st_gid,
        rdev = st.st_rdev,
        access = st.st_atime,
        modification = st.st_mtime,
        change = st.st_ctime,
        size = st.st_size,
        blocks = st.st_blocks,
        blksize = st.st_blksize,
    }
    local _md = function(s)
        return (st.st_mode & posix[s]) ~= 0
    end
    r.mode = {}
    local _md1 = function(t)
        for i=1, #t do
            r.mode[t[i]] = posix["S_IS" .. t[i]:upper()](st.st_mode) ~= 0
        end
    end
    local _md2 = function(t)
        for i=1, #t do
            log(t[i])
            r.mode[t[i]] = (st.st_mode & posix["S_I" .. t[i]:upper()]) ~= 0
        end
    end
    _md1 { "blk", "chr", "fifo", "reg", "dir", "lnk" }
    _md2 {
        "rusr", "wusr", "xusr",
        "rgrp", "wgrp", "xgrp",
        "roth", "woth", "xoth",
        "suid", "sgid",
    }
    return r
end

fs.mkdir = function(path, mode)
    pcheck(posix.mkdir(path))
    pcheck(posix.chmod(path, _modestr(mode)))
end

fs.rmdir = function(path)
    pcheck(posix.rmdir(path))
end

fs.opendir = function(path, fi)
    local ok, dir = pcall(posix.dir, path)
    check(ok, dir)
    fi.fh = #descriptors + 1
    descriptors[fi.fh] = {dir = dir}
end

fs.releasedir = function(path, fi)
    check(fi.fh ~= 0, flu.errno.EINVAL)
    descriptors[fi.fh] = nil
end

fs.readdir = function(path, filler, fi)
    local dir = get_descriptor(fi.fh).dir
    for i=1, #dir do filler(dir[i]) end
end

local _open = function(path, fi, modestr)
    local flags = 0
    for k, v in pairs(fi.flags) do
        log(k, v)
        if v then flags = flags | (posix["O_" .. k:upper()] or 0) end
    end
    local fd = pcheck(posix.open(path, flags, modestr))
    fi.fh = #descriptors + 1
    descriptors[fi.fh] = {fd = fd, offset = 0}
end

fs.create = function(path, mode, fi)
    fi.flags.creat = true
    return _open(path, fi, _modestr(mode))
end

fs.unlink = function(path)
    pcheck(posix.unlink(path))
end

fs.open = function(path, fi)
    return _open(path, fi)
end

fs.release = function(path, fi)
    local d = get_descriptor(fi.fh)
    pcheck(posix.close(d.fd))
    descriptors[fi.fh] = nil
end

fs.read = function(path, size, offset, fi)
    local d = get_descriptor(fi.fh, offset)
    local r = pcheck(posix.read(d.fd, size))
    d.offset = d.offset + #r
    return r
end

fs.write = function(path, buf, offset, fi)
    local d = get_descriptor(fi.fh, offset)
    local r = pcheck(posix.write(d.fd, buf))
    d.offset = d.offset + r
    return r
end

fs.chmod = function(path, mode)
    pcheck(posix.chmod(path, _modestr(mode)))
end

fs.utimens = function(path, access, modification)
    pcheck(posix.utime(path, modification, access))
end

--------------------------------

local _wrap = function(name, f)
    return function(path, ...)
        log("-> %s(%s)", name, path)
        local ok, r = pcall(f, root .. path, ...)
        if not ok then
            log("ERROR: %s", tostring(r))
            error(r, 2)
        end
        return r
    end
end

for k, v in pairs(fs) do
    if type(v) == "function" then fs[k] = _wrap(k, v) end
end

local args = {"mirrorfs", select(2, ...)}
if #args < 2 then usage() end
flu.main(args, fs)
