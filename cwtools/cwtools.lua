local fmt = function(p, ...)
  if select('#', ...) == 0 then
    return p
  else
    return string.format(p, ...)
  end
end

local printf = function(p, ...)
  io.stdout:write(fmt(p, ...))
  io.stdout:flush()
end

local eprintf = function(p, ...)
  io.stderr:write(fmt(p, ...))
  io.stdout:flush()
end

local tprintf = function(t, p, ...)
  t[#t+1] = fmt(p, ...)
end

local file_read = function(fn)
  local f = io.open(fn, "rb")
  if not f then return nil end
  local data = f:read("*all")
  f:close()
  return data
end

local file_write = function(fn, data)
  local f = assert(io.open(fn, "wb"))
  f:write(data)
  f:close()
end

local fun_map = function(f, t)
  assert((type(f) == "function") and (type(t) == "table"))
  local r = {}
  for i=1,#t do r[i] = f(t[i]) end
  return r
end

return {
  fmt = fmt, -- (pattern, ...) -> string
  printf = printf, -- (pattern, ...) -> I/O
  eprintf = eprintf, -- (pattern, ...) -> I/O
  tprintf = tprintf, -- (t, pattern, ...) -> !t
  file = {
    read = file_read, -- (fn) -> data
    write = file_write, -- (fn, data) -> I/O
  },
  fun = {
    map = fun_map, -- (f, t) -> table
  },
}
