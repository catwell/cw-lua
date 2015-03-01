package = "cwbase"
version = "scm-1"

source = {
   url = "git://github.com/catwell/cw-lua.git",
}

description = {
   summary = "A base-to-base converter",
   detailed = [[
      cwbase lets you convert between numeric bases
      using a bignum library.
   ]],
   homepage = "http://github.com/catwell/cw-lua",
   license = "MIT/X11",
}

dependencies = {
   "lua >= 5.1",
   "lbc", -- lmapm also supported
}

build = {
   type = "none",
   install = {
      lua = {
         cwbase = "cwbase/cwbase.lua",
      },
   },
   copy_directories = {},
}
