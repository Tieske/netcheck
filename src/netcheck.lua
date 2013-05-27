-------------------------------------------------------------------------------
-- NetCheck provides functions to detect changes in network connectivity.
-- <br/>NetCheck is free software under the MIT/X11 license.
-- @class module
-- @name netcheck
-- @copyright 2011-2013 Thijs Schreijer
-- @release Version 0.2.0, NetCheck to detect network connection changes

local socket = require("socket")
local netcheck = {}

local _dummy -- make local to trick luadoc
-------------------------------------------------------------------------------
-- State table with network parameters retrieved and used for comparison to detect changes.
-- The table contains the same regular info from <code>socket.dns</code> calls (see luasocket
-- documentation), but extended with the following fields;
-- @class table
-- @name networkstate
-- @field name hostname
-- @field ip table with ip adresses
-- @field arrived (table) containing new ip adresses since last check
-- @field left (table) containing ip adresses no longer available
-- @field connected (string) either `yes`, `no`, or `loopback` 
-- @field changed (boolean) `true` if comparison done was different on either;
-- `name`, `connected`, `ip[1]`, or there where entries in `arrived`/`left` 
_dummy = {}
_dummy = nil

function getip()

  local function tryip()
    local s = socket.udp()
    s:setpeername("1.1.1.1",80)
    local ip, _ = s:getsockname()
    if ip == "0.0.0.0" then ip = nil end
    s:close()
    s = nil
    collectgarbage()  -- make sure to release every new socket created
    return ip
  end

  local myip, result = socket.dns.toip(socket.dns.gethostname())
  local activeip = tryip()
  if myip then
    local lh, aip
    for i, ip in ipairs(result.ip) do
      if ip == activeip    then aip = i end
      if ip == "127.0.0.1" then lh  = i end
    end
    if lh then  -- localhost address found, move it to end
      table.insert(result.ip, result.ip[lh])
      table.remove(result.ip, lh)
    else -- localhost not found? add it
      table.insert(result.ip, "127.0.0.1")
    end
    if activeip and not aip then -- active ip not found, add it on top
      table.insert(result.ip, 1, activeip)
    end
    for i, ip in ipairs(result.ip) do
      if ip == "127.0.1.1" then  -- move it as last
        table.insert(result.ip, "127.0.1.1")
        table.remove(result.ip, i)
        break
      end
    end
    myip = result.ip[1]
  end
  return myip, result
end

-------------------------------------------------------------------------------
-- Checks the network connection of the system and detects changes in connection or IP adress.
-- Call repeatedly to check status for changes. With every call include the previous results to compare with.
-- @param oldState (table) previous result (networkstate-table) to compare with, or `nil` if not called before
-- @return changed (boolean) same as `newstate.changed`
-- @return newState (table) networkstate-table
-- @see networkstate
-- @name netcheck.check
-- @example
-- local netcheck = require("netcheck")
-- function test()
--     print ("TEST: entering endless check loop, change connection settings and watch the changes come in...")
--     require ("base")	-- from stdlib to pretty print the table
--     local change, data
--     while true do
--         change, data = netcheck.check(data)
--         if change then
--             print (prettytostring(data))
--         end
--     end
-- end
netcheck.check = function(oldState)
	oldState = oldState or {}
	oldState.ip = oldState.ip or {}
	local sysname = socket.dns.gethostname()
	local newState = {
				name = sysname or "no name resolved",
				ip = {},
			}
	if not sysname then
		newState.connected = "no"
	else
		local sysip, data = getip()
		if sysip then
			newState.ip = data.ip
			if newState.ip[1] == "127.0.0.1" then
				newState.connected = "loopback"
			else
				newState.connected = "yes"
			end
      newState.arrived = {}
      for _,newip in pairs(newState.ip) do
        for _,oldip in pairs(oldState.ip) do
          if newip == oldip then
            newip = nil
            break
          end
        end
        if newip then -- was not in old state, so arrived
          table.insert(newState.arrived, newip)
        end
      end
      newState.left = {}
      for _,oldip in pairs(oldState.ip) do
        for _,newip in pairs(newState.ip) do
          if newip == oldip then
            oldip = nil
            break
          end
        end
        if oldip then -- was not in new state, so left
          table.insert(newState.left, oldip)
        end
      end
		else
			newState.connected = "no"
		end
	end
	newState.changed = (oldState.name ~= newState.name or oldState.ip[1] ~= newState.ip[1] or newState.connected ~= oldState.connected or (#newState.arrived + #newState.left)>0 )
	return newState.changed, newState
end

-------------------------------------------------------------------------------
-- Wraps the check function in a single function. By wrapping it and creating an upvalue
-- for the <code>oldState</code> parameter, the result can be called directly for changes.
-- @return function that can be used to detect changes. This function takes no parameters
-- and returns three values when called;<ol>
-- <li><code>changed</code> (boolean) indicating whether there was a change (same as <code>newState.changed</code>)</li>
-- <li><code>newState</code> (table) current check result (see <code>networkstate</code>)</li>
-- <li><code>oldState</code> (table) previous check result (see <code>networkstate</code>)</li></ol>
-- @see networkstate
-- @example
-- -- create function
-- local do_check = require("netcheck").getchecker()
-- 
-- -- watch for changes, short version
-- while true do
--     if do_check() then
--         print ("Network connection changed!")
--     end
-- end
-- &nbsp
-- -- alternative, to find out what changed...
-- while true do
--     local changed, newState, oldState = do_check()
--     if changed then
--         print ("Network connection changed!")
--     end
-- end
function netcheck.getchecker()
  local oldState
  local f = function()
    local changed, newState = netcheck.check(oldState)
    oldState, newState = newState, oldState -- swap value
    return changed, oldState, newState
  end
  f()     -- call first time, which always returns true
  return f
end

return netcheck
