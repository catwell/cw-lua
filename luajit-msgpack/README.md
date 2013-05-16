# luajit-msgpack

*NOTE:* This is unmaintained.
[luajit-msgpack-pure](https://github.com/catwell/luajit-msgpack-pure)
is better in every respect, use it.

## Presentation

LuaJIT FFI-based module for MessagePack. Tested on Linux and Mac OS X.

luajit-msgpack requires a small C library because of the interface of
MessagePack. In practice there is little reason not to use
[luajit-msgpack-pure](https://github.com/catwell/luajit-msgpack-pure),
which does not have that requirement and similar performance, instead.

## Alternatives

 - [luajit-msgpack-pure](https://github.com/catwell/luajit-msgpack-pure)
   (pure LuaJIT)
 - [lua-msgpack](https://github.com/kengonakajima/lua-msgpack) (pure Lua)
 - [lua-msgpack-native](https://github.com/kengonakajima/lua-msgpack-native)
   (Lua-specific C implementation)
 - [MPLua](https://github.com/nobu-k/mplua) (binding)

## Usage

See tests/test.lua.
