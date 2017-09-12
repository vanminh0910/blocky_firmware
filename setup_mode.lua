gpio.mode(4, gpio.OUTPUT)
gpio.write(4, gpio.LOW)
wifi.setmode(wifi.STATIONAP)
local cfg={}
cfg.ssid='BLOCKY_'..node.chipid()
wifi.ap.config(cfg)

print('Opening setup mode portal')

local rebootExpiry = 300000

rebootTimer = tmr.create()
rebootTimer:alarm(rebootExpiry, tmr.ALARM_SINGLE, function (t)
  print('No activity found in setup mode. Restarting...')
  node.restart()
end)

function parseRequestArgs(args)
  if args == nil or args == '' then
    return false
  end

  ssid, password, authKey = string.match(args, 'ssid\=([^&?]*)&password\=([^&?]*)&authKey\=([^&?]*)')
  
  local function unescape (str)
    str = string.gsub (str, "+", " ")
    str = string.gsub (str, "%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
    str = string.gsub (str, "\r\n", "\n")
    return str
  end

  ssid = unescape(ssid)
  password = unescape(password)
  authKey = unescape(authKey)

  if ssid == nil or ssid == '' or password == nil or authKey == nil or authKey == '' then
    return false
  end

  passwordLength = string.len(password)
  if passwordLength ~= 0 and (passwordLength < 8 or passwordLength > 64) then
      print('Password length should be between 8 and 64 characters')
      return false
  end

  print('New WiFi credentials received')
  print('-----------------------------')
  print('wifi_ssid     : ' .. ssid)
  print('wifi_password : ' .. password)
  print('auth_key : ' .. authKey)

  wifi.sta.config({['ssid']=ssid, ['pwd']=password, ['save']=true}) 

  file.open('config', 'w')
  file.writeline(authKey)
  file.flush()
  file.close()
  return true
end

srv=net.createServer(net.TCP) 
srv:listen(80, function(conn) 
  local responseBytes = 0
  local method=''
  local url=''
  local vars=''

  conn:on('receive',function(conn, payload)
    if rebootTimer ~= nil then
      tmr.unregister(rebootTimer)
    end    
    reconnectTimer = tmr.create()
    reconnectTimer:alarm(rebootExpiry, tmr.ALARM_SINGLE, function (t)
      node.restart()
    end)

    if string.len(payload) > 2000 then
        print('payload is too big')
        conn:send('HTTP/1.1 404 file not found')
        responseBytes = -1
        return
    end
    _, _, method, url, vars = string.find(payload, '([A-Z]+) /([^?]*)%??(.*) HTTP')

    if (url == '') then
      -- Only support one sending one file
      url='index.html'
      responseBytes = 0
      conn:send('HTTP/1.1 200 OK\r\n\r\n')
      return
    elseif (url == 'set') then
      -- Check if wifi-credentials have been supplied
      if parseRequestArgs(vars) then
        conn:send('HTTP/1.1 200 OK\r\n\r\nConfig saved. Now rebooting...')
        print('<h1>Saved config. Now restart.</h1>')
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
        conn:send('HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n')
        conn:send(sjson.encode(accessPointsList))
        conn:send('\r\n\r\n')
        conn:close()
      end)
    elseif (url == 'status') then
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
  
  conn:on('sent',function(conn) 
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
print('Setup mode is started and can be accessed via url: http://192.168.4.1/')


