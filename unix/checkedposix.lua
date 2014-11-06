return setmetatable(
    { _unchecked = require "posix"},
    {
        __index = function(t, name)
            return function(...)
                return assert(t._unchecked[name](...))
            end
        end
    }
)
