-- This version doesn't support rules depending on more than one relation.
-- https://www.wolframphysics.org/technical-introduction/basic-form-of-models/rules-depending-on-more-than-one-relation/#p-84

local type Value = integer
local type Variable = integer
local type RelationValue = {Value}
local type RelationVariable = {Variable}
local type State = {RelationValue}
local type Mapping = {Variable:Value}
local record Rule
    from: {RelationVariable}
    to: {RelationVariable}
end

local function state_repr (state: State) : string
    local r = {}
    for i = 1, #state do
        r[i] = '{' .. table.concat(state[i], ', ') .. '}'
    end
    return '{' .. table.concat(r, ', ') .. '}'
end

local function match (val: RelationValue, var: RelationVariable) : Mapping
    if #val ~= #var then return nil end
    local r: Mapping = {}
    for i = 1, #val do
        if r[var[i]] then
            if r[var[i]] ~= val[i] then
                return nil
            end
        else
            r[var[i]] = val[i]
        end
    end
    return r
end

local function substitute (var: RelationVariable, map: Mapping, new_id: function(): integer) : RelationValue
    local r: RelationValue = {}
    for i = 1, #var do
        if not map[var[i]] then
            map[var[i]] = new_id()
        end
        r[i] = map[var[i]]
    end
    return r
end

local function state_apply_rule_simple (state: State, rule: Rule) : State
    assert(#rule.from == 1) -- see top comment
    local r: State = {}
    local new_id = (function() : function(): integer
        local n = 0
        for i = 1, #state do
            for j = 1, #state[i] do
                if state[i][j] > n then
                    n = state[i][j]
                end
            end
        end
        return function() : integer
            n = n + 1
            return n
        end
    end)()
    for i = 1, #state do
        local m = match(state[i], rule.from[1])
        if m then
            for j = 1, #rule.to do
                table.insert(r, substitute(rule.to[j], m, new_id))
            end
        else
            table.insert(r, state[i])
        end
    end
    return r
end

local state_apply_rule = state_apply_rule_simple

local function main ()
    local s1 : State = {{1, 2}}
    local rule : Rule = {
        from = {{1, 2}},
        to = {{1, 2}, {2, 3}},
    }

    local s2 = state_apply_rule(s1, rule)
    local s3 = state_apply_rule(s2, rule)

    local expected = "{{1, 2}, {2, 4}, {2, 3}, {3, 5}}"
    assert(state_repr(s3) == expected)
    print('OK')
end

main()
