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
  'util_load_config.lua',
  'util_on_connected.lua',
  'util_save_config.lua',
  'module_thingspeak.lua'
}

index = 1

function downloadFile()
  require('util_download_file')('http://www.getblocky.com/firmwares/latest/' .. listFiles[index],
  listFiles[index], function()  
    index = index + 1
    if index > table.getn(listFiles) then
      print('Upgrade firmware done. Now reboot.')
      node.restart()
    else
      downloadFile()
    end
  end,
  function() 
    print('Failed to download file: ' .. 'http://www.getblocky.com/firmwares/latest/' .. listFiles[index])
    node.restart()
  end)
end

downloadFile()