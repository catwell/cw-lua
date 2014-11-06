local p = require "checkedposix"

-- NOTE: obviously you don't really want to do that,
-- allocations will kill you...

local STDIN_FILENO = p.fileno(io.stdin)
local STDOUT_FILENO = p.fileno(io.stdout)
local CHUNK_SZ = 512

local chunk, sz

while true do
    chunk = p.read(STDIN_FILENO, 512)
    if chunk == "" then break end;
    sz = p.write(STDOUT_FILENO, chunk); assert(sz == #chunk)
end
