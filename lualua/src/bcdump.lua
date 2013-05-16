local instruction = require "instruction"

local p_s = function(n)
  if n > 1 then
    return "s"
  else
    return ""
  end
end

local code = function(proto)
  local ops,lines = proto.code,proto.debug.lineinfo
  local nops = #ops; assert(#lines == nops)
  local r = {}
  for i=1,nops do
    r[i] = string.format(
      "%d\t[%d]\t%s",
      i,
      lines[i],
      instruction.to_string(ops[i])
    )
  end
  return r
end

local constant = function(x) -- TODO see PrintConstant
  return x
end

local debug = function(proto)
  local r = {}
  local x
  r[#r+1] = string.format("constants (%d):",#proto.constants)
  for i=1,#proto.constants do
    r[#r+1] = string.format("\t%d\t%s",i,constant(proto.constants[i]))
  end
  r[#r+1] = string.format("locals (%d):",#proto.debug.locvars)
  for i=1,#proto.debug.locvars do
    x = proto.debug.locvars[i]
    r[#r+1] = string.format(
      "\t%d\t%s\t%d\t%d",
      i,x.varname,x.startpc+1,x.endpc+1
    )
  end
  r[#r+1] = string.format("upvalues (%d):",#proto.upvalues)
  for i=1,#proto.upvalues do
    x = proto.upvalues[i]
    r[#r+1] = string.format(
      "\t%d\t%s\t%d\t%d",
      i,proto.debug.upvalues[i],x.instack,x.idx
    )
  end
  return r
end

local header = function(proto)
  local source = "?"
  if proto.debug.source then
    local c = string.sub(proto.debug.source,1,1)
    if (c == "@") or (c == "=") then
      source = string.sub(proto.debug.source,2)
    elseif c == "\27" then
      source = "(bstring)"
    else
      source = "(string)"
    end
  end
  local ftype
  if proto.linedefined == 0 then
    ftype = "main"
  else
    ftype = "function"
  end
  local vararg_plus = ""
  if proto.is_vararg > 0 then vararg_plus = "+" end
  return {
    string.format(
      "%s <%s:%d,%d> (%d instruction%s)",
      ftype,source,proto.linedefined,proto.lastlinedefined,
      #proto.code,p_s(#proto.code)
    ),
    string.format(
      "%d%s param%s, %d slot%s, %d upvalue%s, " ..
      "%d local%s, %d constant%s, %d function%s",
      proto.numparams,vararg_plus,p_s(proto.numparams),
      proto.maxstacksize,p_s(proto.maxstacksize),
      #proto.upvalues,p_s(#proto.upvalues),
      #proto.debug.locvars,p_s(#proto.debug.locvars),
      #proto.constants,p_s(#proto.constants),
      #proto.protos,p_s(#proto.protos)
    ),
  }
end

local dump
dump = function(proto,pfx)
  if pfx == nil then pfx = "" end
  -- TODO comments after code -> won't be simple
  print(pfx .. table.concat(header(proto),"\n" .. pfx))
  print(pfx .. table.concat(code(proto),"\n" .. pfx))
  print(pfx .. table.concat(debug(proto),"\n" .. pfx))
  for i=1,#proto.protos do
    dump(proto.protos[i],pfx .. "\t")
  end
end

return {
  dump = dump,
}
