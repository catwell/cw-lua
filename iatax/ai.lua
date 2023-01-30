local util = require "util"
local new_state = (require "state").new

local _dummy = function(...) end

local move = function(self, state)
    local allowed = state:allowed_moves(self.color)
    local s = new_state()
    local best_score, best_moves = -10, {}
    for _, m in ipairs(allowed) do
        state:copy(s)
        local n1 = s:play(self.color, m.from, m.to)
        s.set = _dummy -- only compute the score
        local n2 = -10
        for _, m2 in ipairs(s:allowed_moves(self.opponent)) do
            n2 = math.max(n2, s:play(self.opponent, m2.from, m2.to))
        end
        s.set = nil
        if n1 - n2 == best_score then
            best_moves[#best_moves+1] = m
        elseif n1 - n2 > best_score then
            best_score = n1 - n2
            best_moves = {m}
        end
    end
    return best_moves[math.random(1, #best_moves)]
end

local mt = { __index = {
    move = move,
} }

local new = function(color)
    local self = {
        color = color,
        opponent = util.opponent(color),
    }
    return setmetatable(self, mt)
end

return {
    new = new,
}
