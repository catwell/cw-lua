-- ChickenFS
-- Implements a read-only filesystem mirroring a directory with a small twist.

local mirrorfs = require "mirrorfs"

local root, mountpoint = arg[1], arg[2]
if not (root and mountpoint and root:sub(1,1) == "/") then
    io.stderr:write(string.format(
        "USAGE: %s /absolute/path/to/source mountpoint\n", arg[0]
    ))
    os.exit(1)
end

local fs = mirrorfs.new(root, mountpoint)

-- disable writes

local write_handlers = {
    "mkdir", "rmdir", "create", "unlink", "write", "chmod", "utimens"
}
for _, x in ipairs(write_handlers) do fs:unset_handler(x) end

-- overload read

local chicken = function()
    return math.random() < 0.3 and "CHICKEN " or "chicken "
end

local chickensoup = function(s)
    local ls, lc, r = #s, #chicken(), {}
    for i = 1, ls // lc do r[i] = chicken() end
    r[#r+1] = chicken():sub(1, ls % lc)
    return table.concat(r)
end

fs.read = function(self, path, size, offset, fi)
    return chickensoup(
        mirrorfs.default_handlers.read(self, path, size, offset, fi)
    )
end

-- set logfile and run

fs.logfile = "/tmp/chickenfs.log"
fs:main()
