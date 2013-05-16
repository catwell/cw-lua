local zmq = require "zmq"
local mp = require "luajit-msgpack-pure"
local common = require "zerorpc.common"

local z_list = function()
  error("unimplemented")
end

local z_name = function()
  error("unimplemented")
end

local z_ping = function()
  error("unimplemented")
end

local z_help = function()
  error("unimplemented")
end

local z_args = function()
  error("unimplemented")
end

local z_inspect = function()
  error("unimplemented")
end

local z_bye = function(self)
  self.running = false
  return true
end

local new_funs = function()
  return {
    _zerorpc_list = z_list,
    _zerorpc_name = z_name,
    _zerorpc_ping = z_ping,
    _zerorpc_help = z_help,
    _zerorpc_args = z_args,
    _zerorpc_inspect = z_inspect,
    _zerorpc_lua_bye = z_bye,
  }
end

local add = function(self,name,f)
  assert( (type(name) == "string") and (type(f) == "function") )
  self.funs[name] = f
end

local run_once = function(self)
  local i_data = self.skt:recv()
  assert(i_data)
  local offset,i_msg = mp.unpack(i_data)
  assert(offset == #i_data)
  local i_headers,method,args = i_msg[1],i_msg[2],i_msg[3]
  assert(i_headers and method and args)
  assert(self.funs[method])
  local internal = (method:sub(1,1) == "_")
  local ok,value
  if internal then
    ok,value = self.funs[method](self,unpack(args))
  else
    ok,value = self.funs[method](unpack(args))
  end
  if ok then
    local status = "OK"
    local o_headers = common.new_headers()
    o_headers.response_to = assert(i_headers.message_id)
    local o_msg = {o_headers,status,{value}}
    local o_data = mp.pack(o_msg)
    self.skt:send(o_data)
  else
    error("unimplemented")
  end
end

local run = function(self)
  self.running = true
  while self.running do run_once(self) end
  self.skt:close()
  self.ctx:term()
end

local methods = {
  add = add,
  run = run,
}

local new = function(ep)
  local ctx = zmq.init()
  local skt = ctx:socket(zmq.REP)
  skt:bind(ep)
  local funs = new_funs()
  local r = {ctx=ctx,skt=skt,funs=funs}
  return setmetatable(r,{__index = methods})
end

return {
  new = new,
}
