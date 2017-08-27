local M, module = {}, ...

M.brokerHost = 'staging.broker.blocky.easytech.vn'
M.brokerPort = 1883

M.status = 0 -- 0: initial, not connected   1: connected  2: error/offline
M.statusLedOn = 0
M.messageHandlers = {}

function M.init(authKey, onConnected, onDisconnected)
  M.authKey = authKey
  M.mqtt = mqtt.Client(M.authKey .. '_' .. node.chipid(), 120, node.chipid(), M.authKey)
  M.onConnected = onConnected
  M.onDisconnected = onDisconnected
  
  M.mqtt:on('offline', function(con) 
    print ('Broker went offline')
    M.status = 2
    M.onDisconnected()
  end)

  M.mqtt:on('message', function(conn, topic, data)
    print('Receive topic: ' .. topic .. ' data: ' .. data)
    if topic == M.getSystemTopic('ota') then
      print('Received ota request')
      --print('OTA code: ' .. data)
      file.open('main.lua', 'w')
      file.write(data)
      file.flush()
      file.close()
      print('OTA completed. Rebooting now...')
      node.restart()
    elseif topic == M.getSystemTopic('reboot') then
      print('Received reboot request')
      node.restart()
    elseif topic == M.getSystemTopic('setup_mode') then
      enterSetupMode()
    else
      --for key,value in pairs(message_handlers) do print(key,value) end
      if (M.messageHandlers[topic] ~= nil) then
        pcall(function() M.messageHandlers[topic](topic, data) end)
      end
    end      
  end)
end

function M.getTopic(topic)
  return '/' .. M.authKey .. '/' .. topic
end

function M.getSystemTopic(topic)
  return '/' .. M.authKey .. '/' .. node.chipid() .. '/' .. topic
end

function M.connect()
  print('Connecting to MQTT broker')
  M.mqtt:connect(M.brokerHost, M.brokerPort, 0, function(conn) 
    print('Connected to MQTT broker')
    local registerData = '{"chipId": ' .. node.chipid() .. ', "firmware": "1.0", "type": "blocky"}'
    M.mqtt:publish(M.getTopic('register'), registerData, 0, 0)
    M.mqtt:subscribe(M.getSystemTopic('ota'), 0, function() end)
    M.mqtt:subscribe(M.getSystemTopic('setup_mode'), 0, function() end)
    M.mqtt:subscribe(M.getSystemTopic('reboot'), 0, function()
      M.onConnected()
      if (M.status == 0) then
        print('Now run main user code')
        pcall(function() dofile('main.lua') end)
      end
      M.status = 1
    end)
  end)
end

function M.sendMessage(topic, data)
  if (M.status ~= 1) then
    print('Cannot send message as not connected to broker')
    return
  end
  M.mqtt:publish(M.getTopic(topic), data, 0, 0)
end

function M.subscribe(topic, handler)
  if (topic == 'ota' or topic == 'reboot' or topic == 'setup_mode') then
    print('Cannot subscribe to reserved topics (ota, reboot)')
    return
  end
  if handler ~= nil then
    M.mqtt:subscribe(M.getTopic(topic), 0, nil)
    M.messageHandlers[M.getTopic(topic)] = handler
  end
end

function M.log(data)
  if (M.status ~= 1) then
    print('Cannot send message as not connected to broker')
    return
  end
  M.mqtt:publish(M.getSystemTopic('log'), data, 0, 0)
end

function M.unsubscribe(topic)
  M.mqtt:unsubscribe(M.getTopic(topic))
  M.messageHandlers[M.getTopic(topic)] = nil
end

return M 