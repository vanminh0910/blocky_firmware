local module  = ...

return function (topic, isSystemTopic)
	package.loaded[module]=nil
	module = nil
	if isSystemTopic then
		return blocky.config.authKey .. '/sys/' .. topic
	else
		return blocky.config.authKey .. '/user/' .. topic
	end
end

