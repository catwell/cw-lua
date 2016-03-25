local fmt = string.format
local unpack = table.unpack or unpack

local util = require "util"
local all_tiles = util.all_tiles
local same_tile = util.same_tile
local distance = util.distance
local PAWN = util.PAWN

local COLOR = {
    BACKGROUND = { 0, 0, 0, 0 },
    BORDER = { 215, 215, 215, 255 },
    TILE = { 132, 158, 198, 255 },
    BLACK = { 0, 0, 0, 255 },
    WHITE = { 255, 255, 255, 255 },
    SELECTION = { 255, 0, 0, 255 },
}

local reset_dimensions = function(self)
    local width, height = love.graphics.getDimensions()
    local min_d = math.min(width, height)
    self.tile_size = math.floor(min_d / 14) * 2 - 2
    self.size = 7 * (self.tile_size + 2)
    self.top_left = {
        x = math.floor((width - self.size) / 2),
        y = math.floor((height - self.size) / 2),
    }
    self.pawn_radius = math.floor(0.4 * self.tile_size) - 2
    self.pawn_offset = self.tile_size / 2 + 1
    self.selection_radius = math.floor(0.2 * self.tile_size)
    self.too_small = self.pawn_radius < 2
end

local tile_left = function(self, x)
    x = x - 1
    return self.top_left.x + x * (self.tile_size + 2) + 1
end

local tile_top = function(self, y)
    y = y - 1
    return self.top_left.y + y * (self.tile_size + 2) + 1
end

local tile_hit = function(self, pos_x, pos_y)
    for x = 1, 7 do
        local xl = self:tile_left(x)
        local xr = xl + self.tile_size
        if pos_x > xl and pos_x < xr then
            for y = 1, 7 do
                local yt = self:tile_top(y)
                local yb = yt + self.tile_size
                if pos_y > yt and pos_y < yb then
                    return {x, y}
                end
            end
        end
    end
end

local draw_tile = function(self, x, y)
    love.graphics.rectangle(
        "fill",
        self:tile_left(x), self:tile_top(y),
        self.tile_size, self.tile_size
    )
end

local _draw_pawn = function(self, x, y)
    love.graphics.circle(
        "fill",
        self:tile_left(x) + self.pawn_offset,
        self:tile_top(y) + self.pawn_offset,
        self.pawn_radius, 256
    )
end

local draw_pawn = function(self, color, x, y)
    if color then
        love.graphics.setColor(COLOR[PAWN[color]])
        _draw_pawn(self, x, y)
    end
end

local draw_selected = function(self, x, y)
    love.graphics.setColor(COLOR.SELECTION)
    love.graphics.rectangle(
        "line",
        self:tile_left(x), self:tile_top(y),
        self.tile_size, self.tile_size,
        self.selection_radius, self.selection_radius
    )

end

local draw_empty = function(self)
    love.graphics.setColor(COLOR.BORDER)
    love.graphics.rectangle(
        "fill",
        self.top_left.x, self.top_left.y,
        self.size, self.size
    )
    love.graphics.setColor(COLOR.TILE)
    for x, y in all_tiles() do self:draw_tile(x, y) end
end

local BOARD = {
    reset_dimensions = reset_dimensions,
    tile_left = tile_left,
    tile_top = tile_top,
    tile_hit = tile_hit,
    draw_tile = draw_tile,
    draw_pawn = draw_pawn,
    draw_selected = draw_selected,
    draw_empty = draw_empty,
}

---

local game_set = function(self, color, x, y)
    self.state:set(color, x, y)
end

local game_get = function(self, x, y)
    return self.state:get(x, y)
end

local game_draw_pawns = function(self)
    for x, y in all_tiles() do
        self.board:draw_pawn(self:get(x, y), x, y)
    end
end

local game_draw_selected = function(self)
    if self.selected then
        self.board:draw_selected(unpack(self.selected))
    end
end

local game_winner = function(self)
    local w, b = self.state:pawn_counts()
    if w == 0 then
        return PAWN.BLACK
    elseif b == 0 then
        return PAWN.WHITE
    end
end

local game_check_winner = function(self)
    local winner = self:winner()
    if winner then
        print(fmt("%s won", PAWN[winner]))
        os.exit(1)
    end
end

local game_play_ai = function(self)
    local move = self.ai:move(self.state)
    self.state:play(self.OPPONENT, move.from, move.to)
end

local GAME = {
    state = (require "state").new(),
    board = BOARD,
    set = game_set,
    get = game_get,
    draw_pawns = game_draw_pawns,
    draw_selected = game_draw_selected,
    winner = game_winner,
    check_winner = game_check_winner,
    play_ai = game_play_ai,
    PLAYER = PAWN.WHITE,
    OPPONENT = PAWN.BLACK,
}

---

love.mousepressed = function(x, y, button, is_touch)
    if not GAME.current_player then return end
    local tile = BOARD:tile_hit(x, y)
    if not tile then return end
    local color = GAME:get(tile)
    if color == GAME.PLAYER then
        if GAME.selected and same_tile(GAME.selected, tile) then
            GAME.selected = nil
        else
            GAME.selected = tile
        end
    elseif GAME.selected and not color then
        local d = distance(GAME.selected, tile)
        if d <= 2 then
            GAME.current_player = false
            GAME.state:play(GAME.PLAYER, GAME.selected, tile)
            GAME.selected = nil
            GAME:check_winner()
            if GAME.state:can_play(GAME.OPPONENT) then repeat
                GAME:play_ai()
                GAME:check_winner()
            until GAME.state:can_play(GAME.PLAYER) end
            GAME.current_player = true
        end
    end
end

love.load = function()
    BOARD:reset_dimensions()
    assert(not BOARD.top_small)
    GAME:set(PAWN.WHITE, 1, 7)
    GAME:set(PAWN.WHITE, 7, 1)
    GAME:set(PAWN.BLACK, 1, 1)
    GAME:set(PAWN.BLACK, 7, 7)
    GAME.ai = (require "ai").new(GAME.OPPONENT)
    GAME.current_player = true
end

love.draw = function()
    love.graphics.clear(COLOR.BACKGROUND)
    BOARD:draw_empty()
    GAME:draw_pawns()
    GAME:draw_selected()
end
