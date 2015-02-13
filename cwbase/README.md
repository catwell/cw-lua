# cwbase

## Presentation

cwbase can convert any numeric base to and from big integers. This means
it can be used to convert any base to another base as well.

## Dependencies

You need a bignum library. If you do not provide one, cwbase will use
[lbc](http://webserver2.tecgraf.puc-rio.br/~lhf/ftp/lua/#lbc).

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

For now, cwbase is only tested with lbc and lmapm. It should work with
other libraries though.

    local mapm = require "mapm"
    local b36 = cwbase.base36(mapm)

### Use your own alphabet

    local my_b36 = cwbase.converter("0123456789ABCDEF")
    print(b36:from_bignum(42)) -- 2A

## Copyright

Copyright (c) 2015 Pierre Chapuis
