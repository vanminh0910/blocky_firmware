function downloadFile (url, fileName, runAfterDownload)
  print("Downloading: "..fileName.. " from "..url)
  local failed = false
  http.get(url, nil, function(code, data)      
    if (code ~= 200) then
        failed = true
    end    
    local fd = file.open(fileName,"w+");fd:write(data);fd:close()  
    collectgarbage()

    print("Download load completed")
    
    if (runAfterDownload) then
        dofile(fileName)
        collectgarbage()
    end
  end)
end