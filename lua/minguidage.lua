-- minguidage by x0rnn: forces new GUID players on the server to spec to prevent cheaters making new GUIDs and reconnecting
-- you need to prepopulate knownguids.log with known guids or everyone will be considered new, e.g.:
-- guid1	1054080000
-- guid2 	1054080000
-- etc. (it's a tab not a space, followed by timestamp (year 2003))

filename = "knownguids.log"
whitelist = {}
player_timestamp = {}
minguidage = 3 -- days ago needed to be seen on this server for the first time to be allowed to play

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("minguidage.lua "..et.FindSelf())
	local fd, len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len > -1 then
		local filestr = et.trap_FS_Read(fd, len)
		for v in string.gfind(filestr, "([%x]+\t[^\n]+)") do
			table.insert(whitelist, v)
		end
		filestr = nil
		et.trap_FS_FCloseFile(fd)
	else
		et.G_Print("minguidage.lua: no whitelist.log\n")
	end
end

function roundNum(num, n)
	local mult = 10^(n or 0)
	return math.floor(num * mult + 0.5) / mult
end

function et_ClientConnect(clientNum, firstTime, isBot)
	found_flag = false
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")

	for key,value in pairs(whitelist) do
		if string.find(value, cl_guid) then
			for v in string.gfind(value, cl_guid .. "	" .. "(%d+)") do
				timestamp = tonumber(v)
				player_timestamp[clientNum] = timestamp
			end
			found_flag = true
			break
		end
	end
	if not found_flag then
		timestamp = os.time(os.date("!*t"))
		player_timestamp[clientNum] = timestamp
		fd,len = et.trap_FS_FOpenFile(filename, et.FS_APPEND)
		count = et.trap_FS_Write(cl_guid .. "	" .. timestamp .. "\n", string.len(cl_guid .. "	" .. timestamp .. "\n"), fd)
		et.trap_FS_FCloseFile(fd)
		table.insert(whitelist, cl_guid .. "	" .. timestamp)
	end
end

function et_ClientBegin(clientNum)
	local team = et.gentity_get(clientNum, "sess.sessionTeam")
	if team == 1 or team == 2 or team == 3 then
		if ((((os.time(os.date("!*t")) - player_timestamp[clientNum]) / 60) / 60) / 24) < minguidage then
			et.trap_SendServerCommand(-1, "chat \"^3Unknown player with a new GUID connected (" .. et.gentity_get(clientNum, "pers.netname") .. "^3). Keep an eye on him and report if needed.\"")
			--local diff = math.floor(roundNum(((((os.time(os.date("!*t")) - player_timestamp[clientNum]) / 60) / 60) / 24)))
			-- et.trap_DropClient(clientNum, "Your GUID is too new on this server. Try again in " .. minguidage - diff .. " days.", 900) --15 minutes
			--et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref remove " .. clientNum .. "\n")
			--if diff ~= minguidage then
			--	et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(clientNum, "pers.netname") .. "^3's GUID is too new to play on this server. Please wait " .. minguidage - diff .. " days. (Put to spectators to watch only.)\"")
			--else
			--	et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(clientNum, "pers.netname") .. "^3's GUID is too new to play on this server. Please wait a few more hours. (Put to spectators to watch only.)\"")
			--end
		end
	end
end
