local mdb_parser = require "lua-mdb.parser"
local fmt = string.format

local PAGESIZE = 4096

local e_str = function(e)
    return type(e) == "string" and e or "unexpected error"
end

local dbg = function(self, ...)
    if self.DEBUG then print(fmt(...)) end
end

local err = function(self, e)
    assert(e)
    if self.DEBUG then error(e or "?") end
    return nil, e
end

local res = function(self, r, e)
    if self.DEBUG then
        return assert(r, e)
    else
        return r, e
    end
end

local raw_data = function(self, offset, size)
    assert(
        type(self) == "table" and
        type(offset) == "number" and offset >= 0 and
        type(size) == "number" and size >= 0
    )
    local f, r, e
    f, e = io.open(self.path, "rb")
    if not f then return self:err(e) end
    r, e = f:seek("set", offset)
    if not r then
        f:close()
        return self:err(e)
    end
    r, e = f:read(size)
    f:close()
    return self:res(r, e)
end

local raw_page = function(self, n)
    return raw_data(self, n * PAGESIZE, PAGESIZE)
end

local page = function(self, n)
    assert(type(n) == "number" and n >= 0)
    local raw, e = raw_page(self, n)
    if not raw then return self:err(e) end
    local r, e = self.parser:page(raw)
    if not r then
        e = fmt("while parsing page %d: %s", n, e_str(e))
    end
    return self:res(r, e)
end

local pick_meta_page = function(self)
    local m = {page(self, 0), page(self, 1)}
    if not (m[1] and m[2]) then
        return self:err(fmt("could not read meta page: %s", e_str(m[3])))
    end
    local n = m[2].meta.mm_txnid > m[1].meta.mm_txnid and 2 or 1
    self:dbg("picked meta page %d", n - 1)
    local r = m[n]
    assert(r.meta.mm_magic == 0xBEEFC0DE)
    assert(r.meta.mm_version == 1 or r.meta.mm_version == 999)
    return r
end

-- returns the ID of the first node >= key or nil
-- TODO use binary search
local node_search = function(nodes, key)
    for i=1,#nodes do
        if nodes[i].k >= key then return i end
    end
end

local branch_search = function(nodes, key)
    local i = node_search(nodes, key)
    if not i then
        return #nodes
    elseif nodes[i].k == key then
        return i
    else
        return i-1
    end
end

local is_branch = function(page)
    return page.header.mp_flags.BRANCH
end

local is_leaf = function(page)
    return page.header.mp_flags.LEAF
end

local leaf_value = function(self, node)
    if node.mn_flags.BIGDATA then
        local v, e = raw_data(
            self,
            node.overflow_pgno * PAGESIZE + self.parser:PAGEHDRSZ(),
            node.mv_size
        )
        if not v then return self:err(e) end
        return v
    else
        return node.v
    end
end

local leaf_content = function(self, page)
    assert(page and is_leaf(page))
    local r = {}
    for i=1,#page.nodes do
        local v, e = leaf_value(self, page.nodes[i])
        if not v then return self:err(e) end
        r[page.nodes[i].k] = v
    end
    return r
end

local get = function(self, k)
    local meta, e = pick_meta_page(self)
    if not meta then return self:err(e) end
    local root_page_num = meta.meta.mm_dbs.main.md_root
    if root_page_num == self.parser:P_INVALID() then return nil end
    assert(root_page_num >= 0)
    local p, e = page(self, meta.meta.mm_dbs.main.md_root)
    if not p then return self:err(e) end
    while is_branch(p) do
        local i = branch_search(p.nodes, k)
        p, e = page(self, p.nodes[i].mp_pgno)
        if not p then return self:err(e) end
    end
    assert(is_leaf(p))
    local i = node_search(p.nodes, k)
    if not i then return nil end
    return leaf_value(self, p.nodes[i])
end

local _dump; _dump = function(self, p, t)
    local q, e, ok
    if not t then t = {} end
    if is_branch(p) then
        for i=1, #p.nodes do
            q, e = page(self, p.nodes[i].mp_pgno)
            if not q then return self:err(e) end
            ok, e = _dump(self, q, t)
            if not ok then return self:err(e) end
        end
    else
        q, e = leaf_content(self, p)
        if not q then return self:err(e) end
        for k, v in pairs(q) do t[k] = v end
    end
    return t
end

local dump = function(self)
    local meta, e = pick_meta_page(self)
    if not meta then return self:err(e) end
    local root_page_num = meta.meta.mm_dbs.main.md_root
    if root_page_num == self.parser:P_INVALID() then return {} end
    assert(root_page_num >= 0)
    local root_page, e = page(self, meta.meta.mm_dbs.main.md_root)
    if not root_page then return self:err(e) end
    return _dump(self, root_page)
end

local methods = {
    dump = dump,
    get = get,
    -- below: for debug onlu (consider private)
    pick_meta_page = pick_meta_page,
    raw_page = raw_page,
    page = page,
    dbg = dbg,
    err = err,
    res = res,
}

local autodetect_bits = function()
    -- This parses the Lua 5.3 bytecode header to get the size of size_t.
    -- See ldump.c in the Lua source code.
    local s = string.dump(function() end)
    assert(s:sub(1,12) == "\x1bLua\x53\x00\x19\x93\r\n\x1a\n")
    return 8 * s:byte(14)
end

local new = function(path, _opts)
    assert(type(path) == "string")

    local opts = {}
    if _opts then
        for k, v in pairs(_opts) do opts[k] = v end
    end
    if not opts.bits then opts.bits = autodetect_bits() end
    assert(opts.bits == 32 or opts.bits == 64)

    local r = {
        path = path,
        PAGESIZE = PAGESIZE,
        DEBUG = false,
        parser = mdb_parser.new({bits = opts.bits}),
    }
    return setmetatable(r, {__index = methods})
end

return {
    new = new,
}
