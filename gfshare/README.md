# gfshare

Toy [Teal](https://github.com/teal-language/tl) implementation of [gfshare](https://github.com/jcushman/libgfshare).

*Do not use* the split function as is, this code uses the Lua random generator which is not cryptographic.

To run the tests you will need [base2base](https://github.com/oploadk/base2base).

An easy way to run this is to use [localua](https://loadk.com).

```bash
curl https://loadk.com/localua.sh -O
sh localua.sh .lua
./.lua/bin/luarocks install tl
./.lua/bin/luarocks install base2base
./.lua/bin/tl run gfshare.test.tl
```
