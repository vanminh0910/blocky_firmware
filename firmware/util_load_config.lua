local module  = ...

return function ()	
	package.loaded[module]=nil
  module = nil
  if file.open('config' ,'r') then
    local fileData = file.read()
    local runSuccess, runError = pcall(function() 
      blocky.config = sjson.decode(fileData)
    end) 
    if not runSuccess then
      print('Failed to load config. Error: ' .. runError)
      blocky.config = nil
    end
  else
    print('Could not read config file')
    blocky.config = nil
  end

  file.close()
end

