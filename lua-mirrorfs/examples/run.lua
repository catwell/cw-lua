-- MirrorFS Hello World.
-- Runs a filesystem mirroring a directory.

local mirrorfs = require "mirrorfs"

local root, mountpoint = arg[1], arg[2]
if not (root and mountpoint and root:sub(1,1) == "/") then
    io.stderr:write(string.format(
        "USAGE: %s /absolute/path/to/source mountpoint\n", arg[0]
    ))
    os.exit(1)
end

local fs = mirrorfs.new(root, mountpoint)
fs.logfile = "/tmp/mirrorfs.log"
fs:main()
