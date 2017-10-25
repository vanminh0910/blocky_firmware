local module  = ...

return function (args)
	package.loaded[module]=nil
	module = nil
	if args == nil or args == '' then
    return false
  end

  local ssid, password, authKey, deviceName = string.match(args, 'ssid\=([^&?]*)&password\=([^&?]*)&authKey\=([^&?]*)&deviceName\=([^&?]*)')
  
  local function unescape (str)
    if str == '' or str == nil then
      return str
    end
    str = string.gsub (str, "+", " ")
    str = string.gsub (str, "%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
    str = string.gsub (str, "\r\n", "\n")
    return str
  end

  ssid = unescape(ssid)
  password = unescape(password)
  authKey = unescape(authKey)
  deviceName = unescape(deviceName)

  if (deviceName == nil or deviceName == '') and (blocky.config.deviceName == nil or blocky.config.deviceName == '') then
    deviceName = 'blocky_' .. node.chipid()
  end

  if ssid == nil or ssid == '' or password == nil or authKey == nil or authKey == '' then
    return false
  end

  local passwordLength = string.len(password)
  if passwordLength ~= 0 and (passwordLength < 8 or passwordLength > 64) then
      print('Password length should be between 8 and 64 characters')
      return false
  end

  print('New WiFi credentials received')
  print('-----------------------------')
  print('wifi_ssid     : ' .. ssid)
  print('wifi_password : ' .. password)
  print('auth_key : ' .. authKey)
  print('device name : ' .. deviceName)  
  
  wifi.sta.config({['ssid']=ssid, ['pwd']=password, ['save']=true})

  blocky.config.authKey = authKey
  blocky.config.deviceName = deviceName
  require('util_save_config.lua')()
  return true
end
