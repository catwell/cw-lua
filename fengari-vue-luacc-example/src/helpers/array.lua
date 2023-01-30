local function Array (t)
    local r = js.new(js.global.Array)
    for _, v in ipairs(t) do
        r:push(v)
    end
    return r
end

return Array
