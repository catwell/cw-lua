local js = require "js"
local fmt = string.format

local canvas = js.global.document:getElementById("canvas")
local ctx = canvas:getContext("2d")

local function textfit (text, width, max, min)
    for s = max, min, -1 do
        ctx.font = fmt("%dpx arial", s)
        text = ctx:measureText(text)
        if text.width <= width then
            return s
        end
    end
    return min
end

local function within (rect, x, y)
    return (
        x >= rect.x and y >= rect.y and
        x <= (rect.x + rect.w) and (y <= rect.y + rect.h)
    )
end

ctx.fillStyle = "blue"
ctx:fillRect(0, 0, canvas.width, canvas.height)

local text = "Hello Fengari + Canvas World!"
local margin1, margin2 = 10, 2
local max_w = canvas.width - 2 * margin1
local text_h = textfit(text, max_w, 100, 10)

local rect = {
    x = margin1 - margin2,
    y = canvas.height // 2 - text_h - margin2,
    w = max_w + 2 * margin2,
    h = text_h + 2 * margin2,
}

ctx.fillStyle = "green"
ctx:fillRect(rect.x, rect.y, rect.w, rect.h)

ctx.fillStyle = "red"
ctx.textBaseline = "bottom"
ctx:fillText(text, margin1, canvas.height // 2, max_w)

function canvas:onclick (event)
    if within(rect, event.offsetX, event.offsetY) then
        js.global:alert("Clicked!")
    end
end
