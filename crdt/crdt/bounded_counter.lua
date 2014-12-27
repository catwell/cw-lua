-- Bounded Counter

-- This is a PN counter that cannot go below zero.
-- The `decr` method returns true if successful and `false` if it failed.
-- The implementation is simple but probably very wasteful.
-- Not inspired by a paper, I thought about that one on my own
-- (but I probably reinvented somebody's wheel).

-- The idea is that rebalancing can always increase another node's
-- token counter if it decreases the counter of the current node
-- by the same amount. Increasing the global counter produces tokens
-- and decreasing it consumes them.

-- The logic assumes a node which tried to decrement but could not is more
-- likely to try again, and the "hints" table is used to bias rebalancing
-- towards favoring those nodes.

local PNCounter = require "pn_counter"
local GBoolean = require "g_boolean"
local utils = require "utils"

--- METHODS

local decr = function(self)
    if self.tokens[self.node]:value() < 1 then
        self.hints[self.node]:set(true)
        return false
    end
    self.ctr:decr(1)
    self.tokens[self.node]:decr(1)
    return true
end

local incr = function(self)
    self.hints[self.node]:set(false)
    self.ctr:incr(1)
    self.tokens[self.node]:incr(1)
end

local merge = function(self, other)
    self.ctr:merge(other.ctr)
    for k,v in pairs(other.tokens) do
        self.tokens[k]:merge(v)
    end
    for k,v in pairs(other.hints) do
        self.hints[k]:merge(v)
    end
    if self.tokens[self.node]:value() > 0 then
        self.hints[self.node]:set(false)
    end
end

local rebalance = function(self)

    local r = false
    local self_tk = self.tokens[self.node]:value()

    if self.tk == 0 then return r end

    local min_tk, min_node, n = self_tk, self.node, 0
    local tk
    for k,v in pairs(self.tokens) do
        tk, n = v:value(), n + 1
        if (k ~= self.node) and (tk < min_tk) then
            if tk == 0 and self.hints[k]:value() then
                self.tokens[self.node]:decr(1)
                self.tokens[k]:incr(1)
                self_tk = self_tk - 1
                self.hints[k]:set(false)
                r = true
                if self.tk == 0 then return r end
            end
            min_tk, min_node = tk, k
        end
    end

    local avg_tk = self.ctr:value() / n

    while self_tk > avg_tk do
        local d = math.floor(math.min(avg_tk - min_tk, self_tk - avg_tk))
        if d == 0 then break end
        assert(min_node ~= self.node)
        r = true
        self.tokens[self.node]:decr(d)
        self_tk = self_tk - d
        self.tokens[min_node]:incr(d)
        min_tk, min_node = self_tk, self.node
        for k,v in pairs(self.tokens) do
            tk = v:value()
            if (k ~= self.node) and (tk < min_tk) then
                min_tk, min_node = tk, self.node
            end
        end
    end

    return r

end

local value = function(self)
    return self.ctr:value()
end

local methods = {
    decr = decr, -- (qty) -> !
    incr = incr, -- (qty) -> bool
    merge = merge, -- (other) -> !
    value = value, -- () -> number
    rebalance = rebalance, -- () -> bool
}

--- CLASS

local new = function(node)
    local r = {
        node = node,
        ctr = PNCounter.new(node),
        tokens = utils.defmap2(PNCounter.new),
        hints = utils.defmap2(GBoolean.new),
    }
    assert(r.tokens[node]) -- force registration of self
    return setmetatable(r, {__index = methods})
end

return {
    new = new, -- (node) -> Bounded Counter
}
