if connectBlinkTimer ~= nil then
  tmr.unregister(connectBlinkTimer)
  connectBlinkTimer = nil
  collectgarbage()
end
startConnectingBlink()
reconnectTimer = tmr.create()
reconnectTimer:alarm(10000, tmr.ALARM_AUTO, function (t)
  blocky.connect()
end)