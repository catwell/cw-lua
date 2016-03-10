local fmt = string.format

local _bit = function(n, mask)
    return (n & mask) == mask
end

local flags_repr = function(flags)
    local t = {}
    for k, v in pairs(flags) do
        if v then t[#t+1] = k end
    end
    return table.concat(t, " | ")
end

local _mp_flags = function(i)
    return {
        BRANCH = _bit(i, 0x01),
        LEAF = _bit(i, 0x02),
        OVERFLOW = _bit(i, 0x04),
        META = _bit(i, 0x08),
        DIRTY = _bit(i, 0x10),
        LEAF2 = _bit(i, 0x20),
        SUBP = _bit(i, 0x40),
        LOOSE = _bit(i, 0x4000),
        KEEP = _bit(i, 0x8000),
    }
end

local _md_flags = function(i)
    return {
        REVERSEKEY = _bit(i, 0x02),
        DUPSORT = _bit(i, 0x04),
        INTEGERKEY = _bit(i, 0x08),
        DUPFIXED = _bit(i, 0x10),
        INTEGERDUP = _bit(i, 0x20),
        REVERSEDUP = _bit(i, 0x40),
        CREATE = _bit(i, 0x40000),
    }
end

local _mn_flags = function(i)
    return {
        BIGDATA = _bit(i, 0x01),
        SUBDATA = _bit(i, 0x02),
        DUPDATA = _bit(i, 0x04),
    }
end

local R = function(self, raw, offset, p32, p64)
    if not p64 then p64 = p32 end
    return string.unpack(
        (self.bits == 32) and "<!4" .. p32 or "<!8" .. p64,
        raw, offset
    )

end

local P_INVALID = function(self)
    return R(self, "\xff\xff\xff\xff\xff\xff\xff\xff", 1, "I4", "I8")
end

local PAGEHDRSZ = function(self)
    return (self.bits == 32) and 12 or 16
end

local NUMKEYS = function(self, page)
    return (page.header.pb_lower - PAGEHDRSZ(self)) // 2
end

local NODESZ = function(self, node)
    return node.mn_lo + (node.mn_hi << 16)
end

local NODEPGNO = function(self, h1, h2, h3)
    local r = h1 + (h2 << 16)
    if self.bits == 64 then
        -- 64 bit: pgno in branch nodes is 6B
        r = r + (h3 << 32)
    end
    return r
end

local _page_header = function(self, raw, offset)
    local r, pad, mp_flags = {}
    r.mp_pgno, pad, mp_flags, offset = R(self, raw, offset, "I4c2I2", "I8c2I2")
    r.mp_flags = _mp_flags(mp_flags)
    if r.mp_flags.OVERFLOW then
        r.pb_pages, offset = R(self, raw, offset, "I4")
    else
        r.pb_lower, r.pb_upper, offset = R(self, raw, offset, "I2I2")
    end
    return r, offset
end

local _db = function(self, raw, offset)
    local r, md_flags = {}
    r.md_pad, md_flags, r.md_depth, r.md_branch_pages, r.md_leaf_pages,
        r.md_overflow_pages, r.md_entries, r.md_root, offset =
        R(self, raw, offset, "I4I2I2I4I4I4I4I4", "I4I2I2I8I8I8I8I8")
    r.md_flags = _md_flags(md_flags)
    return r, offset
end

local _meta = function(self, raw, base)
    local r = {}
    local offset = base + PAGEHDRSZ(self)
    r.mm_magic, r.mm_version, r.mm_address, r.mm_mapsize, offset =
        R(self, raw, offset, "I4I4I4I4", "I4I4I8I8")
    r.mm_dbs = {}
    r.mm_dbs.free, offset = _db(self, raw, offset)
    r.mm_dbs.main, offset = _db(self, raw, offset)
    r.mm_last_pg, r.mm_txnid, offset = R(self, raw, offset, "I4I4", "I8I8")
    return r
end

local _mp_ptrs = function(self, raw, count, offset)
    local r = {}
    for i=1,count do
        r[i], offset = R(self, raw, offset, "I2")
    end
    return r, offset
end

local _leaf_node = function(self, raw, offset)
    local r, mn_flags = {}
    r.mn_lo, r.mn_hi, mn_flags, r.mn_ksize, offset =
        R(self, raw, offset, "I2I2I2I2")
    r.mn_flags = _mn_flags(mn_flags)
    r.k = raw:sub(offset, offset + r.mn_ksize - 1)
    offset = offset + r.mn_ksize
    r.mv_size = NODESZ(self, r)
    if r.mn_flags.BIGDATA then
        -- NOTE: this read is *not* aligned
        local ptrn = (self.bits == 32) and "<I4" or "<I8"
        r.overflow_pgno, offset = string.unpack(ptrn, raw, offset)
    else
        r.v = raw:sub(offset, offset + r.mv_size - 1)
    end
    return r
end

local _branch_node = function(self, raw, offset)
    local r, h1, h2, h3 = {}
    h1, h2, h3, r.mn_ksize, offset = R(self, raw, offset, "I2I2I2I2")
    r.mp_pgno = NODEPGNO(self, h1, h2, h3)
    r.k = raw:sub(offset, offset + r.mn_ksize - 1)
    offset = offset + r.mn_ksize
    return r
end

local _leaf_nodes = function(self, page, raw, base)
    local r = {}
    local mp_ptrs = _mp_ptrs(
        self, raw, NUMKEYS(self, page), base + PAGEHDRSZ(self)
    )
    for i=1,#mp_ptrs do
        r[i] = _leaf_node(self, raw, base + mp_ptrs[i])
    end
    return r
end

local _branch_nodes = function(self, page, raw, base)
    local r = {}
    local mp_ptrs = _mp_ptrs(
        self, raw, NUMKEYS(self, page), base + PAGEHDRSZ(self)
    )
    for i=1,#mp_ptrs do
        r[i] = _branch_node(self, raw, base + mp_ptrs[i])
    end
    return r
end

local _page = function(self, raw, offset)
    local r, base = {}, offset or 0
    r.header, offset = _page_header(self, raw, offset)
    if r.header.mp_flags.META then
        r.meta = _meta(self, raw, base)
    elseif r.header.mp_flags.LEAF then
        -- TODO check LEAF2 and SUBP
        r.nodes = _leaf_nodes(self, r, raw, base)
    elseif r.header.mp_flags.OVERFLOW then
        -- nothing
    elseif r.header.mp_flags.BRANCH then
        r.nodes = _branch_nodes(self, r, raw, base)
    else
        return nil, fmt("unknown page type: %s", flags_repr(r.header.mp_flags))
    end
    return r
end

local methods = {
    page_header = _page_header,
    page = _page,
    NUMKEYS = NUMKEYS,
    PAGEHDRSZ = PAGEHDRSZ,
    P_INVALID = P_INVALID,
}

local new = function(opts)
    assert(opts.bits == 32 or opts.bits == 64)
    local r = {bits = opts.bits}
    return setmetatable(r, {__index = methods})
end

return {
    new = new,
}
