gpio.mode(4, gpio.OUTPUT)
gpio.write(4, gpio.LOW)

if blocky.config.upgradeFimrware then
  blocky.config.upgradeFimrware = false
  dofile('util_save_config.lua')
end

-- Fast blink to let user know 
upgradeBlinkTimer = tmr.create()
statusLedOn = 0
gpio.write(4, gpio.HIGH)
upgradeBlinkTimer:alarm(100, tmr.ALARM_AUTO, function (t)
  if (statusLedOn == 1) then gpio.write(4, gpio.LOW) else gpio.write(4, gpio.HIGH) end
  statusLedOn = 1 - statusLedOn
end)

require('util_download_file')('http://www.getblocky.com/firmwares/latest/upgrade_firmware.lua',
  'upgrade_firmware.lua',
  function() dofile('upgrade_firmware.lua') end,
  function() 
    print('Failed to download firmware')
    node.restart()
  end)

	



