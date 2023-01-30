#!/bin/bash

cd "$(dirname "$0")/.."

get_deps () {
    rm -rf deps
    mkdir -p deps
    curl -L -o deps/fengari-web.js \
        "https://github.com/fengari-lua/fengari-web/releases/download/v0.1.4/fengari-web.js"
    curl -L -o deps/luacc.lua \
        "https://raw.githubusercontent.com/oploadk/luacc/master/bin/luacc.lua"
}

[ -d deps ] || get_deps
[ -d .tup ] || tup init
tup
