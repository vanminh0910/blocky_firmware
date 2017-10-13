if connectBlinkTimer ~= nil then
  tmr.unregister(connectBlinkTimer)
  connectBlinkTimer = nil
  collectgarbage()
end
-- start connecting blink
connectBlinkTimer = tmr.create()
connectBlinkTimer:alarm(300, tmr.ALARM_AUTO, function (t)
  if (statusLedOn == 1) then gpio.write(4, gpio.LOW) else gpio.write(4, gpio.HIGH) end
  statusLedOn = 1 - statusLedOn
end)
reconnectTimer = tmr.create()
reconnectTimer:alarm(10000, tmr.ALARM_AUTO, function (t)
  blocky.connect()
end)