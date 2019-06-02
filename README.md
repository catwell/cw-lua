# Fengari + Vue + LuaCC example

This is a sample project showing how to use the [CDN version of Vue](https://vuejs.org/v2/guide/installation.html#CDN) with [fengari-web](https://github.com/fengari-lua/fengari-web) and [LuaCC](https://github.com/mihacooper/luacc).

## Build system

### Build dependencies

- Lua 5.3
- [tup](http://gittup.org/tup)
- [luacheck](https://github.com/mpeterv/luacheck)

### Bootstrapping

The first time you use this project on a new machine, run `./script/bootstrap.sh`. This will download dependencies and initialize the build system.

### Building

Run `tup` to build once. Run `tup monitor -f -a` to get hot code reloading.

### Tupfile

All Lua files and temlates must be explicitly listed in `Tupfile.lua`. `main.lua` should always be first. This is necessary because Tup does not support recursive globbing.

You should not need to touch `Tuprules.lua`.

### Output

Output will be in `dist`. You can use something like [simple-http-server](https://github.com/TheWaWaR/simple-http-server) to try it out. Running it out of a directory will not work because of CORS.

## Possible improvements

- Demonstrate sub-components.
- Demonstrate routing.
- Demonstrate Web Components usage.
- CSS encapsulation?
