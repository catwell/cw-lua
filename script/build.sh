#!/bin/bash

cd "$(dirname "$0")/.."

list_modules () {
    find src -type f -name *.lua \
        | grep -v 'src/main.lua' \
        | sed 's/^src\///' \
        | sed 's/.lua$//' \
        | sed 's/.init$//' \
        | tr '\n\/' ' .'
}

get_deps () {
    rm -rf deps
    mkdir -p deps
    curl -L -o deps/fengari-web.js \
        "https://github.com/fengari-lua/fengari-web/releases/download/v0.1.4/fengari-web.js"
    curl -L -o deps/luacc.lua \
        "https://raw.githubusercontent.com/oploadk/luacc/master/bin/luacc.lua"
}

prepare_dist () {
    rm -rf dist
    mkdir -p dist
    cp deps/fengari-web.js dist
    cp static/* dist
}

build_lua () {
    luacheck --codes .

    lua deps/luacc.lua \
        -o dist/index.lua \
        -i src \
        main $(list_modules)
}

[ ! -d deps ] && get_deps
prepare_dist
build_lua
