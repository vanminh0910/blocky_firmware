-------------------------------- main code starts here -----------------------
statusLedOn = 0
gpio.mode(4, gpio.OUTPUT)
gpio.write(4, gpio.HIGH)

wifi.setmode(wifi.STATION)

do
  -- pin 3 is connected to config mode button
  local pin, pulse1, duration, now = 3, 0, 0, tmr.now
  gpio.mode(pin,gpio.INT)
  local function configBtnCb(level, pulse2)
    duration = pulse2 - pulse1
    if level == gpio.HIGH and duration > 1000000 then
      dofile('trigger_setup_mode.lua')
    end
    pulse1 = pulse2
    gpio.trig(pin, level == gpio.HIGH  and "down" or "up")
  end
  gpio.trig(pin, "down", configBtnCb)
end

function startConnectingBlink()
  connectBlinkTimer = tmr.create()
  connectBlinkTimer:alarm(300, tmr.ALARM_AUTO, function (t)
    if (statusLedOn == 1) then gpio.write(4, gpio.LOW) else gpio.write(4, gpio.HIGH) end
    statusLedOn = 1 - statusLedOn
  end)
end

function onBlockyConnected()
  dofile('on_blocky_connected.lua')
end

function onBlockyDisConnected()
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
end

-- check if boot to setup mode is triggered
if file.exists('boot_setup_mode') or not file.exists('config') then
  print('Boot setup mode file found. Now enter setup mode')
  file.remove('boot_setup_mode')
  --dofile ("dns-liar.lua")
  dofile('setup_mode.lua')
else
  -- load authentication key
  local authKey = ''
  local deviceName = ''
  if not pcall(function() 
    file.open('config', 'r')
    authKey = string.match(file.read('\n'), "^%s*(.-)%s*$")
    deviceName = string.match(file.read('\n'), "^%s*(.-)%s*$")
    if deviceName == nil or deviceName == '' then
        deviceName = 'blocky_' .. node.chipid()
    end
    print('Found auth key and device name: ' .. authKey .. ' ' .. deviceName)
    file.close()
  end) or authKey == nil or authKey == '' then
    print('No authentication key found. Enter setup mode')
    dofile('setup_mode.lua')
  else
    blocky = require('blocky')
    blocky.init({authKey=authKey, deviceName=deviceName}, onBlockyConnected, onBlockyDisConnected)
    authKey = nil
    
    wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
      print("\n\tWIFI - GOT IP: " .. T.IP)
      blocky.connect()
    end)

    startConnectingBlink()
    
    connectBlockyTimer = tmr.create()
    connectBlockyTimer:alarm(40000, tmr.ALARM_SINGLE, function (t)
      --boot to setup mode
      print('Fail to connect to broker')
      dofile('trigger_setup_mode.lua')
    end)
  end
end

collectgarbage()



