local fmt = string.format

local _bit = function(n, mask)
    return (n & mask) == mask
end

local PAGEHDRSZ = 16

local NUMKEYS = function(page)
    return (page.header.pb_lower - PAGEHDRSZ) // 2
end

local NODESZ = function(node)
    return node.mn_lo + (node.mn_hi << 16)
end

local NODEPGNO = function(h1, h2, h3)
    -- 64 bit: pgno in branch nodes is 6B
    return h1 + (h2 << 16) + (h3 << 32)
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

local _page_header = function(raw, offset)
    local r, pad, mp_flags = {}
    r.mp_pgno, pad, mp_flags, offset = string.unpack("<!8I8c2I2", raw, offset)
    r.mp_flags = _mp_flags(mp_flags)
    if r.mp_flags.OVERFLOW then
        r.pb_pages, offset = string.unpack("<!8I4", raw, offset)
    else
        r.pb_lower, r.pb_upper, offset = string.unpack("<!8I2I2", raw, offset)
    end
    return r, offset
end

local _db = function(raw, offset)
    local r, md_flags = {}
    r.md_pad, md_flags, r.md_depth, r.md_branch_pages, r.md_leaf_pages,
        r.md_overflow_pages, r.md_entries, r.md_root, offset =
        string.unpack("<!8I4I2I2I8I8I8I8I8", raw, offset)
    r.md_flags = _md_flags(md_flags)
    return r, offset
end

local _meta = function(raw, base)
    local r = {}
    local offset = base + PAGEHDRSZ
    r.mm_magic, r.mm_version, r.mm_address, r.mm_mapsize, offset =
        string.unpack("<!8I4I4I8I8", raw, offset)
    r.mm_dbs = {}
    r.mm_dbs.free, offset = _db(raw, offset)
    r.mm_dbs.main, offset = _db(raw, offset)
    r.mm_last_pg, r.mm_txnid, offset = string.unpack("<!8I8I8", raw, offset)
    return r
end

local _mp_ptrs = function(raw, count, offset)
    local r = {}
    for i=1,count do
        r[i], offset = string.unpack("<!8I2", raw, offset)
    end
    return r, offset
end

local _leaf_node = function(raw, offset)
    local r, mn_flags = {}
    r.mn_lo, r.mn_hi, mn_flags, r.mn_ksize, offset =
        string.unpack("<!8I2I2I2I2", raw, offset)
    r.mn_flags = _mn_flags(mn_flags)
    r.k = raw:sub(offset, offset + r.mn_ksize - 1)
    offset = offset + r.mn_ksize
    r.mv_size = NODESZ(r)
    if r.mn_flags.BIGDATA then
        -- NOTE: this read is *not* aligned
        r.overflow_pgno, offset = string.unpack("<I8", raw, offset)
    else
        r.v = raw:sub(offset, offset + r.mv_size - 1)
    end
    return r
end

local _branch_node = function(raw, offset)
    local r, h1, h2, h3 = {}
    h1, h2, h3, r.mn_ksize, offset = string.unpack("<!8I2I2I2I2", raw, offset)
    r.mp_pgno = NODEPGNO(h1, h2, h3)
    r.k = raw:sub(offset, offset + r.mn_ksize - 1)
    offset = offset + r.mn_ksize
    return r
end

local _leaf_nodes = function(page, raw, base)
    local r = {}
    local mp_ptrs = _mp_ptrs(raw, NUMKEYS(page), base + PAGEHDRSZ)
    for i=1,#mp_ptrs do
        r[i] = _leaf_node(raw, base + mp_ptrs[i])
    end
    return r
end

local _branch_nodes = function(page, raw, base)
    local r = {}
    local mp_ptrs = _mp_ptrs(raw, NUMKEYS(page), base + PAGEHDRSZ)
    for i=1,#mp_ptrs do
        r[i] = _branch_node(raw, base + mp_ptrs[i])
    end
    return r
end

local _page = function(raw, offset)
    local r, base = {}, offset or 0
    r.header, offset = _page_header(raw, offset)
    if r.header.mp_flags.META then
        r.meta = _meta(raw, base)
    elseif r.header.mp_flags.LEAF then
        -- TODO check LEAF2 and SUBP
        r.nodes = _leaf_nodes(r, raw, base)
    elseif r.header.mp_flags.OVERFLOW then
        -- nothing
    elseif r.header.mp_flags.BRANCH then
        r.nodes = _branch_nodes(r, raw, base)
    else
        return nil, fmt("unknown page type: %s", flags_repr(r.header.mp_flags))
    end
    return r
end

return {
    page_header = _page_header,
    page = _page,
    NUMKEYS = NUMKEYS,
    PAGEHDRSZ = PAGEHDRSZ,
}
