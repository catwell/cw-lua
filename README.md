# Catwell's Lua playground

This repository is used to store the various Open Source tools,
algorithms and libraries I write in Lua (or rather LuaJIT + FFI)
that do not deserve their own repository.

These are mostly unmaintained prototypes and ideas I gave up on.
Projects I become more serious about graduate to their own repositories.

## Maintained (somewhat)

If you send me a bug report on one of those projects,
I will at least try to give you an answer. I may update
some of them.

- sha256: a SHA-256 implementation in pure LuaJIT+FFI.
- crdt: implementation of some Conflict-Free Replicated Data Types in Lua.
- deque: simple deque implementation (similar to the lists used in fakeredis).
- bimap: mirrored map implementation.
- cwbase: a base-to-base converter.

## Unmaintained

I am unlikely to work again on any of those projects.

- lualua: an unfinished implementation of Lua 5.2 in LuaJIT.
- luajit-msgpack: LuaJIT FFI-based module for MessagePack.
- lua-pipe: syntax experiment, Lua version of Pipe in Python.
- lua-zerorpc: [ZeroRPC](http://zerorpc.dotcloud.com/) implementation.
- nsqc: a [NSQ](http://nsq.io) client.

## Sample code

Not really tools, but rather small examples of how to do some things.

- cwtools: a small collection of useful functions
- concurrent-dotproduct: a simple ConcurrentLua example (outdated)
- unix: luaposix sample code (and C counterparts)
- tcpchat: simple TCP chat with LuaSocket

## Graduated

- [fakeredis](https://github.com/catwell/fakeredis):
a Redis mock (same interface as redis-lua).
- [iris](https://github.com/catwell/iris-lua):
an [Iris](http://iris.karalabe.com/) client.
