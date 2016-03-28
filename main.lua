local unpack = table.unpack or unpack

local util = require "util"
local all_tiles = util.all_tiles
local same_tile = util.same_tile
local distance = util.distance
local PAWN = util.PAWN

local COLOR = {
    BACKGROUND = { 128, 128, 128, 0 },
    BORDER = { 215, 215, 215, 255 },
    TILE = { 132, 158, 198, 255 },
    BLACK = { 0, 0, 0, 255 },
    WHITE = { 255, 255, 255, 255 },
    SELECTION = { 255, 0, 0, 255 },
}

local SCREEN = {home = {}, game = {}}

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
    elseif w + b == 7 * 7 then
        return w > b and PAWN.WHITE or PAWN.BLACK
    end
end

local game_check_winner = function(self)
    local winner = self:winner()
    if winner then
        if winner == self.PLAYER then
            SCREEN.home.text = "You won. New game?"
        else
            SCREEN.home.text = "You lost. New game?"
        end
        self.screen = SCREEN.home
    end
    return winner
end

local game_play_ai = function(self)
    local move = self.ai:move(self.state)
    self.state:play(self.OPPONENT, move.from, move.to)
end

local game_set_player = function(self, color)
    self.PLAYER = color
    self.OPPONENT = util.opponent(color)
    self.ai = (require "ai").new(self.OPPONENT)
    self.state = (require "state").new()
    self.allow_input = true
    self.selected = nil
end

local GAME = {
    board = BOARD,
    set = game_set,
    get = game_get,
    draw_pawns = game_draw_pawns,
    draw_selected = game_draw_selected,
    winner = game_winner,
    check_winner = game_check_winner,
    play_ai = game_play_ai,
    set_player = game_set_player,
}

---

SCREEN.game.load = function(self)
    BOARD:reset_dimensions()
    assert(not BOARD.top_small)
end

SCREEN.game.draw = function(self)
    BOARD:draw_empty()
    GAME:draw_pawns()
    GAME:draw_selected()
end

SCREEN.game.mousepressed = function(self, x, y, ...)
    if not GAME.allow_input then return end
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
            GAME.allow_input = false
            GAME.state:play(GAME.PLAYER, GAME.selected, tile)
            GAME.selected = nil
            if GAME:check_winner() then return end
            if GAME.state:can_play(GAME.OPPONENT) then repeat
                GAME:play_ai()
                if GAME:check_winner() then return end
            until GAME.state:can_play(GAME.PLAYER) end
            GAME.allow_input = true
        end
    end
end

SCREEN.home.load = function(self)
    self.logo = love.graphics.newImage("iatax_logo.png")
    self.font = love.graphics.newFont(200)
    local fh = self.font:getHeight()
    local iw, ih = self.logo:getDimensions()
    local sw, sh = love.graphics.getDimensions()
    self.scale_factor = 0.4 * math.min(sw/iw, sh/ih)
    self.logo_pos = { x = math.floor(0.3 * sw), y = math.floor(0.1 * sh)}
    local hh = math.ceil(0.1 * sh + self.scale_factor * ih)
    local bottom_h = sh - hh
    self.txt_h, self.txt_top = math.floor(0.3 * bottom_h), hh
    local fw = self.font:getWidth("You lost. New game?")
    self.txt_font_scale_factor = math.min(0.8 * sw / fw, self.txt_h * fh)
    local bh = math.floor(0.6 * (bottom_h - self.txt_h))
    self.btn_top = hh + self.txt_h + math.floor(bh / 3)
    self.btn_w, self.btn_h = math.floor(0.35 * sw), bh
    self.btn1_x = math.floor(0.1 * sw)
    self.btn2_x = 2 * self.btn1_x + self.btn_w
    self.btn_radius = math.floor(0.2 * bh)
    fw = math.max(
        self.font:getWidth("Play White"),
        self.font:getWidth("Play Black")
    )
    self.btn_font_scale_factor = 0.8 * self.btn_w / fw
    local bfh = fh * self.btn_font_scale_factor
    self.btn_font_top = math.floor(self.btn_top + (bh - bfh) / 2)
    self.btn_font_offset = math.floor(0.1 * self.btn_w)
    self.text = "New game?"
end

SCREEN.home.draw = function(self)
    love.graphics.setColor(COLOR.WHITE)
    love.graphics.draw(
        self.logo, self.logo_pos.x, self.logo_pos.y,
        0, self.scale_factor, self.scale_factor
    )
    love.graphics.rectangle(
        "fill",
        self.btn1_x, self.btn_top,
        self.btn_w, self.btn_h,
        self.btn_radius, self.btn_radius
    )
    love.graphics.rectangle(
        "fill",
        self.btn2_x, self.btn_top,
        self.btn_w, self.btn_h,
        self.btn_radius, self.btn_radius
    )
    love.graphics.setColor(COLOR.BLACK)
    love.graphics.setFont(self.font)
    local sw = love.graphics.getDimensions()
    local tw, tf = self.font:getWidth(self.text), self.txt_font_scale_factor
    local txt_hpad = (self.txt_h - tf * self.font:getHeight()) / 2
    love.graphics.print(
        self.text, (sw - tf * tw) / 2, self.txt_top + txt_hpad,
        0, tf, tf
    )
    love.graphics.print(
        "Play White", self.btn1_x + self.btn_font_offset, self.btn_font_top,
        0, self.btn_font_scale_factor, self.btn_font_scale_factor
    )
    love.graphics.print(
        "Play Black", self.btn2_x + self.btn_font_offset, self.btn_font_top,
        0, self.btn_font_scale_factor, self.btn_font_scale_factor
    )
end

SCREEN.home.mousepressed = function(self, x, y, ...)
    if y < self.btn_top or y > self.btn_top + self.btn_h then return end
    if x >= self.btn1_x and x <= self.btn1_x + self.btn_w then
        GAME:set_player(PAWN.WHITE)
    elseif x >= self.btn2_x and x <= self.btn2_x + self.btn_w then
        GAME:set_player(PAWN.BLACK)
    else return end
    GAME.screen = SCREEN.game
end

love.mousepressed = function(x, y, ...)
    GAME.screen:mousepressed(x, y, ...)
end

love.load = function()
    SCREEN.home:load()
    SCREEN.game:load()
    GAME.screen = SCREEN.home
end

love.draw = function()
    love.graphics.clear(COLOR.BACKGROUND)
    GAME.screen:draw()
end
