local p = require "checkedposix"

local MSG = "hello world\n"
local STDIN_FILENO = p.fileno(io.stdin)

local r,w = p.pipe()
local pid = p.fork()

if pid ~= 0 then -- parent
    p.close(r)
    local sz = p.write(w, MSG); assert(sz == #MSG)
    p.close(w)
    -- wait for child to finish
    p.wait(pid)
else -- child
    p.close(STDIN_FILENO)
    p.dup(r)
    p.close(r)
    p.close(w)
    p.exec("/bin/wc", {[0]="wc"})
end
