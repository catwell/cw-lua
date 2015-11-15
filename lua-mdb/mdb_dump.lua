local reader = require "lua-mdb.reader"
local to_hex = assert((require "cwbase").to_hex)
local fmt = string.format

local sorted_pairs = function(t)
    local idx, i = {}, 0
    for k in pairs(t) do
        i = i + 1
        idx[i] = k
    end
    table.sort(idx)
    i = 0
    local f = function(t, _)
        i = i + 1
        return idx[i], t[idx[i]]
    end
    return f, t, nil
end

local r = reader.new(arg[1] .. "/data.mdb")
local mp = r:pick_meta_page()

print("VERSION=3")
print("format=bytevalue")
print("type=btree")
print("mapsize=1048576")
print("maxreaders=126")
print("db_pagesize=4096")
print("HEADER=END")

local t = assert(r:dump())

for k, v in sorted_pairs(t) do
    print(" " .. to_hex(k))
    print(" " .. to_hex(v))
end
print("DATA=END")
