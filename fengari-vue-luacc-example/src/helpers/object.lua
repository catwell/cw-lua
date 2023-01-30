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

return Object
