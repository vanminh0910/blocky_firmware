local M, module = {}, ...

M.brokerHost = 'broker.getblocky.com'
M.brokerPort = 1883

M.status = 0 -- 0: initial, not connected   1: connected  2: error/offline
M.statusLedOn = 0
M.messageHandlers = {}

function M.init(authKey, onConnected, onDisconnected)
  M.authKey = authKey
  M.mqtt = mqtt.Client(M.authKey .. '_' .. node.chipid(), 30, node.chipid(), M.authKey)
  M.onConnected = onConnected
  M.onDisconnected = onDisconnected
  
  M.mqtt:on('offline', function(con) 
    print ('Broker went offline')
    M.status = 2
    M.onDisconnected()
  end)

  M.mqtt:on('message', function(conn, topic, data)
    print('Receive topic: ' .. topic .. ' data: ' .. data)
    -- remove authKey to extract topic
    local topic = string.match(topic, '/' .. M.authKey .. '/(.*)')
    print(topic)
    print(string.sub(topic, 1, string.len(node.chipid()))==''..node.chipid())
    print(string.sub(topic, 1, string.len(node.chipid())))
    -- check if this is system topic like ota or reboot or trigger setup mode    
    if string.sub(topic, 1, string.len(node.chipid()))==''..node.chipid() then
      print('System topic detected')
      local systemTopic = string.match(topic, node.chipid() .. '/(.*)')
      print(systemTopic)
      if systemTopic == 'ota' then
        print('Received ota request')
        file.open('main.lua', 'w')
        file.write(data)
        file.flush()
        file.close()
        node.compile("main.lua")
        file.remove('main.lua')
        print('OTA completed. Rebooting now...')
        M.mqtt:publish(M.getSystemTopic('ota_ack'), 'OTA completed', 0, 0, function()
          print('Published OTA ack')
          node.restart()
        end)
        
      elseif systemTopic == 'reboot' then
        print('Received reboot request')
        node.restart()
      elseif systemTopic == 'setup_mode' then
        enterSetupMode()
      elseif string.match(systemTopic, 'ota/(.*)') then
        otaIndex = string.match(systemTopic, 'ota/(.*)')
        print('Received part of ota code')
        if otaIndex == '1' then
          file.open('main_temp.lua', 'w')
        else
          file.open('main_temp.lua', 'a+')
        end
        file.write(data)
        file.flush()
        file.close()
        
        if otaIndex == '$' then
          print('OTA completed. Rebooting now...')
          node.compile("main_temp.lua")
          file.remove('main.lc')
          file.rename('main_temp.lc', 'main.lc')
          file.remove('main_temp.lua')
          file.remove('main_temp.lc')
          M.mqtt:publish(M.getSystemTopic('ota_ack'), 'OTA completed', 0, 0, function()
            node.restart()
          end)
        end
      end    
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
    M.mqtt:subscribe(M.getSystemTopic('ota/+'), 0, function() end)
    M.mqtt:subscribe(M.getSystemTopic('setup_mode'), 0, function() end)
    M.mqtt:subscribe(M.getSystemTopic('reboot'), 0, function()
      M.onConnected()
      if (M.status == 0) then
        M.status = 1
        print('Now run main user code')
        pcall(function() dofile('main.lc') end)
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
    M.messageHandlers[topic] = handler
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