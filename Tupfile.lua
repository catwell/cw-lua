
local lua_sources = {
    "main.lua",
    "app.lua",
    "helpers/object.lua",
    "helpers/init.lua",
}

local templates = {
    "app.html"
}

rule_dep "fengari-web.js"

for i, p in ipairs(tup.glob("static/*")) do
    rule_static(tup.file(p))
end

rule_lua(
    lua_sources,
    rule_templates(templates)
)
