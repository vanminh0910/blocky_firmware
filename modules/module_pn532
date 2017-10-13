--ModuleName    PN532
--Version       1
--Contributor   Hacklock

local M, module = {}, ...

require('bit')
local PN532_PREAMBLE         = 0x00
local PN532_STARTCODE1        = 0x00
local PN532_STARTCODE2        = 0xFF
local PN532_POSTAMBLE         = 0x00
local PN532_HOSTTOPN532   = 0xD4
local PN532_PN532TOHOST   = 0xD5
local I2CBus = 0
local I2CNFC = 0x24
local Return = 0 
 function M.IRQRead ()
    gpio.mode(_irq_pin, gpio.INPUT , gpio.PULLUP) --change IRQ pin here
    return gpio.read(_irq_pin)
end
 function M.Write (Address, ...)

     Data = {...}
     Bytes = string.format("%02x ", Address)
    ----print("-0")
    for _, Byte in pairs(Data) do
        ----print("1")
        Bytes = Bytes .. string.format("%02x ", Byte)
    end

     DataString = string.char(unpack(Data))

    i2c.start(0)
    i2c.address(0, 0x24,i2c.TRANSMITTER)
    i2c.write(I2CBus,  DataString)
    i2c.stop(0)
    ----print("I2C Writemnnnn")
    return error
end
 function M.Read (Address, BytesOut, ...)
     Data = {...}
     DataString = string.char(unpack(Data))
     Status = 0 
    M.Write(Address , DataString)
    i2c.start(0)
    Status = i2c.address(0, Address,i2c.RECEIVER)
    Data = i2c.read(0,BytesOut)

    Return = {}

    if Status == 0 then
        Data:gsub(".", function(c)
            Return[#Return+1] = string.byte(c)
        end)
        return Return
    end
end
 function M.ReadWithoutCommand (Address, BytesOut)
     Data = {}
    i2c.start(0)
    i2c.address(0, Address,i2c.RECEIVER)
    Data = i2c.read(0,BytesOut)
    Return = {}
    Status = 0 
    if Status == 0 then
        Data:gsub(".", function(c)
            Return[#Return+1] = string.byte(c)
        end)
        return Return
    end
end

 function M.WaitForIRQ (Timeout)
     Timeout = Timeout or 50
     WaitStart = tmr.now()
     IRQStatus = 0 
    while tmr.now() < WaitStart + Timeout do
        IRQStatus = M.IRQRead()
        if IRQStatus == 0 then break end
    end
    IRQStatus = M.IRQRead()
        if IRQStatus ~= 0 then
            return false
        end
    return true
end

 function M.WriteCommand (...)
     Command = {...}
     Checksum = PN532_PREAMBLE + PN532_STARTCODE1 + PN532_STARTCODE2
     WireCommand = { PN532_PREAMBLE, PN532_STARTCODE1, PN532_STARTCODE2 }
    WireCommand[#WireCommand+1] = (#Command + 1)
    WireCommand[#WireCommand+1] = bit.band(bit.bnot(#Command +1) + 1, 0xFF)
    Checksum = Checksum + PN532_HOSTTOPN532
    WireCommand[#WireCommand+1] = PN532_HOSTTOPN532
    for _, Byte in pairs(Command) do
        Checksum = Checksum + Byte
        WireCommand[#WireCommand+1] = Byte
    end
    WireCommand[#WireCommand+1] = bit.band(bit.bnot(Checksum), 0xFF)
    WireCommand[#WireCommand+1] = PN532_POSTAMBLE
    M.Write(I2CNFC, unpack(WireCommand))
end

function M.SendAndAck (...)
    M.WriteCommand(...)
     IRQArrived = M.WaitForIRQ()
    if not IRQArrived then
        return false
    end

    ACK =   M.ReadWithoutCommand(I2CNFC, 8)
    if ACK[1] == 1 and ACK[2] == 0 and ACK[3] == 0 and ACK[4] == 255
        and ACK[5] == 0 and ACK[6] == 255 and ACK[7] == 0 then
        return true
    else
        return false
    end
end
 function M.ReadFrame (Count)
    Bytes = M.ReadWithoutCommand(I2CNFC, Count+2)
    table.remove(Bytes, 1)
    table.remove(Bytes, #Bytes)
    return Bytes
end
local function checkOnline ()
    i2c.start(0)
    error = i2c.address(0, 0x24 ,i2c.TRANSMITTER)  
    i2c.stop(0)
    return error
end

-----------------------------------------------------------------------
function M.Setup(_pin)
    _irq_pin = _pin
    -- enable SAM with stuff.
    i2c.setup(0, 2, 1, i2c.SLOW)
    if checkOnline() == true then 
        print("Device Online") 
    end

    if M.SendAndAck(0x14, 0x01, 0x14, 0x01) == false then
        print( "SAM configuration failed!")
        return false
    end

return true
end

-- Waits for a NFC card to appear in the field
-- „Seconds” is how long the reader will block
-- „Callback” is a callback which is called when a card appears, and takes
-- a single argument which is the NFC ID like this: { 0x00, 0x01, 0x02, 0x03 }


function M.WaitForCard(Seconds,Callback)
----print("WFC")
if M.SendAndAck(0x4A, 0x01, 0x0) == false then
    ----print "Sending card read command failed!"
    return false
end

if M.WaitForIRQ(Seconds) then
    Bytes = M.ReadFrame(20)
    if Bytes ~= nil and #Bytes == 20 then
        NFCID = { Bytes[14], Bytes[15], Bytes[16], Bytes[17] }
        Callback(NFCID)
    end
    return true
    else return false
end

return true
end


return M
