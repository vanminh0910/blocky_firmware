local module  = ...

return function ()	
	package.loaded[module]=nil
  module = nil
  local ok, json = pcall(sjson.encode, blocky.config)
  if ok then
    file.open('config', 'w')
    file.writeline(json)
    file.flush()
    file.close()
    return true
  else
    print('Failed to save config')
    return false
  end
end