tmr.create():alarm(10000, tmr.ALARM_AUTO, function() 
  print('test') 
  blocky.sendMessage('hello', 'hello world')
end)