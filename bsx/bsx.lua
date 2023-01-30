#!/usr/bin/env luajit

pcall(require "pl.strict")
local haricot = require "haricot"

--- TOOLS ---

local fmt = function(p,...)
  if select('#',...) == 0 then
    return p
  else
    return string.format(p,...)
  end
end

local printf = function(p,...)
  io.stdout:write(fmt(p,...)); io.stdout:flush()
end

local check_cfg = function(cfg)
  return (
    (type(cfg) == "table") and
    (type(cfg.server) == "string") and
    (type(cfg.port) == "number") and
    (type(cfg.tube) == "string")
  ) and cfg or nil
end

--- functions ---

init = function()
  BS = assert(haricot.new(CFG.server,CFG.port))
  BS:use(CFG.tube)
  BS:watch(CFG.tube)
  BS:ignore("default")
  local identity = function(x) return x end
  decode = CFG.decode or identity
  encode = CFG.encode or identity
  as_string = CFG.as_string or identity
  valid = CFG.valid or identity
end

local wrap_body = function(body)
  if not body then return nil end
  local body_methods = {
    as_string = as_string,
    valid = valid,
    encode = encode,
  }
  return setmetatable(body,{__index = body_methods})
end

get_body = function(job)
  if job.data then
    return wrap_body(decode(job.data))
  else return nil end
end

show = function(job)
  if not job then
    printf("==> no job <==\n")
  elseif job.deleted then
    printf("==> deleted (%d) <==\n",job.id)
  else
    printf("==> %d <==\n%s\n",job.id,as_string(get_body(job)))
  end
end

delete = function(job,force)
  if j.deleted and (not force) then
    print("Already deleted!")
    return
  end
  BS:delete(job.id)
  job.deleted = true
  job.data = nil
end

wrap_job = function(job)
  if not job then return nil end
  local job_methods = {
    show = show,
    delete = delete,
    body = get_body,
  }
  return setmetatable(job,{__index = job_methods})
end

peek = function()
  local ok,job = BS:peek_ready()
  if not ok then
    printf("ERROR: %s\n",job)
  else
    show(job)
    return wrap_job(job)
  end
end

put = function(body,pri,delay,ttr)
  assert(valid(body))
  BS:put(
    pri or 2048,
    delay or 0,
    ttr or 60,
    encode(body)
  )
end

--- MAIN ---

BS,encode,decode,as_string,valid = nil,nil,nil,nil,nil
CFG = assert(check_cfg(require "bsxcfg"),"invalid config")

init()
