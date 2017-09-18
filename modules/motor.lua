local M, module = {}, ...

function M.setup()
    i2c.setup(0, 2, 1, i2c.SLOW)
end

function M.setSpeed(channel, direction, speed)
  --channel 1-4
  --speed 0-255
  --direction 0-360
	--[[
		0 degree is go straight , 180 is go back , 90 is right , 270 is left
		--under developement
	]]--
	i2c.start(0)
	i2c.address(0, 0x11, i2c.TRANSMITTER)
	i2c.write(0, 0x00)
	i2c.write(0, 0x12)
	i2c.write(0, channel)
	i2c.write(0, direction)
	i2c.write(0, speed)
	i2c.stop(0)
end

function M.go(direction)
	--direction 0-360
	i2c.start(0)
	i2c.address(0, 0x11, i2c.TRANSMITTER)
	i2c.write(0, 0x00)
	i2c.write(0,0x19)
	i2c.write(0, direction[1])
	i2c.write(0, direction[2])
	i2c.stop(0)
end

--Advance function 
function M.setStep(step) --how fast the motor react , the smaller the better
	i2c.setup(0, 2, 1, i2c.SLOW)
	i2c.start(0)
	i2c.address(0, 0x11, i2c.TRANSMITTER)
	i2c.write(0, 0x00)
	i2c.write(0, 0x20)
	i2c.write(0, step)
	i2c.stop(0)
	--default step is 1
end

return M 