require "pl.strict"
local sha256 = require "sha256"
local TESTFILE = "test.tmp"

local sys_sha256_hex = function(input)
  local f = io.open(TESTFILE,"wb")
  f:write(input)
  f:close()
  local cmd = string.format("sha256sum %s | cut -d' ' -f1",TESTFILE)
  local f = assert(io.popen(cmd,"r"))
  local s = assert(f:read("*a"))
  f:close()
  s = s:gsub("[\n\r]+$","")
  return s
end

local printf = function(p,...)
  io.stdout:write(string.format(p,...)); io.stdout:flush()
end

local rand_raw = function(len)
  local t = {}
  for i=1,len do t[i] = string.char(math.random(0,255)) end
  return table.concat(t)
end

local input = {
  "",
  "stuff",
  -- below: NIST NSRL test data (http://www.nsrl.nist.gov/testdata/)
  "abc",
  "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
}

local s = "a"
for i=1,6 do
  s = s .. s .. s .. s .. s
  s = s .. s
end
assert(#s==1000000)
input[#input+1] = s

local errors = {}

local test = function(k)
  local x,y = sys_sha256_hex(k),sha256.hex(k)
  if x == y then
    printf(".")
  else
    printf("x")
    errors[#errors+1] = {k,x,y}
  end
end

local end_test = function()
  if #errors == 0 then
    print(" OK")
  else
    print(" errors found!")
    local err
    for i=1,#errors do
      err = errors[i]
      printf("input:    [%s]\n",err[1])
      printf("expected: [%s]\n",err[2])
      printf("found:    [%s]\n",err[3])
    end
  end
  errors = {}
end

printf("fixed input ")
for i=1,#input do
  test(input[i])
end
end_test()

printf("fuzzing ")
for i=1,1000 do
  local x = rand_raw(math.random(0,1000))
  test(x)
end
end_test()
os.remove(TESTFILE)
