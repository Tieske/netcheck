-------------------------------------------------------------------------------
-- NetCheck provides function to detect changes in network connectivity
-- @copyright 2011 Thijs Schreijer
-- @release Version 0.1, NetCheck to detect network connection changes

local socket = require("socket")
require ("coxpcall")

netcheck = netcheck or {}

-------------------------------------------------------------------------------
-- Checks the network connection of the system and detects changes in connection or IP adress.
-- Call repeatedly to check status for changes. With every call include the previous results to compare with.
-- @param oldState (table) previous result to compare with, or <code>nil</code> if not called before
-- @return changed (boolean) same as <code>newstate.changed</code> (see below).
-- @return newState (table) same as regular info from <code>socket.dns</code> calls, but extended with;
-- <ul><li><code>localhostname </code>= (string) name of localhost (only field that can be set, defaults to <code>'localhost'</code>)</li>
-- <li><code>localhostip   </code>= (string) ip address resolved for <code>localhostname</code></li>
-- <li><code>connected     </code>= (string) either <code>'yes'</code>, <code>'no'</code>, or <code>'loopback'</code> (loopback means connected to localhost, no external connection)</li>
-- <li><code>changed       </code>= (boolean) <code>true</code> if <code>oldstate</code> is different on either; <code>name</code>, <code>connected</code>, or <code>ip[1]</code> properties</li></ul>
-- @usage# function test()
--     print ("TEST: entering endless check loop, change connection settings and watch the changes come in...")
--     require ("base")	-- from stdlib to pretty print the table
--     local change, data
--     while true do
--         change, data = copas.checknetwork(data)
--         if change then
--             print (prettytostring(data))
--         end
--     end
-- end
function netcheck.check(oldState)
	oldState = oldState or {}
	oldState.alias = oldState.alias or {}
	oldState.ip = oldState.ip or {}
	local sysname = socket.dns.gethostname()
	local newState = {
				name = sysname or "no name resolved",
				localhostname = oldState.localhostname or "localhost",
				localhostip = socket.dns.toip(oldState.localhostname or "localhost") or "127.0.0.1",
				alias = {},
				ip = {},
			}
	if not sysname then
		newState.connected = "no"
	else
		local sysip, data = socket.dns.toip(sysname)
		if sysip then
			newState.ip = data.ip
			newState.alias = data.alias
			if newState.ip[1] == newState.localhostip then
				newState.connected = "loopback"
			else
				newState.connected = "yes"
			end
		else
			newState.connected = "no"
		end
	end
	newState.changed = (oldState.name ~= newState.name or oldState.ip[1] ~= newState.ip[1] or newState.connected ~= oldState.connected)
	return newState.changed, newState
end

-------------------------------------------------------------------------------
-- Wraps the check function in a single function. By wrapping it and creating an upvalue
-- for the <code>oldState</code> parameter, the result can be called directly for changes.
-- @return function that can be used to detect changes
-- @usage# -- create function
-- local networkchanged = netcheck.wrap()
-- -- watch for changes
-- while true do
--     if networkchanged() then
--         print ("Network connection changed!")
--     end
-- end
function netcheck.wrap()
	assert(type(handler) == "function", "Error, no handler function provided")
	local oldState
    local f = function()
			local changed, oldState = copas.checknetwork(oldState)
            return changed
		end
    f()     -- call first time, which always returns true
    return f
end

