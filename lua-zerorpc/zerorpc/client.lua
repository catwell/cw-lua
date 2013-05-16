local zmq = require "zmq"
local mp = require "luajit-msgpack-pure"
local common = require "zerorpc.common"

local close = function(self)
  self.skt:close()
  self.ctx:term()
end

local call = function(self,method,...)
  local args = {...}
  local o_headers = common.new_headers()
  local o_msg = {o_headers,method,args}
  local o_data = mp.pack(o_msg)
  self.skt:send(o_data)
  local i_data,err = self.skt:recv()
  if i_data then
    local offset,i_msg = mp.unpack(i_data)
    assert(offset == #i_data)
    if i_msg[2] == "OK" then
      return true,unpack(i_msg[3])
    else
      error("unimplemented")
    end
  else
    error("unimplemented")
  end
end

local methods = {
  close = close,
  call = call,
}

local new = function(ep)
  local ctx = zmq.init()
  local skt = ctx:socket(zmq.REQ)
  skt:connect(ep)
  local r = {ctx=ctx,skt=skt}
  return setmetatable(r,{__index = methods})
end

return {
  new = new,
}
