local M, module = {}, ...

M.brokerHost = 'staging.broker.getblocky.com'
M.brokerPort = 1883

M.status = 0 -- 0: initial, not connected   1: connected  2: error/offline
--M.statusLedOn = 0
M.messageHandlers = {}

local function getTopic(topic, isSystemTopic)
  if isSystemTopic then
    return M.config.authKey .. '/sys/' .. topic
  else
    return M.config.authKey .. '/user/' .. topic
  end
end

function M.init(config, onConnected, onDisconnected)
  M.config = config
  M.mqtt = mqtt.Client(M.config.authKey .. '_' .. node.chipid(), 30, node.chipid(), M.config.authKey)
  M.onConnected = onConnected
  M.onDisconnected = onDisconnected
  
  M.mqtt:on('offline', function(con) 
    print ('Broker went offline')
    M.status = 2
    M.onDisconnected()
  end)

  M.mqtt:on('message', function(conn, topic, data)
    print('Receive topic: ' .. topic)
    if safeModeTimer ~= nil then
      tmr.unregister(safeModeTimer)
      safeModeTimer = nil
      collectgarbage()
    end
    local matchPattern = string.gsub(getTopic('(.*)', false), "%-", "%%-")
    if string.match(topic, matchPattern) then
      local topicParsed = string.match(topic, matchPattern)
      if topicParsed and M.messageHandlers[topicParsed] ~= nil then
        pcall(function() M.messageHandlers[topicParsed](topicParsed, data) end)
      end
    else
      matchPattern = string.gsub(getTopic('', true), "%-", "%%-")
      -- if receive system command
      if topic == getTopic(node.chipid()..'/run', true) or topic == getTopic(node.chipid()..'/ota', true) then
        matchPattern = string.gsub(getTopic(node.chipid()..'/(.*)', true), "%-", "%%-")
        local topicParsed = string.match(topic, matchPattern)
        if topicParsed == 'run' then
          print('Received run request')
          local otaAckMsg = '{"chipId":"' .. node.chipid() .. '", "event":"run_ack"}';
          M.mqtt:publish(getTopic('', true), otaAckMsg, 0, 0, function()
            print('Published RUN ack')
          end)
          node.input(data)
        elseif topicParsed == 'ota' then
          print('Received ota request')
          file.open('main_temp.lua', 'w')
          file.write(data)
          file.flush()
          file.close()
          file.remove('main.lua')
          file.rename('main_temp.lua', 'main.lua')
          --file.remove('main_temp.lua')
          print('OTA completed. Rebooting now...')
          local otaAckMsg = '{"chipId":"' .. node.chipid() .. '", "event":"ota_ack"}';
          M.mqtt:publish(getTopic('', true), otaAckMsg, 0, 0, function()
            print('Published OTA ack')
            node.restart()
          end)
        end        
      elseif string.match(topic, matchPattern..node.chipid()..'/ota/(.*)') then -- if receive multipart ota command
        local otaIndex = string.match(topic, matchPattern..node.chipid()..'/ota/(.*)')
        print('Received part of ota code: ' .. otaIndex)
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
          file.rename('main_temp.lua', 'main.lua')
          --node.compile("main_temp.lua")
          --file.remove('main.lc')
          --file.rename('main_temp.lc', 'main.lc')
          file.remove('main_temp.lua')
          --file.remove('main_temp.lc')
          local otaAckMsg = '{"chipId":"' .. node.chipid() .. '", "event":"ota_ack"}';
          M.mqtt:publish(getTopic('', true), otaAckMsg, 0, 0, function()
            print('Published OTA ack')
            node.restart()
          end)
        end
      elseif string.match(topic, matchPattern..node.chipid()..'/run/(.*)') then
        local runIndex = string.match(topic, matchPattern..node.chipid()..'/run/(.*)')
        if runIndex == '1' then
          file.open('run_temp.lua', 'w')
        else
          file.open('run_temp.lua', 'a+')
        end
        file.write(data)
        file.flush()
        file.close()
        
        if runIndex == '$' then
          print('Run completed. Executing...')
          dofile('run_temp.lua')
          file.remove('run_temp.lua')
          local runAckMsg = '{"chipId":"' .. node.chipid() .. '", "event":"run_ack"}';
          M.mqtt:publish(getTopic('', true), runAckMsg, 0, 0, function()
            print('Published run ack')
          end)
        end
      elseif topic == getTopic(node.chipid()..'/rename', true) then
        print('Received rename request')
        if data == nil or data == '' then
          print('Invalid name')
        else
          file.open('config', 'w')
          file.writeline(M.config.authKey)
          file.writeline(data)
          file.flush()
          file.close()
        end        
      elseif topic == getTopic(node.chipid()..'/reboot', true) then
        print('Received reboot request')
        node.restart()
      elseif topic == getTopic(node.chipid()..'/upload', true) then
        print('Received upload request')
      else
        print('Received invalid request')
      end
    end
  end)
end

function M.connect()
  print('Connecting to MQTT broker')
  M.mqtt:connect(M.brokerHost, M.brokerPort, 0, function(conn) 
    print('Connected to MQTT broker')
    local modulesList = ''
    for filename, filesize in pairs(file.list()) do
      if string.find(filename, 'module_')~=nil then
        modulesList = filename .. ',' .. modulesList
      end
    end
    local registerData = '{"event":"register", "chipId": "' .. node.chipid() .. 
      '", "firmware": "1.0", "name":"' .. M.config.deviceName .. '", "modules": "'.. 
      modulesList .. '", "type": "blocky_esp8266"}'
    M.mqtt:publish(getTopic('', true), registerData, 1, 0)
    M.mqtt:subscribe(getTopic(node.chipid()..'/#', true), 1, function()
      M.onConnected()
      if (M.status == 0) then
        M.status = 1
        local bootReason1, bootReason2 = node.bootreason()
        if bootReason1 == 2 and (bootReason2 == 1 or bootReason2 == 2 or bootReason2 == 3) then
          print('Crash found. Boot to safe mode (uploaded code is not run). Auto reboot in 3 minutes if no activity')
          M.log('Crash found. Boot to safe mode (uploaded code is not run). Auto reboot in 3 minutes if no activity')
          safeModeTimer = tmr.create()
          safeModeTimer:alarm(180000, tmr.ALARM_SINGLE, function (t)
            node.restart()
          end)
        else
          print('Now run main user code')
          tmr.alarm(1, 1, 0, function() 
            local runSuccess, runError = pcall(function() dofile('main.lua') end) 
            print(runSuccess)
            print(runError)
            if not runSuccess then
              M.log('Failed to run user code. Error: ' .. runError)
            end
          end)
        end        
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
  M.mqtt:publish(getTopic(topic, false), data, 0, 0)
end

function M.subscribe(topic, handler)
  if handler ~= nil then
    M.mqtt:subscribe(getTopic(topic, false), 0, nil)
    M.messageHandlers[topic] = handler
  end
end

function M.log(data)
  if (M.status ~= 1) then
    print('Cannot send message as not connected to broker')
    return
  end
  M.mqtt:publish(getTopic('', true), '{"event":"log", "chipId":"' .. node.chipid() .. '","data":"' .. data .. '"}', 0, 0)
end

function M.unsubscribe(topic)
  M.mqtt:unsubscribe(getTopic(topic, false))
  M.messageHandlers[topic] = nil
end

return M 