--[[
Copyright (C) 2013-2014 Draios inc.
 
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.


This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]

-- Chisel description
description = "Print the standard input of any process on screen. Combine this script with a filter to limit the output to a specific process or pid.";
short_description = "Print stdin of processes";
category = "I/O";

args = {}
str_holder = "";
-- Initialization callback
function on_init()
	-- Request the fields that we need
	fbuf = chisel.request_field("evt.rawarg.data")
	fcontainerid = chisel.request_field("container.id")
	fcontainername = chisel.request_field("container.name")

	-- increase the snaplen so we capture more of the conversation 
	sysdig.set_snaplen(2000)

	-- set the filter
	chisel.set_filter("fd.num=0 and evt.is_io=true")
	
	return true
end

-- Event parsing callback
function on_event()
	buf = evt.field(fbuf)
	local cjson = require 'cjson'
	local containername = evt.field(fcontainername)
	local containerid = evt.field(fcontainerid)

	local date_table = os.date("*t")
	local ms = string.match(tostring(os.clock()), "%d%.(%d+)")
	local hour, minute, second = date_table.hour, date_table.min, date_table.sec
	local year, month, day = date_table.year, date_table.month, date_table.day
	local current_time = string.format("%d-%02d-%02d %02d:%02d:%02d:%s", year, month, day, hour, minute, second, ms)

	if buf ~= nil then
		if string.byte(buf, 1,-1) == 13 or string.byte(buf, 1,-1) == 10 then
			print(cjson.encode({ datetime = current_time,
								 containerName = containername,
								 containerId = containerid,
								 command = str_holder,
								 type="stdin" }))
			str_holder = nil
			str_holder = ""
		elseif string.byte(buf, 1,-1) == 127 or string.byte(buf, 1,-1) == 8 then
			str_holder = str_holder:sub(1, -2)
		else
			str_holder = str_holder .. buf
		end
	end
	
	return true
end
