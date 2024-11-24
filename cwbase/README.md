# cwbase

## Presentation

cwbase can convert any numeric base to and from big integers. This means
it can be used to convert any base to another base as well.

This code is deprecated in favor of my pure Lua module,
[base2base](https://github.com/catwell/base2base).

## Dependencies

You need a bignum library. If you do not provide one, cwbase will use
[lbc](http://webserver2.tecgraf.puc-rio.br/~lhf/ftp/lua/#lbc).

This repository includes tedbigint, a pure Lua bignum library modified
to be compatible with cwbase. Note that tedbigint is *not* installed
by the cwbase rockspec (lbc is).

The test suite requires [cwtest](https://github.com/catwell/cwtest).

## Usage

### Convert from a base to a bignum

    local cwbase = require "cwbase"
    local b36 = cwbase.base36()
    print(b36:to_bignum("hello")) -- 29234652
    print(b36:from_bignum(54903217)) -- world

### Binary is base256

    local bin, hex = cwbase.base256(), cwbase.base16()

    local bin_to_hex = function(x)
        return hex:from_bignum(bin:to_bignum(x))
    end

    local hex_to_bin = function(x)
        return bin:from_bignum(hex:to_bignum(x))
    end

### Use another bignum library

For now, cwbase is only tested with lbc, lmapm and tedbigint.
It may well work with other libraries though.

    local b36 = cwbase.base36(require "mapm") -- for use with mapm
    local b36 = cwbase.base36(require "tedbigint") -- for use with tedbigint

### Use your own alphabet

    local my_b36 = cwbase.converter("0123456789ABCDEF")
    print(b36:from_bignum(42)) -- 2A

## Copyright

Copyright (c) Pierre Chapuis
