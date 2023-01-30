# MirrorFS

## Presentation

MirrorFS is a Lua module that implements a FUSE mirroring a directory.

It can be useful as an example of how to use [Flu](http://piratery.net/flu/),
but it could also have creative uses.

## Dependencies

MirrorFS depends on [Flu](http://piratery.net/flu/) and
[luaposix](https://github.com/luaposix/luaposix).

It is only tested on Linux with Lua 5.3.

## Usage

Check out the examples in the `examples/` directory.

#### Starting a filesystem

    local fs = mirrorfs.new(root, mountpoint)
    fs:main()

`root` must be an absolute path (i.e. start with `/`).

#### Logging operations

`mirrorfs` can log operations and their results. To log to a file, just
set `fs.logfile` before starting the filesystem. You can also override
the `fs.log` method whose signature is `log(self, ...)`, where `...` are the
same arguments as `string.format`.

#### Implementing handlers

To modify the behavior of MirrorFS, you need to implement handlers for
filesystem calls. They have the same interface as in Flu, except that
they take the filesystem object as their first argument and that the `path`
argument is already prefixed by the mirrored path.

To override a handler, just assign it to the corresponding key in the
filesystem object:

    fs.release = function(self, path, fi)
        ...
    end

To unset a handler, just call the `unset_handler` method:

    fs:unset_handler("unlink")

Check out the `chickenfs` example.

#### Making calls fail

To make a handler return a POSIX error, the easiest solution is to use
`mirrorfs.fail` with a string or a number representing a POSIX error code:

    -- those two lines do the same thing
    mirrorfs.fail("ENOMEM")
    mirrorfs.fail(12)

MirrorFS also provides two helpers: `check` that behaves like `assert` but
with `fail` instead of `error` and `pcheck` which is used to check the return
value of most luaposix calls.

If you raise a normal error in an handler, it will be interpreted as `EPERM`.

#### Descriptors

Some FUSE handlers (`open`, `readdir`, etc) interact with file or directory
descriptors. The filesystem instance has three methods to manage their state:
`push_descriptor`, `get_descriptor` and `clear_descriptor`. If you need to
use them, read the implementation of the default handlers in `mirrorfs.lua`
and use it as an example.

## Copyright

- Copyright (c) 2015-2016 Pierre Chapuis
