

local MPR121 = {}
local codes = {
    MPR121_I2CADDR_DEFAULT = 0x5A,
	MPR121_TOUCHSTATUS_L   = 0x00,
	MPR121_TOUCHSTATUS_H   = 0x01,
	MPR121_FILTDATA_0L     = 0x04,
	MPR121_FILTDATA_0H     = 0x05,
	MPR121_BASELINE_0      = 0x1E,
	MPR121_MHDR            = 0x2B,
	MPR121_NHDR            = 0x2C,
	MPR121_NCLR            = 0x2D,
	MPR121_FDLR            = 0x2E,
	MPR121_MHDF            = 0x2F,
	MPR121_NHDF            = 0x30,
	MPR121_NCLF            = 0x31,
	MPR121_FDLF            = 0x32,
	MPR121_NHDT            = 0x33,
	MPR121_NCLT            = 0x34,
	MPR121_FDLT            = 0x35,

	MPR121_TOUCHTH_0       = 0x41,
	MPR121_RELEASETH_0     = 0x42,
	MPR121_DEBOUNCE        = 0x5B,
	MPR121_CONFIG1         = 0x5C,
	MPR121_CONFIG2         = 0x5D,
	--MPR121_CHARGECURR_0    = 0x5F,
	--MPR121_CHARGETIME_1    = 0x6C,
	MPR121_ECR             = 0x5E,
	--MPR121_AUTOCONFIG0     = 0x7B,
	--MPR121_AUTOCONFIG1     = 0x7C,
	--MPR121_UPLIMIT         = 0x7D,
	--MPR121_LOWLIMIT        = 0x7E,
	--MPR121_TARGETLIMIT     = 0x7F,

	--MPR121_GPIODIR         = 0x76,
	--MPR121_GPIOEN          = 0x77,
	--MPR121_GPIOSET         = 0x78,
	--MPR121_GPIOCLR         = 0x79,
	--MPR121_GPIOTOGGLE      = 0x7A,

	MPR121_SOFTRESET       = 0x80,
}
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

function MPR121:begin()
	i2c.setup(0, 2, 1, i2c.SLOW)
    MPR121:writeRegister(codes.MPR121_SOFTRESET, 0x63)
	tmr.delay(1000)
    MPR121:writeRegister(codes.MPR121_ECR, 0x0)
    --local c =readRegister(codes.MPR121_CONFIG2, 1)
    --if (c ~= 0x24) then return false end
    MPR121:setThresholds(12, 6)
    MPR121:writeRegister(codes.MPR121_MHDR, 0x01)
    MPR121:writeRegister(codes.MPR121_NHDR, 0x01)
    MPR121:writeRegister(codes.MPR121_NCLR, 0x0E)
    MPR121:writeRegister(codes.MPR121_FDLR, 0x00)
    MPR121:writeRegister(codes.MPR121_MHDF, 0x01)
    MPR121:writeRegister(codes.MPR121_NHDF, 0x05)
    MPR121:writeRegister(codes.MPR121_NCLF, 0x01)
    MPR121:writeRegister(codes.MPR121_FDLF, 0x00)
    MPR121:writeRegister(codes.MPR121_NHDT, 0x00)
    MPR121:writeRegister(codes.MPR121_NCLT, 0x00)
    MPR121:writeRegister(codes.MPR121_FDLT, 0x00)
    MPR121:writeRegister(codes.MPR121_DEBOUNCE, 0)
    MPR121:writeRegister(codes.MPR121_CONFIG1, 0x10)
    MPR121:writeRegister(codes.MPR121_CONFIG2, 0x20)
    MPR121:writeRegister(codes.MPR121_ECR, 0x8F)

end

function MPR121:setThresholds(touch, release)
  for i=0,11 do
    MPR121:writeRegister(codes.MPR121_TOUCHTH_0 + 2*i, touch)
    MPR121:writeRegister(codes.MPR121_RELEASETH_0 + 2*i, release)
  end
end

--[[
function MPR121:filteredData(t)
  if (t > 12) then return 0 end
  return self.reg:r(codes.MPR121_FILTDATA_0L + t*2)
end

function MPR121:baselineData(t)
  if (t > 12) then return 0 end
  bl = self.reg:r(codes.MPR121_BASELINE_0 + t, 1)
  return bit.lshift(bl, 2)
end
]]--
function MPR121:readRegister16(reg,length)
	i2c.start(0)
    i2c.address(0, 0x5A,i2c.TRANSMITTER)
    i2c.write(0,reg)
    i2c.stop(0)
	i2c.start(0)
	local error = i2c.address(0, 0x5A, i2c.RECEIVER)
	if error == true then print("Read Suz") end
	str = i2c.read(0,2)
	i2c.stop(0)
	
	return tonumber(str)

end
function MPR121:touched()
  t = MPR121:readRegister16(codes.MPR121_TOUCHSTATUS_L, 2)
  return bit.band(t, 0x0FFF)
end

return MPR121
