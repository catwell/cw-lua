require "pl.strict"
local pretty = require "pl.pretty"
local util = require "util"
local fmt = string.format
local socket = require "socket"

local gitpack = require "pack"

local HOST = "localhost"
local REPO = "haricot"

local encode_pktline = function(s)
    return fmt("%04x", #s + 4) .. s
end

local cnx = socket.tcp()
cnx:connect(HOST, 9418)

local send_pktline = function(s)
    cnx:send(encode_pktline(s))
end

local send_flush = function(s)
    cnx:send("0000")
end

local read_pktline = function()
    local sl = assert(cnx:receive(4))
    local l = tonumber(sl, 16)
    if l > 0 then
        assert(l >= 4)
        return assert(cnx:receive(l - 4))
    end
end

local send_upload_pack = function(repo, host)
    local cmd = table.concat{"git-upload-pack /", repo, "\0host=", host, "\0"}
    send_pktline(cmd)
end

local parse_capabilities = function(s)
    local r = {}
    for c in s:gmatch("([^%s]+)") do
        local k, v = c:match("(%S+)=(%S+)")
        if k then r[k] = v else r[c] = true end
    end
    return r
end

local discover_refs = function(repo, host)
    local r = {refs = {}, capabilities = {}}
    send_upload_pack(repo, host)
    local line, capa = assert(read_pktline()):match("(.+)\0(.+)")
    while true do
        line = read_pktline()
        if not line then break end
        local sha, path = line:match("([0-9a-f]+) (%S+)")
        r.refs[#r.refs+1] = {sha = sha, path = path}
    end
    r.capabilities = parse_capabilities(capa)
    return r
end

local filter_interesting_refs = function(t)
    local r = {}
    for i=1, #t.refs do
        if t.refs[i].path:match("^refs/heads/") or
           t.refs[i].path:match("^refs/tags/") then
           r[#r+1] = t.refs[i].sha
        end
    end
    return r
end

local send_want = function(refs, capabilities)
    assert(type(capabilities) == "string")
    send_pktline("want " .. refs[1] .. " " .. capabilities)
    for i=2, #refs do
        send_pktline("want " .. refs[i])
    end
    send_flush()
    send_pktline("done\n")
end

local default_on_remote = function(line)
    local l = ("\r" .. line):match("([^\r]+\r?)$")
    io.stderr:write("remote: " .. l)
    io.stderr:flush()
end

local default_on_error = function(line)
    error("error: " .. line)
end

local receive_with_sideband = function(on_data, on_remote, on_error)
    if not on_remote then on_remote = default_on_remote end
    if not on_error then on_error = default_on_error end
    assert(type(on_data) == "function")
    local line, b
    while true do
        line = read_pktline()
        while line == "NAK\n" do line = read_pktline() end
        if not line then break end
        b, line = line:byte(), line:sub(2)
        if b == 1 then
            on_data(line)
        elseif b == 2 then
            on_remote(line)
        elseif b == 3 then
            on_error(line)
        else
            error("unexpected line: " .. line)
        end
    end
end

local _refs = discover_refs(REPO, HOST)
local refs = filter_interesting_refs(_refs)
local capa = "multi_ack_detailed side-band-64k agent=git/1.8.2"
send_want(refs, capa)

local packfile = {}
local on_data = function(line)
    packfile[#packfile + 1] = line
end

receive_with_sideband(on_data)

local packdata = table.concat(packfile)

print("res", #packdata)

local pack = gitpack.new(packdata)

assert(pack:check_hash())
pretty.dump(pack:parse())
