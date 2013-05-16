local server = require "zerorpc.server"
local S = server.new("tcp://127.0.0.1:4242")

local swrap = function(f)
  return function(...)
    return true,f(...)
  end
end

local hello = function(name)
  return string.format("Hello, %s!",name)
end

S:add("hello",swrap(hello))
S:run()
