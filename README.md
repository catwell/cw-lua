# Catwell's Lua playground

This repository is used to store the various Open Source tools,
algorithms and libraries I write in Lua (or rather LuaJIT + FFI)
that do not deserve their own repository.

These are mostly unmaintained prototypes and ideas I gave up on.
Projects I become more serious about graduate to their own repositories.

## Early stage

I just started those. They are just experiments for now,
although some may become real projects someday.

- iris: an [Iris](http://iris.karalabe.com/) client.

## Maintained (somewhat)

If you send me a bug report on one of those projects,
I will at least try to give you an answer. I may update
some of them.

- sha256: a SHA-256 implementation in pure LuaJIT+FFI.
- cwtools: a small collection of useful functions.
- crdt: implementation of some Conflict-Free Replicated Data Types in Lua.
- deque: simple deque implementation (similar to the lists used in fakeredis).
- bimap: mirrored map implementation.

## Unmaintained

I am unlikely to work again on any of those projects.

- lualua: an unfinished implementation of Lua 5.2 in LuaJIT.
- luajit-msgpack: LuaJIT FFI-based module for MessagePack.
- lua-pipe: syntax experiment, Lua version of Pipe in Python.
- lua-zerorpc: [ZeroRPC](http://zerorpc.dotcloud.com/) implementation.
- nsqc: a [NSQ](http://nsq.io) client.

## Graduated

- [fakeredis](https://github.com/catwell/fakeredis): a Redis mock
(same interface as redis-lua).
