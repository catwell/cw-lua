
local all_tiles
do -- tiles iterator
    local _tiles = {}
    for x = 1, 7 do
        for y = 1, 7 do _tiles[#_tiles+1] = {x, y} end
    end
    all_tiles = function()
        local i = 0
        return function()
            i = i + 1
            if _tiles[i] then return unpack(_tiles[i]) end
        end
    end
end

local same_tile = function(a, b)
    return a[1] == b[1] and a[2] == b[2]
end

local distance = function(a, b)
    return math.max(math.abs(a[1] - b[1]), math.abs(a[2] - b[2]))
end

local neighborhood = function(r, x, y)
    if type(x) == "table" then x, y = x[1], x[2] end
    local t = {}
    for i = -r, r do
        for j = -r, r do
            local px, py = x + i, y + j
            if (
                (i ~= 0 or j ~= 0) and
                px > 0 and px < 8 and py > 0 and py < 8
            ) then t[#t+1] = {px, py} end
        end
    end
    local i = 0
    return function()
        i = i + 1
        if t[i] then return t[i][1], t[i][2] end
    end
end

local PAWN = { WHITE = 1, BLACK = 2 }
for k, v in pairs(PAWN) do PAWN[v] = k end

local opponent = function(color)
    return (color == PAWN.WHITE) and PAWN.BLACK or PAWN.WHITE
end

return {
    all_tiles = all_tiles,
    same_tile = same_tile,
    distance = distance,
    neighborhood = neighborhood,
    PAWN = PAWN,
    opponent = opponent,
}
