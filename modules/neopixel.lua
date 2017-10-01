local M, module = {}, ...

function colour_rgb(r, g, b)
  return string.format('#%02x%02x%02x', r, g, b)
end

function M.hex2rgb(hex)
  hex = hex:gsub('#','')
  return {tonumber('0x'..hex:sub(1,2)), tonumber('0x'..hex:sub(3,4)), tonumber('0x'..hex:sub(5,6))}
end

function M.setup()
    i2c.setup(0, 2, 1, i2c.SLOW)
end

function M.update() 
    i2c.setup(0, 2, 1, i2c.SLOW)
    i2c.start(0)
    i2c.address(0, 0x15, i2c.TRANSMITTER)
    i2c.write(0, 0x00)
    i2c.write(0, 0x05)
    i2c.stop(0)
end

function M.setColorForAll(colorHex)
  local colorRGB = M.hex2rgb(colorHex)
  i2c.setup(0, 2, 1, i2c.SLOW)
  i2c.start(0)
  i2c.address(0, 0x15, i2c.TRANSMITTER)
  i2c.write(0, 0x00)
  i2c.write(0, 0x01)
  i2c.write(0, colorRGB[1])
  i2c.write(0, colorRGB[2])
  i2c.write(0, colorRGB[3])
  i2c.stop(0)
  M.update()
end

function M.setBrightness(brightness)
  i2c.setup(0, 2, 1, i2c.SLOW)
  i2c.start(0)
  i2c.address(0, 0x15, i2c.TRANSMITTER)
  i2c.write(0, 0x00)
  i2c.write(0, 0x03)
  i2c.write(0, brightness)
  i2c.stop(0)
  M.update()
end

function M.setColor(pixel, colorHex)
  local colorRGB = M.hex2rgb(colorHex)
  i2c.setup(0, 2, 1, i2c.SLOW)
  i2c.start(0)
  i2c.address(0, 0x15, i2c.TRANSMITTER)
  i2c.write(0, 0x00)
  i2c.write(0, 0x00)
  i2c.write(0, pixel)
  i2c.write(0, colorRGB[1])
  i2c.write(0, colorRGB[2])
  i2c.write(0, colorRGB[3])
  i2c.stop(0)
  M.update()
end

return M 