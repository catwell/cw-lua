local uuid = require "uuid"
local Z_VERSION = 3

local gen_uuid = function()
  return uuid.new()
end

local new_headers = function()
  return {
    message_id = gen_uuid(),
    v = Z_VERSION,
  }
end

return {
  new_headers = new_headers,
}
