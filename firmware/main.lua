sntp.sync(nil, nil, nil, 1)
print(rtctime.get())

tm = rtctime.epoch2cal(rtctime.get())
print(string.format("%04d/%02d/%02d %02d:%02d:%02d", tm["year"],
tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))

