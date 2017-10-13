if connectBlockyTimer ~= nil then
  tmr.unregister(connectBlockyTimer)
  connectBlockyTimer = nil
end
if connectBlinkTimer ~= nil then
  tmr.unregister(connectBlinkTimer)
  connectBlinkTimer = nil
end  
if reconnectTimer ~= nil then
  tmr.unregister(reconnectTimer)
  reconnectTimer = nil
end
collectgarbage()
gpio.write(4, gpio.HIGH)