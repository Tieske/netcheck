-------------------------------------------------------------------------------
-- NetCheck provides functions to detect changes in network connectivity.
-- This module will create no global, it returns the <code>netcheck</code> table with
-- the defined functions (see below).<br/>
-- <br/>NetCheck is free software under the MIT/X11 license.
-- @class module
-- @name netcheck
-- @copyright 2011 Thijs Schreijer
-- @release Version 0.1.0, NetCheck to detect network connection changes

local socket = require("socket")
local netcheck = {}

local _dummy -- make local to trick luadoc
-------------------------------------------------------------------------------
-- State table with network parameters retrieved and used for comparison to detect changes.
-- The table contains the same regular info from <code>socket.dns</code> calls (see luasocket
-- documentation), but extended with the following fields;
-- @class table
-- @name networkstate
-- @field localhostname (string) name of localhost (only field that can be set, defaults to
-- <code>'localhost'</code>)
-- @field localhostip (string) ip address resolved for <code>localhostname</code>
-- @field connected (string) either <code>'yes'</code>, <code>'no'</code>, or
-- <code>'loopback'</code> (loopback means connected to localhost, no external connection)
-- @field changed (boolean) <code>true</code> if comparison done was different on either;
-- <code>name</code>, <code>connected</code>, or <code>ip[1]</code> properties
_dummy = {}
_dummy = nil

-------------------------------------------------------------------------------
-- Checks the network connection of the system and detects changes in connection or IP adress.
-- Call repeatedly to check status for changes. With every call include the previous results to compare with.
-- @param oldState (table) previous result (networkstate-table) to compare with, or <code>nil</code> if not called before
-- @return changed (boolean) same as <code>newstate.changed</code>
-- @return newState (table) networkstate-table
-- @see networkstate
-- @usage# local netcheck = require("netcheck")
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
-- @return function that can be used to detect changes. This function takes no parameters
-- and returns three values when called;<ol>
-- <li><code>changed</code> (boolean) indicating whether there was a change (same as <code>newState.changed</code>)</li>
-- <li><code>newState</code> (table) current check result (see <code>networkstate</code>)</li>
-- <li><code>oldState</code> (table) previous check result (see <code>networkstate</code>)</li></ol>
-- @see networkstate
-- @usage# -- create function
-- local do_check = require("netcheck").getchecker()
-- &nbsp
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
--         -- here you can compare oldState with newState to find out exactly what changed
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
