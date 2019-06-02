std = "lua53"

ignore = {
    -- allow access to js global
    "113/js",
    -- allow unused argument self
    "212/self",
    -- allow unused variables ending with _
    "211/.*_",
    -- allow unused arguments ending with _
    "212/.*_",
    -- allow never accessed variables ending with _
    "231/.*_",
}

exclude_files = {"deps", "dist", "Tupfile.lua"}
