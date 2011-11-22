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
    -- do some stuff
end

print("Starting network checks, change your network and watch the changes come in")
local lasttime
local cnt = 60
local do_check = netcheck.getchecker()
local changed, new, old

while cnt > 0 do
    cnt=cnt-1
    if lasttime then
        print (cnt .. ": It's been " .. tostring(socket.gettime() - lasttime) .. " since we were here, silly how time flies...")
    end
    changed, new, old = do_check()
    if changed then
        netchange(new, old)
    end
    lasttime = socket.gettime()
    socket.sleep(1)
end

print ("bye, bye...")

