-- master node

local nodeName = "n0"
local machineName = "host0"
local vLen = 10000
local workerNodes = {
  {"n1", "n1@host1"},
  {"n2", "n2@host2"},
  {"n3", "n3@host3"},
  {"n4", "n4@host4"},
  {"n5", "n5@host5"},
}

----

require "concurrent"

local random_vect = function(n)
  -- generate a vector of random numbers
  r = {}
  for i=1,n do
    table.insert(r,math.random())
  end
  return r
end

local self_desc = function()
  -- return that node's description
  return {concurrent.self(), concurrent.node()}
end

local dot_product = function(v1, v2)
  -- compute linear dot product
  local r = 0
  for i,j in ipairs(v1) do
    r = r + j*v2[i]
  end
  return r
end

local master = function()

  local v1 = random_vect(vLen)
  local v2 = random_vect(vLen)

  -- compute linear version (check)
  print("linear dot product is " .. dot_product(v1, v2))

  local sv1, sv2
  local sum = 0

  local numNodes = # workerNodes
  local svLen = math.floor(vLen / numNodes)
  local svRem = vLen - (svLen * numNodes)

  for _,node in ipairs(workerNodes) do

    -- take a slice of each vector v1 and v2
    sv1 = {}
    sv2 = {}
    for i=1,svLen do
      table.insert(sv1, table.remove(v1))
      table.insert(sv2, table.remove(v2))
    end
    if svRem > 0 then
      svRem = svRem - 1
      table.insert(sv1, table.remove(v1))
      table.insert(sv2, table.remove(v2))
    end

    -- send them to the worker nodes to compute their dot product
    concurrent.send(
      node,
      {
        from = self_desc(),
        v1 = sv1,
        v2 = sv2
      }
    )

  end

  -- receive the results
  for i=1,numNodes do
    local partsum = concurrent.receive()
    print("partsum " .. i .." is " .. partsum)
    sum = sum + partsum
  end

  print("parallel dot product is " .. sum)

end

-- main code: run the master
concurrent.init(nodeName .. "@" .. machineName)
concurrent.spawn(master)
concurrent.loop()
concurrent.shutdown()
