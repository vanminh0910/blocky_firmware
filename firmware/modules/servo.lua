--FileName      Servo.lua
--Version       1
--Contributor   RandName
local moduleName = ...
local M = {}
_G[moduleName] = M

local pin
local min = 50
local max = 105

function M.init(p)
    pin = p
    gpio.mode(pin,1)
    pwm.setup(pin,50,((min+max)/2))
end

function M.write(val,fi)
    pwm.start(pin)
    if(val<min) then val = min end
    if(val>max) then val = max end
    pwm.setduty(pin,val)
    if(fi) then tmr.alarm( 1, 1000, 0, function() pwm.stop(pin) end ) end
end

return M
