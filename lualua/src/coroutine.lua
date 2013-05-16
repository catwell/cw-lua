local structures = require "structures"

local coroutine_new = function()
  local r = {
    call_stack = structures.stack({}),
    data_stack = structures.stack({}),
  }
  return r
end

local simple_exec = function(proto)
  local co = coroutine_new()
end

return {
  simple_exec = simple_exec,
}
