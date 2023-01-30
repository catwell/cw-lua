local function read_file (fn)
    local f = assert(io.open(fn, "rb"))
    local r = f:read("*all")
    f:close()
    return r
end

print("return [=[")
print(read_file(arg[1]))
print("]=]")
