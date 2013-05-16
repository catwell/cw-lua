local ffi = require "ffi"
local structures = require "structures"

-- see ldump.c in Lua source for the format

--- standard cdefs

ffi.cdef[[
  void free(void *ptr);
  void *malloc(size_t size);
]]

--- constants

local LUA_T = structures.bimap(0,{
  [0] = "NIL",
  [1] = "BOOLEAN",
  [2] = "LIGHTUSERDATA",
  [3] = "NUMBER",
  [4] = "STRING",
  [5] = "TABLE",
  [6] = "FUNCTION",
  [7] = "USERDATA",
  [8] = "THREAD"
})

--- constructor

local new = function(data)
  local r = {
    data = {
      size = #data+1,
      pos = 0,
    },
    internal = {},
    parsed = {},
  }
  r.data.raw = ffi.cast("unsigned char *",ffi.C.malloc(r.data.size))
  ffi.copy(r.data.raw,data,r.data.size)
  return r
end

--- readers

local pop_byte = function(self)
  local r = self.data.raw[self.data.pos]
  self.data.pos = self.data.pos + 1
  return r
end

-- basic types

local pop_bool = function(self)
  return pop_byte(self) > 0
end

local pop_fstr = function(self,size)
  local r = ffi.string(self.data.raw+self.data.pos,size)
  self.data.pos = self.data.pos + size
  return r
end

local pop_instruction = function(self)
  local _d = self.data
  local r = tonumber(ffi.cast("uint32_t *",_d.raw+_d.pos)[0])
  _d.pos = _d.pos + 4
  return r
end

local pop_int = function(self)
  local _d,_i = self.data,self.internal
  local r = tonumber(ffi.cast(_i.int.pointer_ctype,_d.raw+_d.pos)[0])
  _d.pos = _d.pos + _i.int.size
  return r
end

local pop_number = function(self)
  local _d,_i = self.data,self.internal
  local r = tonumber(ffi.cast(_i.number.pointer_ctype,_d.raw+_d.pos)[0])
  _d.pos = _d.pos + _i.number.size
  return r
end

local pop_size = function(self)
  local _d,_i = self.data,self.internal
  local r = tonumber(ffi.cast(_i.size.pointer_ctype,_d.raw+_d.pos)[0])
  _d.pos = _d.pos + _i.size.size
  return r
end

local pop_vstr = function(self)
  local size = pop_size(self) -- with trailing \0
  local r = ffi.string(self.data.raw+self.data.pos,size-1)
  self.data.pos = self.data.pos + size
  return r
end

-- parts of prototype

local pop_constant = {
  [LUA_T.NIL] = function(self)
    return nil
  end,
  [LUA_T.BOOLEAN] = function(self)
    return pop_byte(self) > 0
  end,
  [LUA_T.LIGHTUSERDATA] = function(self)
    error("unimplemented")
  end,
  [LUA_T.NUMBER] = function(self)
    return pop_number(self)
  end,
  [LUA_T.STRING] = function(self)
    return pop_vstr(self)
  end,
  [LUA_T.TABLE] = function(self)
    error("unimplemented")
  end,
  [LUA_T.FUNCTION] = function(self)
    error("unimplemented")
  end,
  [LUA_T.USERDATA] = function(self)
    error("unimplemented")
  end,
  [LUA_T.THREAD] = function(self)
    error("unimplemented")
  end,
}

local pop_upvalue = function(self)
  return {
    instack = pop_byte(self),
    idx = pop_byte(self)
  }
end

local pop_proto
pop_proto = function(self)
  local r = {}
  local n,t
  r.linedefined = pop_int(self)
  r.lastlinedefined = pop_int(self)
  r.numparams = pop_byte(self)
  r.is_vararg = pop_byte(self)
  r.maxstacksize = pop_byte(self)
  -- code
  n,t = pop_int(self),{}
  for i=1,n do t[#t+1] = pop_instruction(self) end
  r.code = t
  -- constants
  n,t = pop_int(self),{}
  local _ct
  for i=1,n do
    _ct = tonumber(pop_byte(self))
    t[#t+1] = pop_constant[_ct](self)
  end
  r.constants = t
  -- protos
  n,t = pop_int(self),{}
  for i=1,n do t[#t+1] = pop_proto(self) end
  r.protos = t
  -- upvalues
  n,t = pop_int(self),{}
  for i=1,n do t[#t+1] = pop_upvalue(self) end
  r.upvalues = t
  -- debug (TODO make optional)
  r.debug = {}
  r.debug.source = pop_vstr(self)
  n,t = pop_int(self),{}
  for i=1,n do t[#t+1] = pop_int(self) end
  r.debug.lineinfo = t
  n,t = pop_int(self),{}
  for i=1,n do
    t[#t+1] = {
      varname = pop_vstr(self),
      startpc = pop_int(self),
      endpc = pop_int(self),
    }
  end
  r.debug.locvars = t
  n,t = pop_int(self),{}
  for i=1,n do t[#t+1] = pop_vstr(self) end
  r.debug.upvalues = t
  return r
end

--- parsing

local parse_header = function(self)
  local h = {
    lua_signature = pop_fstr(self,4),
    version = pop_byte(self),
    official = not pop_bool(self),
    little_endian = pop_bool(self),
    size_int = pop_byte(self),
    size_size = pop_byte(self),
    size_instruction = pop_byte(self),
    size_number = pop_byte(self),
    number_is_integral = pop_bool(self),
    lua_tail = pop_fstr(self,6),
  }
  -- validation
  assert(
    h.lua_signature == "\27Lua" and
    h.version == 0x52 and
    h.official and
    h.little_endian and
    h.size_instruction == 4 and
    (h.size_number == 4 or h.size_number == 8) and
    not h.number_is_integral and
    h.lua_tail == "\x19\x93\r\n\x1a\n"
  )
  self.parsed.header = h
  -- re-use for internal info
  self.internal = {
    int = {
      size = h.size_int,
      pointer_ctype = "int" .. tostring(h.size_int*8) .. "_t *",
    },
    number = {
      size = h.size_number,
    },
    size = {
      size = h.size_size,
      pointer_ctype = "size_t *", -- HMM...
    }
  }
  if self.internal.number.size == 4 then
    self.internal.number.pointer_ctype = "float *"
  else
    self.internal.number.pointer_ctype = "double *"
  end
end

local parse_proto = function(self)
  self.parsed.proto = pop_proto(self)
end

--- module

local parse = function(data)
  local p = new(data)
  parse_header(p)
  parse_proto(p)
  return p
end

return {
  parse = parse,
}
