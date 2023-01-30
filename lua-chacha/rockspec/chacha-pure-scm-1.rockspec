package = "chacha-pure"
version = "scm-1"

source = { url = "git://github.com/catwell/lua-chacha.git" }

description = {
   summary = "ChaCha stream cipher, pure Lua version.",
   detailed = [[
      Pure Lua module implementing the ChaCha stream cipher
      (http://cr.yp.to/chacha.html) and its version normalized by IETF.
   ]],
   homepage = "http://github.com/catwell/lua-chacha",
   license = "MIT/X11",
}

dependencies = { "lua >= 5.3" }

build = {
    type = "none",
    install = { lua = { ["chacha-pure"] = "chacha-pure.lua" } },
    copy_directories = {},
}
