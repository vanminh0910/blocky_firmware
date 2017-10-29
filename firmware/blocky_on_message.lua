
local module  = ...

return function (conn, topic, data)
	package.loaded[module]=nil
	module = nil
	print('Received topic = ', topic)
	if safeModeTimer ~= nil then
		tmr.unregister(safeModeTimer)
		safeModeTimer = nil
		collectgarbage()
	end
	local matchPattern = string.gsub(blocky.userTopicPrefix..'(.*)', '%-', '%%-')
	if string.match(topic, matchPattern) then
		local topicParsed = string.match(topic, matchPattern)
		if topicParsed and blocky.messageHandlers[topicParsed] ~= nil then
			pcall(function() blocky.messageHandlers[topicParsed](topicParsed, data) end)
		end
	else
		matchPattern = string.gsub(blocky.sysTopicPrefix, '%-', '%%-')
		-- if receive system command
		if topic == blocky.sysTopicPrefix..node.chipid()..'/run' 
			or topic == blocky.sysTopicPrefix..node.chipid()..'/ota' then
			matchPattern = string.gsub(blocky.sysTopicPrefix..node.chipid()..'/(.*)', '%-', '%%-')
			local topicParsed = string.match(topic, matchPattern)
			if topicParsed == 'run' then
				print('Received run request')
				print(data)
				local otaAckMsg = '{"chipId":"' .. node.chipid() .. '", "event":"run_ack"}';
				blocky.mqtt:publish(blocky.sysTopicPrefix, otaAckMsg, 0, 0, function() node.input(data) end)
			elseif topicParsed == 'ota' then
				print('Received ota request')
				file.open('main_temp.lua', 'w')
				file.write(data)
				file.flush()
				file.close()
				file.remove('main.lua')
				file.rename('main_temp.lua', 'main.lua')
				--file.remove('main_temp.lua')
				print('OTA completed. Rebooting now...')
				local otaAckMsg = '{"chipId":"' .. node.chipid() .. '", "event":"ota_ack"}';
				blocky.mqtt:publish(blocky.sysTopicPrefix, otaAckMsg, 0, 0, function() 
					node.restart()
				end)
			end        
		elseif string.match(topic, matchPattern..node.chipid()..'/ota/(.*)') then -- if receive multipart ota command
			local otaIndex = string.match(topic, matchPattern..node.chipid()..'/ota/(.*)')
			print('Received part of ota code: ' , otaIndex)
			if otaIndex == '1' then
				file.open('main_temp.lua', 'w')
			else
				file.open('main_temp.lua', 'a+')
			end
			file.write(data)
			file.flush()
			file.close()

			if otaIndex == '$' then
				print('OTA completed. Rebooting now...')
				file.rename('main_temp.lua', 'main.lua')
				--node.compile("main_temp.lua")
				--file.remove('main.lc')
				--file.rename('main_temp.lc', 'main.lc')
				file.remove('main_temp.lua')
				--file.remove('main_temp.lc')
				local otaAckMsg = '{"chipId":"' .. node.chipid() .. '", "event":"ota_ack"}';
				blocky.mqtt:publish(blocky.sysTopicPrefix, otaAckMsg, 0, 0, function()
					print('Published OTA ack')
					node.restart()
				end)
			end
		elseif string.match(topic, matchPattern..node.chipid()..'/run/(.*)') then
			local runIndex = string.match(topic, matchPattern..node.chipid()..'/run/(.*)')
			if runIndex == '1' then
				file.open('run_temp.lua', 'w')
			else
				file.open('run_temp.lua', 'a+')
			end
			file.write(data)
			file.flush()
			file.close()

			if runIndex == '$' then
				print('Run completed. Executing...')
				dofile('run_temp.lua')
				file.remove('run_temp.lua')
				local runAckMsg = '{"chipId":"' .. node.chipid() .. '", "event":"run_ack"}';
				blocky.mqtt:publish(blocky.sysTopicPrefix, runAckMsg, 0, 0, function()
					print('Published run ack')
				end)
			end
		elseif topic == blocky.sysTopicPrefix..node.chipid()..'/rename' then
			print('Received rename request')
			if data == nil or data == '' then
				print('Invalid name')
			else
				blocky.config.deviceName = data
				require('util_save_config')()
			end     
		elseif topic == blocky.sysTopicPrefix..node.chipid()..'/reboot' then
			print('Received reboot request')
			node.restart()
		elseif topic == blocky.sysTopicPrefix..node.chipid()..'/upload' then
			print('Received upload request')
		elseif topic == blocky.sysTopicPrefix..node.chipid()..'/upgrade' then
			print('Received upgrade firmware request')
			blocky.config.upgradeFirmware = true
			require('util_save_config')()
			node.restart()
		elseif topic == blocky.sysTopicPrefix..node.chipid()..'/log' then
			return
		else
			print('Received invalid request')
		end
	end
end

