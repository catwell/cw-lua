package = "mirrorfs"
version = "1.0-1"

source = {
   url = "git://github.com/catwell/lua-mirrorfs.git",
   branch = "v1.0",
}

description = {
   summary = "A FUSE mirroring a directory.",
   detailed = [[
      Module that implements a FUSE mirroring a directory.
   ]],
   homepage = "http://github.com/catwell/lua-mirrorfs",
   license = "MIT/X11",
}

dependencies = { "lua >= 5.3", "luaposix", "flu" }

build = {
   type = "none",
   install = {
      lua = { mirrorfs = "mirrorfs.lua", },
   },
   copy_directories = {},
}
