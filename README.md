# Catwell's Lua playground

This repository is used to store the various Open Source tools,
algorithms and libraries I write in Lua (or rather LuaJIT + FFI)
that do not deserve their own repository.

These are mostly unmaintained prototypes and ideas I gave up on.
Projects I become more serious about graduate to their own repositories.

## Contains:

- sha256: a SHA-256 implementation in pure LuaJIT+FFI.
- lua-pipe: syntax experiment, Lua version of Pipe in Python.
- cwtools: a small collection of useful functions.
- lualua: an unfinished implementation of Lua 5.2 in LuaJIT.
- luajit-msgpack: LuaJIT FFI-based module for MessagePack.
- ecds-lua: implementation of some Eventually-Consistent Data Structures.
- lua-zerorpc: [ZeroRPC](http://zerorpc.dotcloud.com/) implementation.
- deque: simple deque implementation (similar to lists in fakeredis).

## Graduated:

- [fakeredis](https://github.com/catwell/fakeredis): a Redis mock
(same interface as redis-lua).
