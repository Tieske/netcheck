local socket = require("socket")
local netcheck = require("netcheck")

-- function handling network changes
local netchange = function (newState, oldState)
    if oldState then
        print ("The network connection changed...")
    else
        print ("Initial network state...")
    end
    print ("        connected : " .. newState.connected)
    print ("        IP address: " .. (newState.ip[1] or "none"))
    print ("        hostname  : " .. newState.name)
    print ("             Added: ", #newState.arrived)
    for i, ip in ipairs(newState.arrived) do
      print ("                "..i..": "..ip)
    end
    print ("             Left : ", #newState.left)
    for i, ip in ipairs(newState.left) do
      print ("                "..i..": "..ip)
    end
    -- do some stuff
end

print("Starting network checks, change your network and watch the changes come in")
local lasttime
local cnt = 60
local do_check = netcheck.getchecker()
local changed, new, old

while cnt > 0 do
    if lasttime then
        print (cnt .. ": It's been " .. tostring(socket.gettime() - lasttime) .. " since we were here, silly how time flies...")
    end
    changed, new, old = do_check()
    if changed or (not lasttime) then
        netchange(new, old)
    end
    lasttime = socket.gettime()
    socket.sleep(1)
    cnt=cnt-1
end

print ("bye, bye...")

