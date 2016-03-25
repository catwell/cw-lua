local util = require "util"
local all_tiles = util.all_tiles
local distance = util.distance
local neighborhood = util.neighborhood
local PAWN = util.PAWN

local set = function(self, color, x, y)
    if type(x) == "table" then x, y = x[1], x[2] end
    self[x][y] = color
end

local get = function(self, x, y)
    if type(x) == "table" then x, y = x[1], x[2] end
    return self[x][y]
end

local copy = function(self, dest)
    for x, y in all_tiles() do dest[x][y] = self[x][y] end
end

local pawn_counts = function(self)
    local w, b = 0, 0
    for x, y in all_tiles() do
        if self[x][y] == PAWN.WHITE then
            w = w + 1
        elseif self[x][y] == PAWN.BLACK then
            b = b + 1
        end
    end
    return w, b
end

local play = function(self, color, from, to, d)
    local opponent = util.opponent(color)
    d = d or distance(from, to)
    assert(d > 0 and d <= 2)
    assert(self:get(from) == color)
    assert(not self:get(to))
    local s = 1
    if d == 2 then
        self:set(nil, from)
        s = s - 1
    end
    for px, py in neighborhood(1, to) do
        if self:get(px, py) == opponent then
            self:set(color, px, py)
            s = s + 1
        end
    end
    self:set(color, to)
    return s
end

local all_tiles_with_color = function(self, color)
    local it = all_tiles()
    return function()
        while true do
            local x, y = it()
            if x then
                if self:get(x, y) == color then return x, y end
            else return nil end
        end
    end
end

local allowed_moves = function(self, color)
    local t = {}
    for xt, yt in all_tiles_with_color(self, nil) do
        for xf, yf in neighborhood(2, xt, yt) do
            if self:get(xf, yf) == color then
                t[#t+1] = {from = {xf, yf}, to = {xt, yt}}
            end
        end
    end
    return t
end

local can_play = function(self, color)
    -- very inefficient :)
    return #self:allowed_moves(color) > 0
end

local mt = { __index = {
    get = get,
    set = set,
    copy = copy,
    pawn_counts = pawn_counts,
    play = play,
    all_tiles_with_color = all_tiles_with_color,
    allowed_moves = allowed_moves,
    can_play = can_play,
} }

local new = function()
    local self = {{}, {}, {}, {}, {}, {}, {}}
    return setmetatable(self, mt)
end

return {
    new = new,
}
