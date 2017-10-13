local moduleName = ...
local M = {}
_G[moduleName] = M

--[[Digitallly Signed by Anata Department 2009 

]]--
local codes = {
  --[[MPR121_I2CADDR_DEFAULT = 0x5A,
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
  ]]--
}
local function writeRegister(reg, val)
  print("Write")
  i2c.start(0)
  local error = i2c.address(0, 0x5A, i2c.TRANSMITTER)
  if error == true then print("Writen")
  else print("False") end
  i2c.write(0, reg)
  i2c.write(0, val)
  i2c.stop(0)
end

local function setThresholds(touch, release)
  for i=0,11 do
    writeRegister(0x41 + 2*i, touch)
    writeRegister(0x42 + 2*i, release)
  end
end

--[[
function filteredData(t)
  if (t > 12) then return 0 end
  return self.reg:r(codes.MPR121_FILTDATA_0L + t*2)
end

function baselineData(t)
  if (t > 12) then return 0 end
  bl = self.reg:r(codes.MPR121_BASELINE_0 + t, 1)
  return bit.lshift(bl, 2)
end
]]--

local function whenTouched(_pin)
  _pin = _pin - 1
  if _pin < 8 then 
      if bit.isset(dataH, _pin) == true and bit.isclear(old_dataH,_pin) == true then  return true end
  elseif _pin > 7 then 
      if bit.isset(dataL, _pin - 8 ) == true and bit.isclear(old_dataL,_pin - 8) == true then return true end
  end
  return false
end

local function whenRelease (_pin)
  _pin = _pin - 1
  if _pin < 8 then 
      if bit.isset(old_dataH, _pin) == true and bit.isclear(dataH,_pin) == true then  return true end
  elseif _pin > 7 then 
      if bit.isset(old_dataL, _pin - 8 ) == true and bit.isclear(dataL,_pin - 8) == true then return true end
  end
  return false
end

function M.start(_trig_pin, onTouched, onReleased)
  i2c.setup(0, 2, 1, i2c.SLOW)
  writeRegister(0x80, 0x63)
  tmr.delay(1000)
  writeRegister(0x5e, 0x0)
  --local c =readRegister(codes.MPR121_CONFIG2, 1)
  --if (c ~= 0x24) then return false end
  setThresholds(12, 6)
  writeRegister(0x2B, 0x01) --MPR121_MHDR
  writeRegister(0x2C, 0x01)--MPR121_NHDR
  writeRegister(0x2D, 0x0E)--MPR121_NCLR
  writeRegister(0x2E, 0x00)--MPR121_FDLR
  writeRegister(0x2F, 0x01)--MPR121_MHDF
  writeRegister(0x30, 0x05)--MPR121_NHDF
  writeRegister(0x31, 0x01)--MPR121_NCLF
  writeRegister(0x32, 0x00)--MPR121_FDLF
  writeRegister(0x33, 0x00)--MPR121_NHDT
  writeRegister(0x34, 0x00)--MPR121_NCLT
  writeRegister(0x35, 0x00)--MPR121_FDLT
  writeRegister(0x5B, 0)--MPR121_DEBOUNCE
  writeRegister(0x5C, 0x10)--MPR121_CONFIG1
  writeRegister(0x5D, 0x20)--MPR121_CONFIG2
  writeRegister(0x5E, 0x8F)--MPR121_ECR
  old_dataH = 0 
  old_dataL = 0 
  gpio.mode(_trig_pin, gpio.INT)
  gpio.trig(_trig_pin, "down", function(level)
  i2c.start(0)
  i2c.address(0 , 0x5A , i2c.TRANSMITTER)
  i2c.write(0, 0x00)
  i2c.stop(0)
  i2c.start(0)
  i2c.address(0, 0x5A , i2c.RECEIVER)
  str = i2c.read(0,2)
  i2c.stop(0)
  
  b = {}
  str:gsub(".",function(c) table.insert(b,c) end)
  
  dataH = string.byte(b[1])
  dataL = string.byte(b[2])
    
  --User Code setting inside
  for i=1, 12 do
    if whenRelease(i)  then onReleased(i) end
    if whenTouched(i) then onTouched(i) end
  end        
  -- User Code inside this line
  old_dataH = dataH
  old_dataL = dataL
  end)
end

return M