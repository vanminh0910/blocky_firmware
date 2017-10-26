gpio.mode(4, gpio.OUTPUT)
gpio.write(4, gpio.LOW)

if blocky.config == nil then blocky.config = {} end

if blocky.config.deviceName == nil or blocky.config.deviceName == '' then
  blocky.config.deviceName = 'blocky_' .. node.chipid()
end

if blocky.config.bootFlag then
  blocky.config.bootFlag = false
  require('util_save_config')()
end

wifi.setmode(wifi.STATIONAP)
wifi.ap.config({ssid=blocky.config.deviceName, pwd='12345678'})

rebootTimer = tmr.create()
rebootTimer:alarm(180000, tmr.ALARM_SINGLE, function (t)
  print('No activity found in config mode. Restarting...')
  node.restart()
end)

-- factory reset if config button pushed longer than 3 seconds
do
  -- pin 3 is connected to config mode button
  local pin, pulse1, duration, now = 3, 0, 0, tmr.now  
  gpio.mode(pin,gpio.INT)
  local function configBtnCb(level, pulse2)
    if level == gpio.LOW then
      pressed = true
      checkConfigPressedTimer = tmr.create()
      checkConfigPressedTimer:alarm(5000, tmr.ALARM_SINGLE, function (t)
        if pressed then
          print('Removing user code in progress')
          file.remove('main.lua')
          -- Fast blink to let user know 
          clearCodeTimer = tmr.create()
          statusLedOn = 0
          gpio.write(4, gpio.HIGH)
          clearCodeBlinkCount = 0
          clearCodeTimer:alarm(100, tmr.ALARM_AUTO, function (t)
            if (statusLedOn == 1) then gpio.write(4, gpio.LOW) else gpio.write(4, gpio.HIGH) end
            statusLedOn = 1 - statusLedOn
            clearCodeBlinkCount = clearCodeBlinkCount + 1
            if clearCodeBlinkCount > 25 then
              tmr.unregister(clearCodeTimer)
              clearCodeTimer = nil
              gpio.write(4, gpio.LOW)
              print('Removing done')
            end
          end)
        end
      end)
    else
      pressed = nil
    end    
    gpio.trig(pin, level == gpio.HIGH  and 'down' or 'up')
  end
  gpio.trig(pin, 'down', configBtnCb)
end

srv=net.createServer(net.TCP) 

srv:listen(80, function(conn) 
  local responseBytes = 0
  local method=''
  local url=''
  local vars=''

	conn:on('receive', function(conn, payload) 
    if rebootTimer ~= nil then
      tmr.unregister(rebootTimer)
    end

    if string.len(payload) > 2000 then
        print('Payload received is too big')
        conn:send('HTTP/1.1 404 file not found')
        responseBytes = -1
        return
    end
    _, _, method, url, vars = string.find(payload, '([A-Z]+) /([^?]*)%??(.*) HTTP')

    if (url == '') then
      -- Only support one sending one file
      url='index.html'
      responseBytes = 0
      conn:send('HTTP/1.1 200 OK\r\n\Access-Control-Allow-Headers: Content-Type\r\nAccess-Control-Allow-Methods: GET, POST, OPTIONS\r\nAllow-Control-Allow-Origin: *\r\n\Content-type: text/html\r\n\r\n')
      return
    elseif (url == 'set') then
      -- Check if wifi-credentials have been supplied
      if require("config_mode_parse_args")(vars) then
        conn:send('HTTP/1.1 200 OK\r\n\r\n<h1>Config saved. Now rebooting...</h1>')
        tmr.create():alarm(2000, tmr.ALARM_SINGLE, function (t) node.restart() end)
      end
      return
    elseif (url == 'aplist') then
      local accessPointsList = {}
      wifi.sta.getap(function(t) 
        for ssid,v in pairs(t) do
          local ap = {}
          local authmode, rssi, bssid, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
          ap.ssid = ssid
          ap.rssi = rssi
          table.insert(accessPointsList, ap)            
        end
        responseBytes = -1
        conn:send('HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Headers: Content-Type\r\nAccess-Control-Allow-Methods: GET, POST, OPTIONS\r\nAccess-Control-Allow-Origin: *\r\n\r\n')
        conn:send(sjson.encode(accessPointsList))
        conn:send('\r\n\r\n')
        conn:close()
      end)
    elseif (url == 'status') then
      -- TODO: need to check wifi status
      print('return status')
    elseif (url == 'favicon.ico') then
      conn:send('HTTP/1.1 404 file not found')
      responseBytes = -1
      return
    else
      conn:send('HTTP/1.1 404 not found')
      responseBytes = -1
      return
    end
  end)
    
	conn:on('sent', function(conn) 
    rebootTimer:stop()
    if responseBytes >= 0 and method == 'GET' then
      if file.open(url, 'r') then            
        file.seek('set', responseBytes)
        local line = file.read(512)
        file.close()
        if line then
          conn:send(line)
          responseBytes = responseBytes + 512
          if (string.len(line)==512) then
            return
          end
        end
      end        
    end
    conn:close() 
  end)
end)

print('Config mode is started and can be accessed via url: http://192.168.4.1/')

	



