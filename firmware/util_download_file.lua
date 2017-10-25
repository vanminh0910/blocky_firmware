local module  = ...


return function (url, fileName, onCompleted, onError)
	package.loaded[module]=nil
	module = nil
	print('Downloading: ' .. fileName .. ' from ' .. url)
	http.get(url, nil, function(code, data)      
    if (code ~= 200) then
      if (onError) then
        onError()
        collectgarbage()
      end
      return
    end    
    local fd = file.open(fileName, "w+"); fd:write(data); fd:close()  
    collectgarbage()
    print('Download completed')
    if (onCompleted) then
      onCompleted()
    end
  end)
end




