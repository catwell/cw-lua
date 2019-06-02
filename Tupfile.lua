
for i, p in ipairs(tup.glob("static/*")) do
    rule_static(tup.file(p))
end

rule_dep "fengari-web.js"

rule_lua {
    "main.lua",
    "app.lua",
    "helpers/object.lua",
    "helpers/init.lua",
}
