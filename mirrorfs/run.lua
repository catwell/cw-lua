local mirrorfs = require "mirrorfs"
local fmt = string.format

local SCRIPT_NAME = arg[0]

local usage = function()
    io.stderr:write(fmt(
        "USAGE: %s /absolute/path/to/source mountpoint\n", SCRIPT_NAME
    ))
    os.exit(1)
end

local root, mountpoint = arg[1], arg[2]
if not (root and mountpoint and root:sub(1,1) == "/") then
    usage()
end

local fs = mirrorfs.new(root, mountpoint)
fs.logfile = "/tmp/mirrorfs.log"
fs:main()
