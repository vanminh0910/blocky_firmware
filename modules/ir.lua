local M, module = {}, ...

function M.setup()
    i2c.setup(0, 2, 1, i2c.SLOW)
end

function M.isBusy()
    i2c.start(0)
    local available = i2c.address(0, 0x09,i2c.TRANSMITTER)
    i2c.stop(0)
    if available == 0 then return true end
	return false
	
end

function M.wait()
	
    while  M.isBusy() == true do  --<< cant call global isBusy ?
        tmr.delay(50)
    end
	
end


function M.learn(addr_id)
    --M.wait() -- i need this , otherwise , i am not sure the module will execute the command
    i2c.start(0)
    i2c.address(0, 0x09,i2c.TRANSMITTER)
    i2c.write(0,0x00)
    i2c.write(0,0x0A)
    i2c.write(0,addr_id)
    i2c.stop(0)
end


function M.send(addr_id) --send with freq from learnIR
    --M.wait()
    i2c.start(0)
    i2c.address(0, 0x09, i2c.TRANSMITTER)
    i2c.write(0,0x00)
    i2c.write(0,0x0C)
    i2c.write(0, addr_id)
    i2c.stop(0)
end


function M.send(addr_id, freq , times , delay )
	--M.wait()
    i2c.start(0)
    i2c.address(0, 0x09, i2c.TRANSMITTER)
    i2c.write(0,0x00)
    i2c.write(0,0x0C)
    i2c.write(0, addr_id)
	i2c.write(0, freq) -- user chosen carrier frequency
	i2c.write(0, times) --for repeat code , SONY tivi
	i2c.write(0, delay)	--delay between repeat
    i2c.stop(0)


end

return M