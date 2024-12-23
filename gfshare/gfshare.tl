local record Tables
   logs: {integer}
   exps: {integer}
end

local type Shares = {integer: string}

local function get_tables() : Tables
    local logs, exps = {}, {}
    local x = 1
    for i = 0, 0xff - 1 do
        exps[i] = x
        if x > 0 then logs[x] = i end
        x = x << 1
        if x & 0x100 ~= 0 then x = x ~ 0x11d end
    end
    return {logs=logs, exps=exps}
end

local function _t<T>(n: integer, f: function(): T): {T}
    local t = {}
    for i = 1, n do t[i] = f() end
    return t
end

local function _zeros(n: integer): {integer}
    return _t(n, function(): integer return 0 end)
end

local function _rands(n: integer): {integer}
    return _t(n, function(): integer return math.random(0, 0xff) end)
end

local function combine(shares: Shares, tables?: Tables): string
    local _, first_share = next(shares)
    local sz = #first_share
    local buf = _zeros(sz)

    if tables == nil then tables = get_tables() end
    local logs, exps = tables.logs, tables.exps

    for i, share in pairs(shares) do
        assert(#share == sz)
        local top, bottom = 0, 0
        for j in pairs(shares) do
            if i ~= j then
                top = (top + logs[j]) % 0xff
                bottom = (bottom + logs[i ~ j]) % 0xff
            end
        end
        local log_l_i = (top - bottom) % 0xff
        for j = 1, sz do
            local b = share:byte(j)
            if b ~= 0 then
                buf[j] = buf[j] ~ exps[(log_l_i + logs[b]) % 0xff]
            end
        end
    end

    return string.char(table.unpack(buf))
end

local function split(
    secret: string,
    num_shares: integer,
    threshold: integer,
    tables?: Tables
): Shares
    local sz = #secret
    local buf = _t(threshold - 1, function(): {integer} return _rands(sz) end)
    buf[threshold] = {secret:byte(1, sz)}

    if tables == nil then tables = get_tables() end
    local logs, exps = tables.logs, tables.exps

    local shares: Shares = {}
    for _ = 1, num_shares do
        -- pick next share number
        local n = math.random(1, 0xff)
        while shares[n] or (n == 0) do n = (n + 1) % 0xff end

        local share = _zeros(sz)
        for coef = 1, threshold do
            for i = 1, sz do
                local b = share[i]
                if b ~= 0 then
                    b = exps[(logs[n] + logs[b]) % 0xff];
                end
                share[i] = b ~ buf[coef][i]
            end
        end

        shares[n] = string.char(table.unpack(share))
    end

    return shares
end

return { get_tables=get_tables, combine=combine, split=split }
