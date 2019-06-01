# Fengari + Vue + LuaCC example

This is a sample project showing how to use the [CDN version of Vue](https://vuejs.org/v2/guide/installation.html#CDN) with [fengari-web](https://github.com/fengari-lua/fengari-web) and [LuaCC](https://github.com/mihacooper/luacc).

## How to use this?

- Edit the Lua source files in `src/` however you like it, as long as you keep a `main.lua` file.
- Edit the files in `static` however you like it as well.
- Run `./script/build.sh`. It will download dependencies the first time it is run.
- Output will be in `dist`. You can use something like [simple-http-server](https://github.com/TheWaWaR/simple-http-server) to try it out. Running it out of a directory will not work because of CORS.

## Possible improvements

- Use [Tup](http://gittup.org/tup/) instead of a shell script to build, get hot reloading for free.
- Use separate files for templates to get syntax highlighting.
