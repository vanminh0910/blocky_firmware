local fileToDownload = {
  {
    fileName = 'init.lua', 
    host = 'raw.githubusercontent.com', 
    port = 443, 
    url = 'vanminh0910/blocky_firmware/master/init.lua'
  }, {
    fileName = 'setup_mode.lua', 
    host = 'raw.githubusercontent.com', 
    port = 443, 
    url = 'vanminh0910/blocky_firmware/master/setup_mode.lua'
  }, {
    fileName = 'index.html', 
    host = 'raw.githubusercontent.com', 
    port = 443, 
    url = 'vanminh0910/blocky_firmware/master/index.html'
  }, 
}

function downloadFile(fileName, host, port, url, callback)
  local fileTemp = fileName .. '_temp'
  file.remove(fileTemp)
  file.open(fileTemp, "w+")

  print('Downloading file ' .. fileName)
    
  payloadFound = false
  payLoadSize = 0
  payloadWritten = 0
  
  tlsConn = net.createConnection(net.TCP, 1) --tls.createConnection() 

  local connTimeOutTimer = tmr.create()
  local readTimeOutTimer = tmr.create()
   
  tlsConn:on("receive", function(conn, payload)
    if (payloadFound == true) then
      file.write(payload)
      file.flush()
      payloadWritten = payloadWritten + string.len(payload)
    else
      if (string.find(payload,"\r\n\r\n") ~= nil and string.find(payload, 'HTTP/1.1 200 OK') ~= nill) then      
        payLoadSize = string.match(payload, "Content%-Length: (%d+)\r\n") + 0
        local data = string.sub(payload, string.find(payload,"\r\n\r\n") + 4)
      
        file.write(data)
        file.flush()
        payloadFound = true
        payloadWritten = payloadWritten + string.len(data)
      else
        print('Receive data error. Cancel firmware downloading.')
        tmr.unregister(readTimeOutTimer)
        conn = nil
        payload = nil
        file.close()
        collectgarbage()        
      end      
    end

    if payloadWritten >= payLoadSize then
      tmr.unregister(readTimeOutTimer)
      conn = nil
      file.close()
      collectgarbage()
      print('File downloaded')
      callback()
    end

    payload = nil
    collectgarbage()
  end)

  tlsConn:on("disconnection", function(conn) 
    print("Connection closed")
    conn = nil
    file.close()
    collectgarbage()
    callback()
  end)
  
  tlsConn:on("connection", function(conn)
      tmr.unregister(connTimeOutTimer)
      conn:send("GET /".. url .." HTTP/1.1\r\n"..
            "Host: "..host.."\r\n"..
            "Connection: close\r\n"..
            "Accept: */*\r\n\r\n")
      readTimeOutTimer:register(15000, tmr.ALARM_SINGLE, function (t) 
        print('Receive data timeout. Cancel firmware downloading.')
        t:unregister()
        conn = nil
        file.close()
        collectgarbage()
      end)
      readTimeOutTimer:start()
  end)
    
  --print ('Connecting to host: ' .. host .. ' on port ' .. port)
  tlsConn:connect(port, host)
  connTimeOutTimer:register(10000, tmr.ALARM_SINGLE, function (t)
      print('Connection timeout. Cancel firmware downloading.')
      t:unregister()
      conn = nil
      file.close()
      collectgarbage()
  end)
  connTimeOutTimer:start()

end

function downloadFirmware()
  for index, info in ipairs(fileToDownload) do
    if fileToDownload[index].done == nil then
      downloadFile(info.fileName, info.host, info.port, info.url, downloadFirmware)
      fileToDownload[index]['done'] = true
      return
    end
  end

  for index, info in ipairs(fileToDownload) do
    local fileTemp = info.fileName .. '_temp'
    file.remove(info.fileName)
    file.rename(fileTemp, info.fileName)
    file.remove(fileTemp)    
  end
  collectgarbage()
  print("All firmware files were downloaded successfully. Now reboot...")
  node.restart()
end

downloadFirmware()
