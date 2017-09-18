local M, module = {}, ...

function M.setup()
    i2c.setup(0, 2, 1, i2c.SLOW)
end

function M.setMode(channel, mode)
  --mode ADC-1, ADC_PULLUP-2, TOUCH-3, IO_INPUT-4, IO_INPUT_PULLUP-5, 
  --mode RANGER-6, IO_OUT-7, SERVO-8, PWM-9
    i2c.start(0)
    i2c.address(0, 0x08, i2c.TRANSMITTER)
    i2c.write(0, 0x00)
    i2c.write(0, 0x08)
    i2c.write(0, channel)
    i2c.write(0, mode)
    i2c.stop(0)
end

function M.setData(channel, data)
    i2c.start(0)
    i2c.address(0, 0x08, i2c.TRANSMITTER)
    i2c.write(0, 0x00)
    i2c.write(0, 0x09)
    i2c.write(0, channel)
    i2c.write(0, math.floor(data/256))
    i2c.write(0, data%256)
    i2c.stop(0)
end

function M.getData(channel)    
    i2c.start(0)
    i2c.address(0, 0x08, i2c.TRANSMITTER)
    i2c.write(0, 0x01)
    i2c.write(0, channel)
    i2c.stop(0)
    i2c.start(0)
    i2c.address(0, 0x08, i2c.RECEIVER)
    c = i2c.read(0,2)
    result = bit.lshift(string.byte(c, 1), 8 ) + string.byte(c, 2)
    print(string.format("%u" ,result))
    return result
end

return M