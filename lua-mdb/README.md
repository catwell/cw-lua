# lua-mdb

## Presentation

lua-mdb is a pure Lua module to read data.mdb files (from
[LMDB](http://symas.com/mdb/), not Microsoft Access).

If you actually want to use LMDB with Lua, this is probably not the module
you are looking for. Check out
[lightningmdb](https://github.com/shmul/lightningmdb).

This code is more a way for me to learn the internals of LMDB than anything
practical. Long term, it could be useful to debug broken .mdb files or read
them on another architecture (the MDB format is architecture-dependent).

## Dependencies

Exclusively supports Lua 5.3. I have no interest in supporting older Lua-s
or LuaJIT with this project and will not accept pull requests trying to do
so (at least until the module reaches a stable state).

Tests require [cwtest](https://github.com/catwell/cwtest),
[lightningmdb](https://github.com/shmul/lightningmdb)
and [Penlight](https://github.com/stevedonovan/Penlight).

## Usage

### mdb_dump.lua

`mdb_dump.lua` is a re-implementation of the mdb_dump tool from LMDB. It can
be used as an example of how to use the library. You can pass the number of
bits of the platform on which the database was generated as the second argument,
otherwise it will try to use the platform the code runs on.

### The library

    local reader = require "lua-mdb.reader"
    local r = reader.new("path/to/data.mdb")
    print(r:get("some_key"))

## Copyright

- Copyright (c) Pierre Chapuis
