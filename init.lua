-------------------------------- main code starts here -----------------------
function enterSetupMode()
  print('Config mode triggered. Reboot to config mode now')
  file.open('boot_setup_mode', 'w')
  file.writeline('')
  file.flush()   
  file.close()
  node.restart()
end

statusLedOn = 0
gpio.mode(4, gpio.OUTPUT)
gpio.write(4, gpio.HIGH)

gpio.mode(3, gpio.INT)
gpio.trig(3, 'down', function(level)
    gpio.trig(3, 'none', function() end)
    enterSetupMode()
end)

function startConnectingBlink()
  connectBlinkTimer = tmr.create()
  connectBlinkTimer:alarm(300, tmr.ALARM_AUTO, function (t)
    if (statusLedOn == 1) then gpio.write(4, gpio.LOW) else gpio.write(4, gpio.HIGH) end
    statusLedOn = 1 - statusLedOn
  end)
end

function onBlockyConnected()
  tmr.unregister(connectBlockyTimer)
  tmr.unregister(connectBlinkTimer)
  if reconnectTimer ~= nil then
    tmr.unregister(reconnectTimer)
    reconnectTimer = nil
  end
  gpio.write(4, gpio.HIGH)
end

function onBlockyDisConnected()
  startConnectingBlink()
  reconnectTimer = tmr.create()
  reconnectTimer:alarm(10000, tmr.ALARM_AUTO, function (t)
    blocky.connect()
  end)
end

-- check if boot to setup mode is triggered
if file.exists('boot_setup_mode') or not file.exists('config') then
  print('Enter setup mode')
  file.remove('boot_setup_mode')
  dofile('setup_mode.lua')
else
  -- load authentication key
  local authKey = ''
  if not pcall(function() 
    file.open('config', 'r')
    authKey = string.match(file.read('\n'), "^%s*(.-)%s*$")    
    file.close()
  end) or authKey == nil or authKey == '' then
    print('No authentication key found. Enter setup mode')
    dofile('setup_mode.lua')
  else
    blocky = require('blocky')
    blocky.init(authKey, onBlockyConnected, onBlockyDisConnected)
    authKey = nil
    
    wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
      print("\n\tWIFI - GOT IP: " .. T.IP)
      blocky.connect()
    end)

    startConnectingBlink()
    
    connectBlockyTimer = tmr.create()
    connectBlockyTimer:alarm(20000, tmr.ALARM_SINGLE, function (t)
      --boot to setup mode
      print('Fail to connect to broker')
      enterSetupMode()
    end)
  end
end



