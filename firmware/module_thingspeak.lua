local module  = ...


return function (WRITE_API_KEY , TOPIC , DATA)
  package.loaded[module]=nil
  module = nil
  
  con = nil
  con = net.createConnection(net.TCP, 0)
  
  con:on("receive", function(con, payloadout)
    if (string.find(payloadout, "Status: 200 OK") ~= nil) then
      print("Posted OK to ThingSpeak");
    end
  end)
  
  con:on("connection", function(con, payloadout)
    
    -- Get sensor data
    
    -- Post data to Thingspeak
    con:send(
    "POST /update?api_key=" .. WRITE_API_KEY .. 
    "&"..TOPIC.."=" .. DATA .. 
    " HTTP/1.1\r\n" .. 
    "Host: api.thingspeak.com\r\n" .. 
    "Connection: close\r\n" .. 
    "Accept: */*\r\n" .. 
    "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n" .. 
    "\r\n")
  end)
  
  con:on("disconnection", function(con, payloadout)
    --con:close();
    collectgarbage();
  end)
  
  -- Connect to Thingspeak
  con:connect(80,'api.thingspeak.com')
end
