local util = require "util"
local fmt = string.format

local gitblob = require "blob"
local gitindex = require "index"

local DEFAULT_CONFIG = [[
[core]
    repositoryformatversion = 0
    filemode = true
    bare = false
    logallrefupdates = true
]]

local subpath = function(self, ...)
    return fmt("%s/.git/%s", self._root, table.concat({...}, "/"))
end

local object_path = function(self, hash)
    return self:subpath("objects", hash:sub(1, 2), hash:sub(3))
end

local index_path = function(self)
    return self:subpath("index")
end

local init = function(self)
    assert(util.mkdir(self:subpath()))
    assert(util.mkdir(self:subpath("branches")))
    assert(util.mkdir(self:subpath("hooks")))
    assert(util.mkdir(self:subpath("info")))
    assert(util.mkdir(self:subpath("objects")))
    assert(util.mkdir(self:subpath("objects", "info")))
    assert(util.mkdir(self:subpath("objects", "pack")))
    assert(util.mkdir(self:subpath("refs")))
    assert(util.mkdir(self:subpath("refs", "heads")))
    assert(util.mkdir(self:subpath("refs", "tags")))
    assert(util.write_file(self:subpath("HEAD"), "ref: refs/heads/master\n"))
    assert(util.write_file(self:subpath("config"), DEFAULT_CONFIG))
end

local load_object = function(self, hash)
    local compressed = util.read_file(self:object_path(hash))
    if not compressed then return nil end
    return gitblob.from_compressed(compressed)
end

local save_object = function(self, blob)
    local path = self:object_path(blob:hash())
    assert(util.mkdir(path:sub(1, -40)))
    return util.write_file(path, blob:compressed())
end

local load_index = function(self)
    local raw = util.read_file(self:index_path())
    if not raw then return nil end
    return gitindex.from_raw(raw)
end

local methods = {
    subpath = subpath,
    object_path = object_path,
    index_path = index_path,
    init = init,
    load_object = load_object,
    save_object = save_object,
    load_index = load_index,
}

local new = function(root)
    return setmetatable({_root = root}, {__index = methods})
end

return {
    new = new,
}
