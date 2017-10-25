local module  = ...

return function ()
	package.loaded[module]=nil
	module = nil

	statusLedOn = nil
	if connectBlockyTimer ~= nil then
		tmr.unregister(connectBlockyTimer)
		connectBlockyTimer = nil
	end
	
	if connectBlinkTimer ~= nil then
	  tmr.unregister(connectBlinkTimer)
	  connectBlinkTimer = nil
	end  
	
	if reconnectTimer ~= nil then
	  tmr.unregister(reconnectTimer)
	  reconnectTimer = nil
	end

	collectgarbage()
	gpio.write(4, gpio.HIGH)
end




