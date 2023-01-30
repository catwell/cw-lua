-- from http://start.tessel.io/blinky

return function (_ENV, module)
    local engine = this
    local tessel = engine:require("tessel")

    local led1 = tessel.led[0]:output(1)
    local led2 = tessel.led[1]:output(0)

    local blink = function(_)
        console:log("I'm blinking! (Press CTRL + C to stop)")
        led1:toggle()
        led2:toggle()
    end

    engine:setInterval(blink, 100)
end
