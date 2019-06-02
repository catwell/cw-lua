local H = require "helpers"


local vue = H.Object { }

function vue.data ()
    return H.Object {
        world = "world",
    }
end

vue.filters = H.Object {
    capitalize = function(self_, value)
        return value:upper()
    end
}

vue.template = H.Template "home"

return vue
