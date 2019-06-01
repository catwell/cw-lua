local Object = (require "helpers").Object

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

vue.template = [[
    <p class="example">
        Hello, <span>{{world | capitalize}}</span>!
    </p>
]]

return vue
