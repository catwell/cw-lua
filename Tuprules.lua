local fmt = string.format

local function lua_inputs (sources)
    local r = {}
    for i, s in ipairs(sources) do
        r[i] = "src/" .. s
    end
    return r
end

local function lua_modules (sources)
    local r = {}
    for i, s in ipairs(sources) do
        s = s:gsub("/", ".")
        if s:match(".init.lua$") then
            r[i] = s:sub(1, -10)
        else
            assert(s:match(".lua$"))
            r[i] = s:sub(1, -5)
        end
    end
    return table.concat(r, " ")
end

local function lua_command (sources)
    return table.concat({
        "luacheck --codes src ;",
        "lua deps/luacc.lua -o dist/index.lua -i src",
        lua_modules(sources)
    }, " ")
end

function rule_lua (sources)
    tup.definerule {
        outputs = {"dist/index.lua"},
        inputs = lua_inputs(sources),
        command = lua_command(sources),
    }
end

function rule_static (fn)
    tup.definerule {
        outputs = {"dist/" .. fn},
        inputs = {"static/" .. fn},
        command = fmt("cp static/%s dist/%s", fn, fn),
    }
end

function rule_dep (fn)
    tup.definerule {
        outputs = {"dist/" .. fn},
        inputs = {"deps/" .. fn},
        command = fmt("cp deps/%s dist/%s", fn, fn),
    }
end
