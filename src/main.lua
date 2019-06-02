local H = require "helpers"


local routes = H.Array {
    H.Object {
        path = "/",
        component = require "home",
    },
    H.Object {
        path = "/other",
        component = H.Object {
            template = H.Template "about",
        },
    },
}

local router = H.Object {
    mode = "history",
    routes = routes,
}

local vue = js.new(
    js.global.Vue,
    H.Object {
        router = js.new(js.global.VueRouter, router)
    }
)

vue["$mount"](vue, "#app")
