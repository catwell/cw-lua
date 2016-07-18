local reader = require "lua-mdb.reader"
local to_hex = assert((require "base2base").to_hex)
local sorted_pairs = (require "lua-mdb.util").sorted_pairs
local fmt = string.format

local r = reader.new(
    arg[1] .. "/data.mdb",
    {
        DEBUG = (os.getenv("LUA_MDB_DEBUG") == "y"),
        bits = tonumber(arg[2]),
    }
)

local mp = r:pick_meta_page()

print("VERSION=3")
print("format=bytevalue")
print("type=btree")
print(fmt("mapsize=%d", mp.meta.mm_mapsize))
print("maxreaders=126")
print("db_pagesize=4096")
print("HEADER=END")

local t = assert(r:dump {check_cycles = true})

for k, v in sorted_pairs(t) do
    print(" " .. to_hex(k))
    print(" " .. to_hex(v))
end
print("DATA=END")
