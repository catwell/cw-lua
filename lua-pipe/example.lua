require "pipe"
local map,reduce = pipe.map,pipe.reduce

-- creating a pipe
div2 = pipe.new(function(n) return n/2 end)

-- simple usage
print(
  pipe.able{1,2,3}
  ^ map(function(x) return x*x end)
  ^ reduce(function(s,x) return s+x end)
  ^ div2
)

-- same thing with composition
local square = map(function(x) return x*x end)
local sum = reduce(function(s,x) return s+x end) -- same as pipe.sum
local process = square ^ sum ^ div2
print(pipe.able{1,2,3} ^ process)

-- using functions
print(pipe.able{{1,2},3,{4}} ^ pipe.flatten ^ table.concat)

