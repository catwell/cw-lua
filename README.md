# Catwell's Lua playground

This repository is used to store the various Open Source tools,
algorithms and libraries I write in Lua (or rather LuaJIT + FFI)
that do not deserve their own repository.

These are mostly unmaintained prototypes and ideas I gave up on.
Projects I become more serious about graduate to their own repositories,
and sometimes projects that I stop maintaining end up here.

## Contents

- bimap: mirrored map implementation
- blake2b: a Lua 5.3 implementation of [BLAKE2b](https://blake2.net)
- bsx: a small tool to manage a Beanstalk queue based on Haricot
- concurrent-dotproduct: a simple ConcurrentLua example (outdated)
- crdt: implementation of some Conflict-Free Replicated Data Types in Lua
- cwbase: deprecated in favor of [base2base](https://github.com/catwell/base2base)
- cwscripts: short Lua utility scripts
- cwtools: a small collection of useful functions
- decolonize: Tessel 1 examples using Lua directly (i.e without Colony)
- deque: simple deque implementation (similar to the lists used in fakeredis)
- etpan: incomplete [libetpan](http://www.etpan.org/libetpan.html) binding
- fengari-canvas: an example of how to use a canvas with Fengari
- fengari-pixi: [PixiJS](https://pixijs.com) + Fengari
- vengari-vue-luacc-example: [Vue](https://vuejs.org) + Fengari
- git: toy implementation of parts of Git
- iatax: a LÖVE remake of an old Perl/SDL game I wrote in 2004
- iris-lua: an [Iris](http://iris.karalabe.com/) client
- itc.lua: a Lua implementation of Interval Tree Clocks
- lua-chacha: a C and a pure Lua module implementing the ChaCha stream cipher
- lua-mdb: pure Lua code to read LMDB databases
- lua-mirrorfs: a FUSE filesystem that mirrors a directory (uses [Flu](http://piratery.net/flu))
- lua-pipe: syntax experiment, Lua version of Pipe in Python
- lua-zerorpc: [ZeroRPC](http://zerorpc.dotcloud.com/) implementation
- luajit-msgpack: LuaJIT FFI-based module for MessagePack
- lualua: an unfinished implementation of Lua 5.2 in LuaJIT
- micrograd: a port of [micrograd](https://github.com/karpathy/micrograd)
- nsqc: a [NSQ](http://nsq.io) client
- sha256: a SHA-256 implementation in pure LuaJIT+FFI
- tcpchat: simple TCP chat + Lua interpreter with LuaSocket
- unix: luaposix sample code (and C counterparts)
- wolfram: playing with Wolfram's Basic Form of Models in Teal
