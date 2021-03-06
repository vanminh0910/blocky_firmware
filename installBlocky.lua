
WIFI_SSID = "Your Wifi Access Point"
WIFI_PASSWORD = "Your Wifi Password"
BLOCKY_AUTHKEY = "Your AuthKey. Open your profile at play.getblocky.com"

--This code will format your Flash and install Blocky firmware needed to do your first IoT project.
-- A heartful welcome from Blocky Team , have fun and be creative !

file.format()


wifi_ap={}
wifi_ap.ssid= WIFI_SSID
wifi_ap.pwd= WIFI_PASSWORD
wifi_ap.save=true

blocky = {}
blocky.config = {}
blocky.config.authKey = BLOCKY_AUTHKEY



index = 1
	


listFiles = {
  'blocky_connect.lua',
  'blocky_init.lua',
  'blocky_on_message.lua',
  'blocky_on_offline.lua',
  'config_mode_init.lua',
  'config_mode_parse_args.lua',
  'index.html',
  'init.lua',
  'upgrade_firmware_mode.lua',
  'util_boot.lua',
  'util_download_file.lua',
  'util_get_topic.lua',
  'util_load_config.lua',
  'util_on_connected.lua',
  'util_save_config.lua',
  'module_thingspeak.lua'
}

function installBlocky()

    index = 1

    function downloadFileList()
        downloadFile('http://www.getblocky.com/firmwares/latest/' .. listFiles[index],
        listFiles[index], function()  
            index = index + 1
            if index > table.getn(listFiles) then
              print('Upgrade firmware done. Now reboot.')
              node.restart()
            else
              downloadFileList()
            end
          end,
          function() 
            print('Failed to download file: ' .. 'http://www.getblocky.com/firmwares/latest/' .. listFiles[index])
            --node.restart()
            
          end)
    end
    function downloadFile(url, fileName, onCompleted, onError)
            
            print('Downloading: ' .. fileName .. ' from ' .. url)
        
            http.get(url, nil, function(code, data)      
            if (code ~= 200) then
              if (onError) then
                onError()
                collectgarbage()
              end
              return
            end    
            local fd = file.open(fileName, "w+"); fd:write(data); fd:flush() ; fd:close()  
            collectgarbage()
            print('Download completed')
            if (onCompleted) then
              onCompleted()
            end
          end)
    end
        
        
        
    file.remove('config')
    downloadFileList()


end


wifi.setmode(wifi.STATION)
wifi.sta.config(wifi_ap)


wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
    print("WIFI connected - IP: " .. T.IP)
    print("Installing Blocky")
    tmr.delay(2000000)
    installBlocky()
    userConfig = '{"authKey":"' .. BLOCKY_AUTHKEY .. '","deviceName":""}'

    local fd = file.open('config', "w+"); fd:write(userConfig); fd:flush() ; fd:close()  
end)

wifi.sta.connect()
