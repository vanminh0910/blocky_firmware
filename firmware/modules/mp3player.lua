local M, module = {}, ...

function M.sendStack(command, argument)
  uart.setup(0, 9600, 8, 0, 1, 0 )
  local _sendingBuffer = {0x7E, 0xFF, 0x06, tonumber(command), 0x00, math.floor(argument/256), argument%256, 0x00, 0x00, 0xEF}
  local sum = 0 
  for i = 2, 7 do 
      sum = sum + _sendingBuffer[i]
  end
  sum = sum * -1
  sum = bit.lshift(sum, 16 )
  sum = bit.rshift(sum, 16 )
  _sendingBuffer[8] = math.floor(sum/256)
  sum = bit.lshift(sum, 8 )
  sum = bit.rshift(sum, 8 )
  _sendingBuffer[9] = sum%256
  for i = 1, 10 do
    uart.write(0,_sendingBuffer[i])
  end
end

function	M.reset()         M.sendStack(0x0C,0x00)    end 
function 	M.play(songID)    M.sendStack(0x12, songID) end --play file name in mp3 folder
function 	M.setVolume(volume)  M.sendStack(0x06, volume) end -- volume from 0-30
function	M.stop()			    M.sendStack(0x16, 0x00)		end
function	M.next()				  M.sendStack(0x01, 0x00)		end
function	M.previous()			M.sendStack(0x02, 0x00)		end
function	M.volumeUp()			M.sendStack(0x04, 0x00)		end
function	M.volumeDown()		M.sendStack(0x05, 0x00)		end

function	M.setEQ(eq)				  M.sendStack(0x07, eq)				end -- 0-Normal/1-Pop/2-Rock/3-Jazz/4-Classic/5-Base
function	M.loop(fileID)		M.sendStack(0x08, fileID)			end

return M



