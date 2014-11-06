-- worker node

local nodeName = arg[2]
local machineName = arg[1]

----

require "concurrent"

local dot_product = function(v1, v2)
  -- compute linear dot product
  local r = 0
  for i,j in ipairs(v1) do
    r = r + j*v2[i]
  end
  return r
end

local worker = function()

  -- receive partial vectors from the master
  local msg = concurrent.receive()
  print("received length " .. (# msg.v1))

  -- compute their linear dot product
  local sum = dot_product(msg.v1, msg.v2)

  -- send the result back
  concurrent.send(msg.from, sum)

end

-- main code: run the worker node
concurrent.init(nodeName .. "@" .. machineName)
local pid = concurrent.spawn(worker)
concurrent.register(nodeName, pid)
concurrent.loop()
concurrent.shutdown()

