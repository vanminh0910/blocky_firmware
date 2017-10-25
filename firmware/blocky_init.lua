local module  = ...

return function ()
	package.loaded[module]=nil
	module = nil

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
		blocky.mqtt:publish(require('util_get_topic')(topic, false), data, 0, 0)
	end

	blocky.log = function(data)
		if (blocky.status ~= 1) then
			print('Cannot send message as not connected to broker')
			return
		end
		blocky.mqtt:publish(require('util_get_topic')(node.chipid()..'/log', true), data, 0, 0)
	end

	blocky.subscribe = function(topic, handler)
		if handler ~= nil then
			blocky.mqtt:subscribe(require('util_get_topic')(topic, false), 0, nil)
			blocky.messageHandlers[topic] = handler
		end
	end
end
