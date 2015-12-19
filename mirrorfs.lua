local flu = require "flu"
local posix = require "posix"
local fmt = string.format

--- helpers

local POSIX_ERRNO = {}
for k,v in pairs(posix) do
    if type(k) == "string" and type(v) == "number" and k:sub(1,1) == "E" then
        POSIX_ERRNO[v] = k
    end
end
for i=1,32 do assert(POSIX_ERRNO[i]) end

local fail = function(err)
    if type(err) == "string" then
        err = flu.errno[err] or err
    elseif type(err) == "number" then
        err = flu.errno[POSIX_ERRNO[err]] or err
    end
    error(err, 0)
end

local check = function(...)
    local value, err = ...
    if not value then fail(err) end
    return ...
end

local pcheck = function(r, e_msg, e_code)
    if not r then fail(e_code) end
    return r
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

--- methods

local log = function(self, ...)
    if not self.logfile then return end
    local f = assert(io.open(self.logfile, "ab"))
    f:write(fmt(...))
    f:write("\n")
    f:close()
end

local get_descriptor = function(self, i, offset)
    local d = self.descriptors[i]
    check(i ~= 0 and d, "EINVAL")
    if offset then
        offset = math.floor(offset)
        check(d.offset, "EINVAL")
        if d.offset ~= offset then
            pcheck(posix.lseek(d.fd, offset, posix.SEEK_SET))
            d.offset = offset
        end
    end
    return d
end

local push_descriptor = function(self, d)
    self.last_descriptor = self.last_descriptor + 1
    self.descriptors[self.last_descriptor] = d
    return self.last_descriptor
end

local clear_descriptor = function(self, i)
    self.descriptors[i] = nil
end

local set_handler = function(self, name, handler)
    self.fs[name] = function(path, ...)
        self:log("-> %s(%s)", name, path)
        local ok, r = pcall(handler, self, self.root .. path, ...)
        if not ok then
            self:log("ERROR: %s", tostring(r))
            error(type(r) == "userdata" and r or flu.errno.EPERM, 0)
        end
        return r
    end
end

local unset_handler = function(self, name)
    self.fs[name] = nil
end

local main = function(self)
    assert(self.name, "name is unset")
    assert(self.mountpoint, "mountpoint is unset")
    assert(self.root, "root is unset")
    local args = {self.name, self.mountpoint}
    flu.main(args, self.fs)
end

local methods = {
    log = log,
    get_descriptor = get_descriptor,
    push_descriptor = push_descriptor,
    clear_descriptor = clear_descriptor,
    set_handler = set_handler,
    unset_handler = unset_handler,
    main = main,
}

--- default handlers (mirror)

local def = {}

def.getattr = function(self, path)
    local st = posix.lstat(path)
    check(st, "ENOENT")
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

def.mkdir = function(self, path, mode)
    pcheck(posix.mkdir(path))
    pcheck(posix.chmod(path, _modestr(mode)))
end

def.rmdir = function(self, path)
    pcheck(posix.rmdir(path))
end

def.opendir = function(self, path, fi)
    local ok, dir = pcall(posix.dir, path)
    check(ok, dir)
    fi.fh = self:push_descriptor({dir = dir})
end

def.releasedir = function(self, path, fi)
    check(fi.fh ~= 0, "EINVAL")
    self:clear_descriptor(fi.fh)
end

def.readdir = function(self, path, filler, fi)
    local dir = self:get_descriptor(fi.fh).dir
    for i=1, #dir do filler(dir[i]) end
end

def.open = function(self, path, fi, modestr)
    -- note: modestr is nil when open is called by Flu
    local flags = 0
    for k, v in pairs(fi.flags) do
        if v then flags = flags | (posix["O_" .. k:upper()] or 0) end
    end
    local fd = pcheck(posix.open(path, flags, modestr))
    fi.fh = self:push_descriptor({fd = fd, offset = 0})
end

def.create = function(self, path, mode, fi)
    fi.flags.creat = true
    return def.open(self, path, fi, _modestr(mode))
end

def.unlink = function(self, path)
    pcheck(posix.unlink(path))
end

def.release = function(self, path, fi)
    local d = self:get_descriptor(fi.fh)
    pcheck(posix.close(d.fd))
    self:clear_descriptor(fi.fh)
end

def.read = function(self, path, size, offset, fi)
    local d = self:get_descriptor(fi.fh, offset)
    local r = pcheck(posix.read(d.fd, size))
    d.offset = d.offset + #r
    return r
end

def.write = function(self, path, buf, offset, fi)
    local d = self:get_descriptor(fi.fh, offset)
    local r = pcheck(posix.write(d.fd, buf))
    d.offset = d.offset + r
    return r
end

def.chmod = function(self, path, mode)
    pcheck(posix.chmod(path, _modestr(mode)))
end

def.utimens = function(self, path, access, modification)
    pcheck(posix.utime(path, modification, access))
end

--- constructor

local _mt = {
    __index = methods,
    __newindex = function(self, k, v)
        if type(v) == "function" then
            self:set_handler(k, v)
        else
            rawset(self, k, v)
        end
    end,
}

local new_empty = function(root, mountpoint)
    local self = {
        name = "mirrorfs",
        descriptors = {},
        last_descriptor = 0,
        fs = {},
        root = root,
        mountpoint = mountpoint,
    }
    return setmetatable(self, _mt)
end

local set_default_handlers = function(self)
    for k, v in pairs(def) do self:set_handler(k, v) end
end

local new = function(root, mountpoint)
    local self = new_empty(root, mountpoint)
    set_default_handlers(self)
    return self
end

return {
    new = new,
    new_empty = new_empty,
    modestr = _modestr,
    fail = fail,
    check = check,
    pcheck = pcheck,
    default_handlers = def,
}
