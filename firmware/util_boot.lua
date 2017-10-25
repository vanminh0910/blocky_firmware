-- main firmware boot file
local module = ...

return function ()
	package.loaded[module] = nil
	module = nil
	blocky = {}
	
	require('util_load_config')()
	
	if blocky.config == nil or blocky.config.bootFlag
		or blocky.config.authKey == nil 
		or blocky.config.authKey == '' then 
		--trigger config mode
		dofile('config_mode_init.lua')
	elseif blocky.config.upgradeFirmware == true then 
		--trigger upgrade firmware mode
		dofile('upgrade_firmware_mode.lua')
	else
		wifi.setmode(wifi.STATION)
		wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
			print("WIFI connected - IP: " .. T.IP)
			require("blocky_connect")()
		end)
		--setup button D3 for triggering config mode
		gpio.trig (3, 'both',	function (level, when)
			local duration = when - lastPressTime
			if level == gpio.LOW then
				lastPressTime = tmr.now()
			end
			if level == gpio.HIGH then
				if duration > 1000000 then
					print('Config mode triggered')
					blocky.config.bootFlag = true
					dofile('util_save_config.lua')
					node.restart()
				end
			end
			gpio.trig(3, level==gpio.HIGH and 'down' or 'up')
		end)
		
		lastPressTime = tmr.now()

		print('Found auth key and device name: ' .. blocky.config.authKey .. ' ' .. blocky.config.deviceName)
		blocky.status = 0 -- 0: initial, not connected   1: connected  2: error/offline
		blocky.messageHandlers = {}
		require("blocky_init")()		

		-- start connecting blink
		connectBlinkTimer = tmr.create()
		statusLedOn = 0
		gpio.mode(4, gpio.OUTPUT)
		gpio.write(4, gpio.HIGH)
    connectBlinkTimer:alarm(300, tmr.ALARM_AUTO, function (t)
      if (statusLedOn == 1) then gpio.write(4, gpio.LOW) else gpio.write(4, gpio.HIGH) end
      statusLedOn = 1 - statusLedOn
		end)
	
		connectBlockyTimer = tmr.create()
		connectBlockyTimer:alarm(40000, tmr.ALARM_SINGLE, function (t)
			print('Fail to connect to wifi or server. Now enter setup mode.')
			require('util-joinWifiList')
			blocky.config.bootFlag = true
			dofile('util_save_config.lua')
			node.restart()
		end)
	end
end