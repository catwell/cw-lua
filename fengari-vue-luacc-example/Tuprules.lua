local fmt = string.format

local function lua_inputs (sources, templates)
    local r = {}
    for i, s in ipairs(sources) do
        r[i] = "src/" .. s
    end
    for i, s in ipairs(templates) do
        table.insert(r, "build/" .. s)
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

local function lua_command (sources, templates)
    return table.concat({
        "luacheck --codes src ;",
        "lua deps/luacc.lua -o dist/index.lua -i src -i build",
        lua_modules(sources),
        lua_modules(templates)
    }, " ")
end

function rule_lua (sources, templates)
    tup.definerule {
        outputs = {"dist/index.lua"},
        inputs = lua_inputs(sources, templates),
        command = lua_command(sources, templates),
    }
end

function rule_template (fn)
    assert(fn:match(".html$"))
    local ofn = "template/" .. fn:sub(1, -6) .. ".lua"
    tup.definerule {
        outputs = {"build/" .. ofn},
        inputs = {"src/" .. fn},
        command = fmt("lua script/as_template.lua src/%s > build/%s", fn, ofn),
    }
    return ofn
end

function rule_templates (templates)
    local r = {}
    for i, t in ipairs(templates) do
        r[i] = rule_template(t)
    end
    return r
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
