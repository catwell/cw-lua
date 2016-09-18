# itc.lua

[![Build Status](https://travis-ci.org/catwell/itc.lua.png?branch=master)](https://travis-ci.org/catwell/itc.lua)

## Presentation

This is a Lua implementation of Interval Tree Clocks, according to
[the paper](http://gsd.di.uminho.pt/members/cbm/ps/itc2008.pdf):

    Paulo Sérgio Almeida, Carlos Baquero and Victor Fonte
    Interval Tree Clocks: A Logical Clock for Dynamic Systems
    In OPODIS '08 - Proceedings of the 12th International Conference on Principles of Distributed Systems

## Dependencies

None except Lua 5.3.

Tests require [cwtest](https://github.com/catwell/cwtest)
and [base2base](https://github.com/catwell/base2base).

## Usage

```lua
local itc = require "itc"
local s1 = itc.stamp.new() -- create a new stamp
local s2 = s1:fork() -- fork into two
s2:event() -- something happened on 2
s1:join(s2) -- merge back into s1
-- using s2 would raise an error from now on
local bin = s1:encode() -- a compact string representing s1
print(#bin) -- '2'
s1 = itc.stamp.decode(bin) -- convert back to a stamp
print(s1:repr()) -- [1, (0, 0, 1)]
s2 = s1:fork() -- fork again
s1:event() -- something happened on 1
local p = s1:peek() -- read-only copy of 1
s2:join(p) -- merge changes (causality), but 1 is still alive
print(s2:repr()) -- [(0, 1), 1]
```

## Copyright

- Copyright (c) 2016 Pierre Chapuis
