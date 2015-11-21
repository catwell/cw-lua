local sorted_pairs = function(t)
    local idx, i = {}, 0
    for k in pairs(t) do
        i = i + 1
        idx[i] = k
    end
    table.sort(idx)
    i = 0
    local f = function(t, _)
        i = i + 1
        return idx[i], t[idx[i]]
    end
    return f, t, nil
end

return {
    sorted_pairs = sorted_pairs,
}
