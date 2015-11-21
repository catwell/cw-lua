local cwtest = require "cwtest"
local lmdb = require "lightningmdb"
local M = require "lua-mdb.reader"
local pathx = require "pl.path"
local dirx = require "pl.dir"
local filex = require "pl.file"
local fmt = string.format

local MDB = setmetatable({}, {__index = function(t, k)
    return lmdb["MDB_" .. k]
end})

local db_dir, db = pathx.tmpname()
filex.delete(db_dir)
local db_file = db_dir .. "/data.mdb"

local db_init = function()
    assert(dirx.makepath(db_dir))
    db = {}
    db.env = assert(lmdb.env_create())
    assert(db.env:set_mapsize(1 * 1024 * 1024))
    assert(db.env:open(db_dir, 0, 420))
    db.txn = assert(db.env:txn_begin(nil, 0))
    db.dbi = assert(db.txn:dbi_open(nil, 0))
end

local db_done = function()
    db.env:dbi_close(db.dbi)
    db.txn:commit()
    db.env:close()
end

local db_clean = function()
    assert(dirx.rmtree(db_dir))
end

local random_data = function(size)
    local t = {}
    for i=1,size do t[i] = string.char(math.random(65, 90)) end
    return table.concat(t)
end

local T = cwtest.new()

T:start("empty"); do
    db_init()
    db_done()
    T:eq( M.new(db_file):dump(), {} )
    db_clean()
end; T:done()

T:start("single page"); do
    db_init()
    db.txn:put(db.dbi, "chunky", "bacon", MDB.NODUPDATA)
    db.txn:put(db.dbi, "spam", "eggs", MDB.NODUPDATA)
    db.txn:commit()
    db.txn = assert(db.env:txn_begin(nil, 0))
    db.txn:put(db.dbi, "fu", "bar", MDB.NODUPDATA)
    db_done()
    T:eq(
        M.new(db_file):dump(),
        { chunky = "bacon", spam = "eggs", fu = "bar" }
    )
    db_clean()
end; T:done()

T:start("large values"); do
    db_init()
    local v1 = random_data(5000) -- overflows a page
    local v2 = random_data(70000) -- overflows a short
    db.txn:put(db.dbi, "k1", v1, MDB.NODUPDATA)
    db.txn:put(db.dbi, "k2", v2, MDB.NODUPDATA)
    db_done()
    T:eq( assert(M.new(db_file):dump()), { k1 = v1, k2 = v2 } )
    db_clean()
end; T:done()

T:start("branch pages"); do
    db_init()
    local t = {}
    for i=1, 2000 do
        local k = "k" .. tostring(i)
        t[k] = "x"
        db.txn:put(db.dbi, k, "x", MDB.NODUPDATA)
    end
    db_done()
    T:eq( assert(M.new(db_file):dump()), t )
    db_clean()
end; T:done()

T:exit()
