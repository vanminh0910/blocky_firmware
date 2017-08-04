blocky = {}
blocky.brokerHost = 'mqtt.easytech.vn'
blocky.brokerPort = 1883

blocky.authKey = 'seagull'

blocky.status = 0 -- 0: initial, not connected   1: connected  2: error/offline
blocky.messageHandlers = {}

blocky.mqtt = mqtt.Client(blocky.authKey .. '_' .. node.chipid(), 120, blocky.authKey, blocky.authKey)

function blocky.getTopic(topic)
  return '/' .. blocky.authKey .. '/' .. node.chipid() .. '/' .. topic
end

function blocky.sendMessage(topic, data)
  if (blocky.status ~= 1) then
    print('Cannot send message as not connected to broker')
    return
  end
  if (topic == 'ota' or topic == 'reboot') then
    print('Cannot send message using reserved topics (ota, reboot)')
    return
  end
  blocky.mqtt:publish(blocky.getTopic(topic), data, 0, 0)
end

function blocky.subscribe(topic, handler)
  if (topic == 'ota' or topic == 'reboot' or topic == 'setup_mode') then
    print('Cannot subscribe to reserved topics (ota, reboot)')
    return
  end
  if handler ~= nil then
    blocky.mqtt:subscribe(blocky.getTopic(topic), 0, nil)
    blocky.messageHandlers[blocky.getTopic(topic)] = handler
  end
end

function blocky.unsubscribe(topic)
  blocky.mqtt:unsubscribe(blocky.getTopic(topic))
  blocky.messageHandlers[blocky.getTopic(topic)] = nil
end

function blocky.enterSetupMode() 
  print('Config mode triggered. Reboot to config mode now')
  file.open('boot_setup_mode', 'w')
  file.writeline('')
  file.flush()   
  file.close()
  node.restart()
end

-------------------------------- main code starts here -----------------------
gpio.mode(4, gpio.OUTPUT)
gpio.write(4, gpio.HIGH)
blocky.statusLedOn = 0

gpio.mode(3, gpio.INT)
gpio.trig(3, 'down', function(level)
    gpio.trig(3, 'none', function() end)
    blocky.enterSetupMode()
end)

-- check if boot to setup mode is triggered
if file.exists('boot_setup_mode') or not file.exists('config') then
  print('Enter setup mode')
  file.remove('boot_setup_mode')
  dofile('setup_mode.lua')
else
  -- load authentication key
  if not pcall(function() 
    file.open('config', 'r')
    local configJson = sjson.decode(file.read('\n'))
    blocky.authKey = configJson.authKey 
    file.close()
  end) or blocky.authKey == nil or blocky.authKey == '' then
    print('No authentication key found. Enter setup mode')
    dofile('setup_mode.lua')
  else
    wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
      print("\n\tSTA - GOT IP".."\n\tStation IP: "..T.IP)
      tmr.unregister(connectWifiTimer)
      blocky.mqtt:on('offline', function(con) 
        print ('MQTT went offline') 
        blocky.status = 2
      end)

      blocky.mqtt:on('message', function(conn, topic, data)
        print('Receive topic: ' .. topic .. ' data: ' .. data)
        if topic == blocky.getTopic('ota') then
          print('Received ota request')
          --print('OTA code: ' .. data)
          file.open('main.lua', 'w')
          file.write(data)
          file.flush()
          file.close()
          print('OTA completed. Rebooting now...')
          node.restart()
        elseif topic == blocky.getTopic('reboot') then
          print('Received reboot request')
          node.restart()
        elseif topic == blocky.getTopic('setup_mode') then
          blocky.enterSetupMode()
        else
          --for key,value in pairs(message_handlers) do print(key,value) end
          if (blocky.messageHandlers[topic] ~= nil) then
            pcall(message_handlers[topic](topic, data))
          end
        end
          
      end)

      blocky.mqtt:connect(blocky.brokerHost, blocky.brokerPort, 0, function(conn) 
        tmr.unregister(connectBrokerTimer)
        print('Connected to MQTT broker')
        --clear error connection timer
        blocky.mqtt:subscribe(blocky.getTopic('ota'), 0, function()
          blocky.mqtt:subscribe(blocky.getTopic('setup_mode'), 0, function()
            blocky.mqtt:subscribe(blocky.getTopic('reboot'), 0, function()
              tmr.unregister(connectBlinkTimer)
              gpio.write(4, gpio.HIGH)
              -- start main user code here
              if (blocky.status == 0) then
                print('Now run main user code')
                pcall(function() dofile('main.lua') end)
              end
              blocky.status = 1
            end)
          end)
        end)
      end)

      --Start a broker connection timer for 15 seconds, after 15 seconds, start another blink timer for blinking led status every 0.3 second
      connectBrokerTimer = tmr.create()
      connectBrokerTimer:alarm(15000, tmr.ALARM_SINGLE, function (t)
        --boot to setup mode
        print('Fail to connect to broker')
        blocky.status = 0
      end)
    end)

    wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
      --print("\n\tSTA - DISCONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
      --  T.BSSID.."\n\treason: "..T.reason)
      if blocky.status ~= 0 then
        blocky.status = 2
      end
    end)
    
    connectBlinkTimer = tmr.create()
    connectBlinkTimer:alarm(100, tmr.ALARM_AUTO, function (t)
      if (blocky.statusLedOn == 1) then gpio.write(4, gpio.LOW) else gpio.write(4, gpio.HIGH) end
      blocky.statusLedOn = 1 - blocky.statusLedOn
    end)

    connectWifiTimer = tmr.create()
    connectWifiTimer:alarm(10000, tmr.ALARM_SINGLE, function (t)
      --boot to setup mode
      print('No wifi connection. Continue to run user main code.')
      pcall(function() dofile('main.lua') end)
    end)
  end
end



