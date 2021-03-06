local module  = ...

local firmwareVersion = '1.0'

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
		print(modulesList)
		local registerData = '{"event":"register", "chipId": "' .. node.chipid() 
			.. '", "firmware": "' .. firmwareVersion .. '", "name":"' .. blocky.config.deviceName .. '", "modules": "'
			.. modulesList ..  '", "type": "blocky_esp8266"}'
		blocky.mqtt:publish(blocky.sysTopicPrefix, registerData, 0, 0)
		blocky.mqtt:subscribe(
			{
				[blocky.sysTopicPrefix..node.chipid()..'/ota/#']=0,
				[blocky.sysTopicPrefix..node.chipid()..'/run/#']=0,
				[blocky.sysTopicPrefix..node.chipid()..'/rename']=0,
				[blocky.sysTopicPrefix..node.chipid()..'/reboot']=0,
				[blocky.sysTopicPrefix..node.chipid()..'/upload']=0,
				[blocky.sysTopicPrefix..node.chipid()..'/upgrade']=0
			}, function()
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