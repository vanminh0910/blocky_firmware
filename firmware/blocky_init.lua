local module  = ...

return function ()
	package.loaded[module]=nil
	module = nil

	blocky.sysTopicPrefix = blocky.config.authKey .. '/sys/'
	blocky.userTopicPrefix = blocky.config.authKey .. '/user/'

	blocky.mqtt = mqtt.Client(blocky.config.authKey	.. '_' .. node.chipid(), 
		30, node.chipid(), blocky.config.authKey)

	blocky.mqtt:on('offline', function(conn)
		require("blocky_on_offline")()
	end)

	blocky.mqtt:on('message', function (conn, topic, data)  
		require("blocky_on_message")(conn, topic, data)
	end)

	blocky.sendMessage = function(topic, data)
		if (blocky.status ~= 1) then
			print('Cannot send message as not connected to broker')
			return
		end
		blocky.mqtt:publish(blocky.userTopicPrefix..topic, data, 0, 0)
	end

	blocky.log = function(data)
		if (blocky.status ~= 1) then
			print('Cannot send message as not connected to broker')
			return
		end
		blocky.mqtt:publish(blocky.sysTopicPrefix..node.chipid()..'/log', data, 0, 0)
	end

	blocky.subscribe = function(topic, handler)
		if handler ~= nil then
			blocky.mqtt:subscribe(blocky.userTopicPrefix..topic, 0, nil)
			blocky.messageHandlers[topic] = handler
		end
	end
end
