--- Helpers

local function is_valid_js_key (k)
    return type(k) == "string" or js.typeof(k) == "symbol"
end

local function Object (t)
    local r = js.new(js.global.Object)
    for k, v in pairs(t) do
        assert(is_valid_js_key(k))
        r[k] = v
    end
    return r
end

--- / Helpers

local js = require "js"
local fmt = string.format

local pixi = js.global.PIXI
local document = js.global.document

local mode = "canvas"
if pixi.utils:isWebGLSupported() then
    mode = "WebGL"
end
pixi.utils:sayHello(mode)

local app_width, app_height = 800, 600
local app = js.new(pixi.Application, Object {
    width = app_width, height = app_height,
})
app.renderer.backgroundColor = 0x061639

local world = {}
local listeners = {}
local keys = {}

local function game_loop (_, dt)
    local cat = world.cat

    cat.vx = (keys.ArrowLeft and -5 or 0) + (keys.ArrowRight and 5 or 0)
    cat.vy = (keys.ArrowUp and -5 or 0) + (keys.ArrowDown and 5 or 0)

    cat.x = cat.x + (cat.vx * dt)
    cat.y = cat.y + (cat.vy * dt)
end

function listeners.keydown (_, ev)
    keys[ev.key] = true
end

function listeners.keyup (_, ev)
    keys[ev.key] = nil
end

local function setup ()
    local cat = js.new(pixi.Sprite, pixi.loader.resources.cat.texture)
    cat.anchor.x, cat.anchor.y = 0.5, 0.5
    cat.x, cat.y = app_width // 2, app_height // 2
    cat.vx, cat.vy = 0, 0

    local tileset = pixi.loader.resources.tileset.texture
    local rocket_rect = js.new(pixi.Rectangle, 192, 128, 64, 64)
    tileset.frame = rocket_rect
    local rocket = js.new(pixi.Sprite, tileset)
    rocket.x, rocket.y = 32, 32

    app.stage:addChild(cat)
    app.stage:addChild(rocket)

    world.cat, world.rocket = cat, rocket

    js.global:addEventListener("keydown", listeners.keydown)
    js.global:addEventListener("keyup", listeners.keyup)

    app.ticker:add(game_loop)
end

pixi.loader
    :add("cat", "images/cat.png")
    :add("tileset", "images/tileset.png")
    :load(setup)

document.body:appendChild(app.view)
