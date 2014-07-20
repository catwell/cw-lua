-- from http://start.tessel.io/wifi

return function (_ENV, module)
    local engine = this
    local http = engine:require("http")
    local statusCode = 200;
    local count = 1;

    local start

    local on_success = function(_, res)
        console:log("# statusCode", res.statusCode)

        local bufs = {}

        local on_data = function(_, data)
            data = data:toString()
            bufs[#bufs+1] = data
            console:log("# received", data);
        end

        local on_end = function()
            console:log("done.")
            engine:setImmediate(start)
        end

        res:on("data", on_data)
        res:on("end", on_end)
    end

    local on_error = function(_, e)
        console:log("not ok -", e.message, "error event")
        engine:setImmediate(start)
    end

    start = function()
        console:log("http request #" .. count)
        count = count + 1
        local r = http:get("http://httpstat.us/" + statusCode, on_success)
        r:on("error", on_error)
    end

    engine:setImmediate(start)
end
