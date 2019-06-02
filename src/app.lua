local helpers = require "helpers"
local Object = helpers.Object
local Template = helpers.Template

local vue = Object { el = "#app" }

function vue.data ()
    return Object {
        world = "world",
    }
end

vue.filters = Object {
    capitalize = function(self_, value)
        return value:upper()
    end
}

vue.template = Template "app"

return vue
