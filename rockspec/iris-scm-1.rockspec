package = "iris"
version = "scm-1"

source = {
   url = "git://github.com/catwell/iris-lua.git",
}

description = {
   summary = "Iris client",
   detailed = [[
      A client for Iris (http://iris.karalabe.com/).
   ]],
   homepage = "http://github.com/catwell/iris-lua",
   license = "MIT/X11",
}

dependencies = {
   "lua >= 5.1",
   "luasocket",
}

build = {
   type = "none",
   install = {
      lua = {
         iris = "iris.lua",
      },
   },
   copy_directories = {},
}
