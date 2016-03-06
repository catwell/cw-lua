package = "etpan"
version = "scm-1"

source = {
   url = "http://github.com/catwell/TODO",
}

description = {
   summary = "libetpan binding",
   detailed = [[
      Binding for LibEtPan, a portable library for email access
      using IMAP, SMTP, POP and NNTP.
   ]],
   -- homepage = "http://github.com/catwell/TODO",
   license = "MIT/X11",
}

dependencies = {
   "lua >= 5.3",
}

build = {
   type = "builtin",
   modules = {
      etpan_ll = {
         sources = {"etpan.c"},
         libraries = { "etpan" },
      },
   },
   copy_directories = {},
}
