--FileName	MPR121
--Version	1
--Contributor	holycow
local MPR121 = {}


function MPR121:writeRegister(reg,val)
	print("Write")
    i2c.start(0)
    local error = i2c.address(0, 0x5A, i2c.TRANSMITTER)
	if error == true then print("Writen")
	else print("False") end
    i2c.write(0,reg)
	i2c.write(0,val)
    i2c.stop(0)
end
function MPR121:setThresholds(touch, release)
  for i=0,11 do
    MPR121:writeRegister(MPR121_TOUCHTH_0 + 2*i, touch)
    MPR121:writeRegister(MPR121_RELEASETH_0 + 2*i, release)
  end
end
function MPR121:begin(_trig_pin)
	i2c.setup(0, 2, 1, i2c.SLOW)
    MPR121:writeRegister(0x80, 0x63)
    tmr.delay(1000)
    MPR121:writeRegister(0x5E, 0x0)
    --local c =readRegister(codes.MPR121_CONFIG2, 1)
    --if (c ~= 0x24) then return false end
    MPR121:setThresholds(12, 6)
    MPR121:writeRegister(0x2B, 0x01) --MPR121_MHDR
    MPR121:writeRegister(0x2C, 0x01)--MPR121_NHDR
    MPR121:writeRegister(0x2D, 0x0E)--MPR121_NCLR
    MPR121:writeRegister(0x2E, 0x00)--MPR121_FDLR
    MPR121:writeRegister(0x2F, 0x01)--MPR121_MHDF
    MPR121:writeRegister(0x30, 0x05)--MPR121_NHDF
    MPR121:writeRegister(0x31, 0x01)--MPR121_NCLF
    MPR121:writeRegister(0x32, 0x00)--MPR121_FDLF
    MPR121:writeRegister(0x33, 0x00)--MPR121_NHDT
    MPR121:writeRegister(0x34, 0x00)--MPR121_NCLT
    MPR121:writeRegister(0x35, 0x00)--MPR121_FDLT
    MPR121:writeRegister(0x5B, 0)--MPR121_DEBOUNCE
    MPR121:writeRegister(0x5C, 0x10)--MPR121_CONFIG1
    MPR121:writeRegister(0x5D, 0x20)--MPR121_CONFIG2
    MPR121:writeRegister(0x5E, 0x8F)--MPR121_ECR
	--end of setup 
    old_dataH = 0 
    old_dataL = 0 
	if _trig_pin ~= nil then 
		gpio.mode(_trig_pin, gpio.INT)
		gpio.trig(_trig_pin, "down", MPR121:update)
	else 
		tmr.create():alarm(1000, tmr.ALARM_AUTO, MPR121:update) --no irq pin setup
	end
end
function MPR121:update()
	i2c.start(0)
	i2c.address(0 , 0x5A , i2c.TRANSMITTER)
	i2c.write(0, 0x00)
	i2c.stop(0)
	i2c.start(0)
	i2c.address(0, 0x5A , i2c.RECEIVER)
	local str = i2c.read(0,2)
	i2c.stop(0)
	local b = {}
	str:gsub(".",function(c) table.insert(b,c) end)

	dataH = string.byte(b[1])
	dataL = string.byte(b[2])

	MPR121:trig_event()

	old_dataH = dataH
	old_dataL = dataL
end
function MPR121:trig_event()


end

--[[
function MPR121:filteredData(t)
  if (t > 12) then return 0 end
  return self.reg:r(MPR121_FILTDATA_0L + t*2)
end
function MPR121:baselineData(t)
  if (t > 12) then return 0 end
  bl = self.reg:r(MPR121_BASELINE_0 + t, 1)
  return bit.lshift(bl, 2)
end
]]--



function MPR121:whenTouch (_channel)
    _channel = _channel - 1
    if _channel < 8 then 
        if bit.isset(dataH, _channel) == true and bit.isclear(old_dataH,_channel) == true then  return true end
    elseif _channel > 7 then 
        if bit.isset(dataL, _channel - 8 ) == true and bit.isclear(old_dataL,_channel - 8) == true then return true end
    end
    return false
end
function MPR121:whenRelease(_channel)
    _channel = _channel - 1
    if _channel < 8 then 
        if bit.isset(old_dataH, _channel) == true and bit.isclear(dataH,_channel) == true then  return true end
    elseif _channel > 7 then 
        if bit.isset(old_dataL, _channel - 8 ) == true and bit.isclear(dataL,_channel - 8) == true then return true end
    end
    return false

end

return MPR121
