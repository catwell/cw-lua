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

Currently, do not expect this to work with non-default settings or with
MDB files that were not generated on an x64 architecture.

## Dependencies

Exclusively supports Lua 5.3. I have no interest in supporting older Lua-s
or LuaJIT with this project and will not accept pull requests trying to do
so (at least until the module reaches a stable state).

Tests require [cwtest](https://github.com/catwell/cwtest),
[lightningmdb](https://github.com/shmul/lightningmdb)
and [Penlight](https://github.com/stevedonovan/Penlight).

## Usage

Coming later.

## Copyright

- Copyright (c) 2015-2016 Pierre Chapuis
