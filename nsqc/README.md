# nsqc

## Presentation

nsqc (pronounce "[Nesquik](http://northdallasgazette.com/wordpress/wp-content/uploads/2012/11/2f561c70a67f88377c3abbf041edbc72.jpg)") is a [NSQ](http://nsq.io/) client for Lua.

*NOTE:* This is very basic, only supports reading and does not support nsqlookupd. *You probably do not want to use this.* I may or may not improve it later. If you need a real NSQ client for Lua, get in touch.

## Usage example

```lua
local nsq = require "nsqc"

c = nsq.new("localhost", 4150)
c:subscribe("my_topic", "my_chan")

local handler = function(job)
    print(string.format(
        "got job %s with %d attempts and body %s",
        job.id, job.attempts, job.body
    ))
    local action = math.random(3)
    if(action == 1) then
        print("  -> marking as done")
        return true
    elseif(action == 2) then
        local timeout = math.random(5)
        print(string.format("  -> requeing with %d seconds timeout", timeout))
        return nil, 1000 * timeout
    else
        assert(action == 3)
        print("  -> crashing on purpose")
        error("oops")
    end
end

while true do c:consume_one(handler) end
```

## Copyright

Copyright (c) 2014 Pierre Chapuis
