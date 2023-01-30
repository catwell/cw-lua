# bsx

**WARNING: work in progress...**

## Presentation

bsx is a small tool to manage a [Beanstalk](http://kr.github.com/beanstalkd/)
queue manually in a Lua shell.

## Dependencies

bsx depends on [haricot](http://github.com/catwell/haricot).

The sample configuration file depends on
[luajit-msgpack-pure](http://github.com/catwell/luajit-msgpack-pure)
(hence LuaJIT) and [Penlight](http://stevedonovan.github.io/Penlight).

## Usage

    MY_TUBE="mytube" rlwrap luajit -lbsx

Yes, I will document this someday. Maybe.

## Copyright

Copyright (c) 2013 Moodstocks SAS
