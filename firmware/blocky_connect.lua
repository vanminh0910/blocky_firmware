local module  = ...

return function ()
	package.loaded[module]=nil
	module = nil
	print('Connecting to server')
	blocky.mqtt:connect('broker.getblocky.com',	1883, 0, function (conn)		
		print('Connected to server')
		local modulesList = ''
		for filename, filesize in pairs(file.list()) do
			if string.find(filename, 'module_')~=nil then
				modulesList = filename .. ',' .. modulesList
			end
		end
		local registerData = '{"event":"register", "chipId": "' .. node.chipid() 
			.. '", "firmware": "1.0", "name":"' .. blocky.config.deviceName .. '", "modules": "'
			.. modulesList ..  '", "type": "blocky_esp8266"}'
		blocky.mqtt:publish(require('util_get_topic')('', true), registerData, 1, 0)
		blocky.mqtt:subscribe(require('util_get_topic')(node.chipid()..'/#', true), 1, function()
			require('util_on_connected')()
			if (blocky.status == 0) then
				blocky.status = 1
				local bootReason1, bootReason2 = node.bootreason()
				if bootReason1 == 2 and (bootReason2 == 1 or bootReason2 == 2 or bootReason2 == 3) then
					print('Crash found. Boot to safe mode (uploaded code is not run). Auto reboot in 3 minutes if no activity')
					blocky.log('Crash found. Boot to safe mode (uploaded code is not run). Auto reboot in 3 minutes if no activity')
					safeModeTimer = tmr.create()
					safeModeTimer:alarm(180000, tmr.ALARM_SINGLE, function (t)
						node.restart()
					end)
				else
					print('Now run user uploaded code')
					tmr.alarm(1, 1, 0, function() 
						local runSuccess, runError = pcall(function() dofile('main.lua') end) 
						if not runSuccess then
							blocky.log('Failed to run user code. Error: ' .. runError)
						end
					end)
				end        
			end
			blocky.status = 1
		end)
	end)
end