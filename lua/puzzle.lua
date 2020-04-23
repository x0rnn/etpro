-- lua code needed to play/finish puzzlemap by x0rnn

filename = "puzzlemap.log"
mapname = ""
players = {}
starttime = {}
flag = false
silverflag = false
silvercarriers = {}
goldflag = false
goldcarriers = {}

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("puzzle.lua "..et.FindSelf())

	maxClients = tonumber(et.trap_Cvar_Get("sv_maxclients"))
	for i=0,maxClients-1 do
		players[i] = nil
	end

	mapname = et.trap_Cvar_Get("mapname")
	if mapname == "puzzlemap" then
		flag = true
	end
end

function winners()
	fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len ~= -1 then
		local count = 0
		filestr = et.trap_FS_Read(fd, len)
		et.trap_FS_FCloseFile(fd)
		for n,t in string.gfind(filestr, "Date: [^\t]+\tName: ([^\t]+)\ttime: ([^\n]+)") do
			count = count + 1
			et.trap_SendServerCommand(-1, "chat \"^3" .. n .. " finished the map in: ^1" .. t .. "\"\n")
		end
		if count == 0 then
			et.trap_SendServerCommand(-1, "chat \"^3Nobody completed the map yet.\"\n")
		end
	else
		et.G_Print("puzzle.lua: no puzzlemap.log\n")
		return(0)
	end
end

function et_ClientBegin(clientNum)
	if flag == true then
		local team = tonumber(et.gentity_get(clientNum, "sess.sessionTeam"))

		if players[clientNum] == nil then
			players[clientNum] = team
		end

		if team == 1 or team == 2 then
			et.trap_SendServerCommand(clientNum, "chat \"^3This is an interactive puzzle map done with the help of LUA scripting.\"")
			et.trap_SendServerCommand(clientNum, "chat \"^3To proceed in some levels, you type out the answer and add a ^1! ^3in front.\"")
			et.trap_SendServerCommand(clientNum, "chat \"^3For example, to start, type ^1!startlevel\"")
			et.trap_SendServerCommand(clientNum, "chat \"^3Please don't share the level answers.\"")
			et.trap_SendServerCommand(clientNum, "chat \"^3Type ^1!hint ^3to get a hint.\"")
			et.trap_SendServerCommand(clientNum, "chat \"^3Type ^1!winners ^3to see all the players who completed the map.\"")
		end
	end
end

function et_ClientUserinfoChanged(clientNum)
	if flag == true then
		local team = tonumber(et.gentity_get(clientNum, "sess.sessionTeam"))

		if players[clientNum] == nil then
			players[clientNum] = team
		end

		if players[clientNum] ~= team then
			if team == 1 or team == 2 then
				et.trap_SendServerCommand(clientNum, "chat \"^3This is an interactive puzzle map done with the help of LUA scripting.\"")
				et.trap_SendServerCommand(clientNum, "chat \"^3To proceed in some levels, you type out the answer and add a ^1! ^3in front.\"")
				et.trap_SendServerCommand(clientNum, "chat \"^3For example, to start, type ^1!startlevel\"")
				et.trap_SendServerCommand(clientNum, "chat \"^3Please don't share the level answers.\"")
				et.trap_SendServerCommand(clientNum, "chat \"^3Type ^1!hint ^3to get a hint.\"")
				et.trap_SendServerCommand(clientNum, "chat \"^3Type ^1!winners ^3to see all the players who completed the map.\"")
				players[clientNum] = team
			else
				players[clientNum] = team
			end
		end
	end
end

function et_ClientDisconnect(clientNum)
	if flag == true then
		cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
		starttime[cl_guid] = nil
		silvercarriers[clientNum] = nil
		goldcarriers[clientNum] = nil
		local cnt = 0
		for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
			if et.gentity_get(i,"inuse") then
				cnt = cnt + 1
			end
		end
		if cnt == 1 then
			et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref maprestart" .. "\n")
		end
	end
end

function et_RunFrame(levelTime) 
	if flag == true then
		if math.mod(levelTime,2000) ~= 0 then return end
		if silverflag == true then
			for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
				local team = tonumber(et.gentity_get(i,"sess.sessionTeam"))
				if team == 1 or team == 2 then
					if team == 1 then
						local blue = et.gentity_get(i, "ps.powerups", 7)
						if blue ~= 0 then
							silvercarriers[i] = true
						end
					elseif team == 2 then
						local red = et.gentity_get(i, "ps.powerups", 6)
						if red ~= 0 then
							silvercarriers[i] = true
						end
					end
				end
			end
		end
		if goldflag == true then
			for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
				local team = tonumber(et.gentity_get(i,"sess.sessionTeam"))
				if team == 1 or team == 2 then
					local origin = et.gentity_get(i, "r.currentOrigin")
					local z = math.floor(origin[3])
					if z == -1008 then
						if goldcarriers[i] ~= true then
							local ps_origin = { [1]=-1875,  [2]=1063, [3]=1552 }
							et.gentity_set(i, "ps.origin", ps_origin)
							et.trap_SendServerCommand(i, "chat \"^0You need to figure it out yourself^7.\"")
						end
					end
				end
			end
		end
	end
end

function et_Print(text)
	if flag == true then
		if string.find(text, "stole \"The silver key\"") then
			silverflag = true
		end
	end
end

function et_ClientSpawn(clientNum, revived)
	if flag == true then
		local team = et.gentity_get(clientNum, "sess.sessionTeam")
		if team == 1 or team == 2 then
			et.gentity_set(clientNum, "ps.stats", 4, 9999)
			et.gentity_set(clientNum, "health", 9999)
			et.gentity_set(clientNum, "ps.ammoclip", 4, 0)
			et.gentity_set(clientNum, "ps.ammoclip", 9, 0)
			et.gentity_set(clientNum, "ps.ammo", 2, 0)
			et.gentity_set(clientNum, "ps.ammo", 7, 0)
			et.gentity_set(clientNum, "ps.ammoclip", 2, 0)
			et.gentity_set(clientNum, "ps.ammoclip", 7, 0)
			et.gentity_set(clientNum, "ps.ammo", 3, 0)
			et.gentity_set(clientNum, "ps.ammo", 8, 0)
			et.gentity_set(clientNum, "ps.ammoclip", 3, 0)
			et.gentity_set(clientNum, "ps.ammoclip", 8, 0)
			et.gentity_set(clientNum, "ps.ammo", 19, 0)
			et.gentity_set(clientNum, "ps.ammoclip", 19, 0)
		end
	end
end

function et_ClientCommand(id, cmd)
	if flag == true then
		cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(id), "cl_guid")
		if et.trap_Argv(0) == "say" then
			local team = et.gentity_get(id, "sess.sessionTeam")
			args = et.ConcatArgs(1)
			local args_table = {}
			cnt = 0
			for i in string.gfind(args, "%S+") do
				table.insert(args_table, i)
				cnt = cnt + 1
			end
			if args_table[1] == "!winners" then
				winners()
			end
			if team == 1 or team == 2 then
				if args_table[1] == "!startlevel" then
					local origin = et.gentity_get(id, "r.currentOrigin")
					local z = math.floor(origin[3])
					if z == -1248 then
						local ps_origin = { [1]=47,  [2]=-1410, [3]=-1679 }
						et.gentity_set(id, "ps.origin", ps_origin)
						et.trap_SendServerCommand(id, "chat \"^0Your journey begins now^7.\"")
						starttime[cl_guid] = os.time()
					elseif z > 1040 and z < 1552 then
						if silvercarriers[id] == true then
							local ps_origin = { [1]=112,  [2]=-438, [3]=-1679 }
							et.gentity_set(id, "ps.origin", ps_origin)
							et.trap_SendServerCommand(id, "chat \"^0Welcome back^7.\"")
							goldflag = true
							goldcarriers[id] = true
						end
						return 1
					end
				end
				if args_table[1] == "!hint" then
					local origin = et.gentity_get(id, "r.currentOrigin")
					local z = math.floor(origin[3])
					if z == -1720 then
						et.trap_SendServerCommand(id, "chat \"^0Anagram^7.\"")
					elseif z == 2336 or z == 2380 then
						et.trap_SendServerCommand(id, "chat \"^0Ding dong^7.\"")
					elseif z == -192 then
						et.trap_SendServerCommand(id, "chat \"^0Alpha Beta _____ Delta^7.\"")
					elseif z > 119 and z < 816 then
						et.trap_SendServerCommand(id, "chat \"^0William Blake^7.\"")
					elseif z == -1008 then
						et.trap_SendServerCommand(id, "chat \"^0Code^7.\"")
					end
				end
				if args_table[1] == "!murder" then
					local origin = et.gentity_get(id, "r.currentOrigin")
					local z = math.floor(origin[3])
					if z == -1720 then
						local ps_origin = { [1]=-1990,  [2]=4372, [3]=2376 }
						et.gentity_set(id, "ps.origin", ps_origin)
						et.trap_SendServerCommand(id, "chat \"^0Well done^7.\"")
					end
					return 1
				end
				if args_table[1] == "!666" then
					local origin = et.gentity_get(id, "r.currentOrigin")
					local z = math.floor(origin[3])
					if z == -192 then
						local ps_origin = { [1]=4472,  [2]=2634, [3]=437 }
						et.gentity_set(id, "ps.origin", ps_origin)
						et.trap_SendServerCommand(id, "chat \"^0Well done^7.\"")
						et.gentity_set(id, "ps.stats", 4, 9999)
						et.gentity_set(id, "health", 9999)
						et.gentity_set(id, "ps.ammoclip", 4, 0)
						et.gentity_set(id, "ps.ammoclip", 9, 0)
						et.gentity_set(id, "ps.ammo", 2, 0)
						et.gentity_set(id, "ps.ammo", 7, 0)
						et.gentity_set(id, "ps.ammoclip", 2, 0)
						et.gentity_set(id, "ps.ammoclip", 7, 0)
						et.gentity_set(id, "ps.ammo", 3, 0)
						et.gentity_set(id, "ps.ammo", 8, 0)
						et.gentity_set(id, "ps.ammoclip", 3, 0)
						et.gentity_set(id, "ps.ammoclip", 8, 0)
						et.gentity_set(id, "ps.ammo", 19, 0)
						et.gentity_set(id, "ps.ammoclip", 19, 0)
						return 1
					end
				end
				if args_table[1] == "!dragon" then
					local origin = et.gentity_get(id, "r.currentOrigin")
					local z = math.floor(origin[3])
					if z > 119 and z < 816 then
						local ps_origin = { [1]=-1875,  [2]=1063, [3]=1552 }
						et.gentity_set(id, "ps.origin", ps_origin)
						et.trap_SendServerCommand(id, "chat \"^0Well done^7.\"")
					end
					return 1
				end
				if args_table[1] == "!cthulhu" or args_table[1] == "!cthulu" or args_table[1] == "!chtulu" or args_table[1] == "!chtulhu" then
					local origin = et.gentity_get(id, "r.currentOrigin")
					local z = math.floor(origin[3])
					if z == -1008 then
						local ps_origin = { [1]=-2328,  [2]=-2048, [3]=-2152 }
						et.gentity_set(id, "ps.origin", ps_origin)
						if args_table[1] ~= "!cthulhu" then
							et.trap_SendServerCommand(id, "chat \"^0Spelled it wrong^7, ^0but well done^7.\"")
						else
							et.trap_SendServerCommand(id, "chat \"^0Well done^7.\"")
						end
						local name = et.gentity_get(id, "pers.netname")
						local diff = os.date("!%X", os.difftime(os.time(),starttime[cl_guid]))
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^0finished the map in ^1" .. diff .. "^7!\"")
						local fd,len = et.trap_FS_FOpenFile(filename, et.FS_APPEND)
						local info = string.format("Date: %s	Name: %s	time: %s\n", os.date(), name, diff)
						et.trap_FS_Write(info, string.len(info), fd)
						et.trap_FS_FCloseFile(fd)
						fd = nil
					end
					return 1
				end
				if args_table[1] == "!iaiafhtagn" or args_table[1] == "!reddragon" or args_table[1] == "!thegreatreddragon" then
					return 1
				end
			end
		end
	end
	return(0)
end