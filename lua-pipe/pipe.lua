pipe = {

  cast = function(p)
    if type(p) == "function" then return pipe.new(p)
    else return p end
  end,

  mt_pipeable = {
    __pow = function(self,p)
      return pipe.cast(p).apply(self)
    end
  },

  mt_pipe = {

    __call = function(self,...)
      r = pipe.new(self.fun)
      r.next,r.args = self.next,{...}
      return r
    end,

    __pow = function(self,p)
      r = pipe.new(self.fun)
      r.next,r.args = pipe.cast(p),self.args
      return r
    end,

    __index = function(self,x)
      if x == "apply" then
        return function(in_t,...)
          if self.args == nil then r = self.fun(in_t)
          else r = self.fun(in_t,unpack(self.args)) end
          if self.next == nil then return r
          else return self.next.apply(r) end
        end
      elseif x == "is_pipe" then return true
      else return rawget(self,x) end
    end,

  },

  able = function(x)
    return setmetatable(x,pipe.mt_pipeable)
  end,

  new = function(f)
    return setmetatable({fun=f},pipe.mt_pipe)
  end,

}

-- default pipes

pipe.reduce = pipe.new(function(t,f,init)
  if init == nil then s = t[1]
  else s = f(init,t[1]) end
  for i=2,#t do s = f(s,t[i]) end
  return s
end)

pipe.map = pipe.new(function(t,f)
  r = {}
  for i=1,#t do r[i] = f(t[i]) end
  return setmetatable(r,mt_table)
end)

pipe.sum = pipe.reduce(function(s,x) return s+x end)

pipe.flatten = pipe.reduce(function(s,x)
  if type(x) == "table" then
    for i=1,#x do s[#s+1] = x[i] end
  else s[#s+1] = x end
  return s
end,{})

pipe.concat = pipe.new(function(t)
  print(table.concat(t))
end)
