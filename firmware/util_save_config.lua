ok, json = pcall(sjson.encode, blocky.config)
if ok then
  file.open('config', 'w')
  file.writeline(json)
  file.flush()
  file.close()
  print('Config saved')
else
  print('Failed to save config')
end