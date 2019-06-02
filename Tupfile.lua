
local lua_sources = {
    "main.lua",
    "home.lua",
    "helpers/object.lua",
    "helpers/array.lua",
    "helpers/template.lua",
    "helpers/init.lua",
}

local templates = {
    "home.html",
    "about.html",
}

rule_dep "fengari-web.js"

for i, p in ipairs(tup.glob("static/*")) do
    rule_static(tup.file(p))
end

rule_lua(
    lua_sources,
    rule_templates(templates)
)
