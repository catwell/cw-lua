# lua-chacha

[![Build Status](https://travis-ci.org/catwell/lua-chacha.png?branch=master)](https://travis-ci.org/catwell/lua-chacha)

## Presentation

This is a Lua C module implementing for the
[ChaCha stream cipher](http://cr.yp.to/chacha.html).

*WARNING*: ChaCha is *just* a stream cipher, not a complete solution for
encryption. Do not use this unless you really understand what you are doing.

## Dependencies

Supports Lua from 5.1 to 5.3 and LuaJIT 2.

Tests depend on [cwtest](https://github.com/catwell/cwtest).
Tests on anything else than Lua 5.3 depend on
[compat53](https://github.com/keplerproject/lua-compat-5.3).

## Usage

The module exposes two functions: `ref_crypt` and `ietf_crypt`.
They both have the same interface:

    f(rounds, key, IV, plaintext, [counter])

`ietf_crypt` corresponds to the ChaCha20 variant described in
[RFC7539 section 2.4](https://tools.ietf.org/html/rfc7539#section-2.4).
`rounds` *must* be 20; `key` must be 32 bytes (256 bits); `IV` must be 12 bytes
(96 bits) and the optional argument `counter` must be 4 bytes (32 bits) if
present.

`ref_crypt` corresponds to the original ChaCha algorithm by D.J. Bernstein.
`rounds` can be one of 20, 12 or 8; `key` can be 16 or 32 bytes
(128 or 256 bits); `IV` must be 8 bytes (64 bits) and the optional argument
`counter` must be 8 bytes (64 bits) if present.

See chacha.test.lua for more.

## Copyright

- Copyright (c) 2015 Pierre Chapuis

The original ChaCha implementation was released under the Public Domain
by D.J. Bernstein.
