package = "chacha"
version = "scm-1"

source = {
   url = "git://github.com/catwell/lua-chacha.git",
}

description = {
   summary = "ChaCha stream cipher.",
   detailed = [[
      Lua C module implementing the ChaCha stream cipher
      (http://cr.yp.to/chacha.html) and its version normalized by IETF.
   ]],
   homepage = "http://github.com/catwell/lua-chacha",
   license = "MIT/X11",
}

dependencies = {
   "lua >= 5.1",
}

build = {
   type = "builtin",
   modules = {
      chacha = {
         sources = {"chacha.c", "lchacha.c"},
      },
   },
   copy_directories = {},
}
