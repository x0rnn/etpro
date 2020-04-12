-- autoafk999spec.lua - auto-puts 999 and afk players to spectator
-- !specs command to list who specs are spectating
-- !(un)speclock command to prevent someone spectating the game
-- inactivity code from "Player Inactivity Modification" (inacmod.lua) by hadro
-- g_inactivity needs to be enabled
-- it is strongly recommended to set g_inactivity at least 11 seconds higher than max_player_inactivity

checkInterval = 15000 -- interval in milliseconds to check ping (15 sec)
pings = {} -- pings[clientid][15 sec interval ping]; if 3 intervals (45 sec) are all 999, player is put to spec
max_player_inactivity = 150000 -- time in milliseconds before a player gets moved to spectator for being inactive (2 min)
filename = "shrubbot.cfg"
speclock = {}
speclock_id = {}
speclock_flag = false

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("spec999.lua "..et.FindSelf())

	maxClients = tonumber(et.trap_Cvar_Get("sv_maxclients"))
	for i=0,maxClients-1 do
		pings[i] = {[1]=0, [2]=0, [3]=0}
		speclock[i] = nil
	end
end

function et_ClientDisconnect(clientNum)
	if speclock[clientNum] == true then
		speclock[clientNum] = nil
		table.remove(speclock_id, clientNum)
		if next(speclock) == nil then
			speclock_flag = false
		end
	end
end

function et_ClientUserinfoChanged(clientNum)
	local team = tonumber(et.gentity_get(clientNum, "sess.sessionTeam"))
	if speclock[clientNum] == true then
		if team == 1 or team == 2 then
			speclock[clientNum] = nil
			if next(speclock) == nil then
				speclock_flag = false
			end
		end
	end
end

function et_RunFrame(levelTime)
	gamestate = tonumber(et.trap_Cvar_Get("gamestate"))

	if speclock_flag == true then
		if gamestate == 0 then
			local x = 1
			for index in pairs(speclock_id) do
				if tonumber(et.gentity_get(speclock_id[x], "sess.sessionTeam")) == 3 then
					local ps_origin = { [1]=0, [2]=0, [3]=-100000 }
					et.gentity_set(speclock_id[x], "ps.origin", ps_origin)
				end
				x = x + 1
			end
		end
	end

	if math.mod(levelTime,checkInterval) == 0 then
		local matches999 = 0
		local matchesafk = 0
		if gamestate == 0 then
			for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
				local team = tonumber(et.gentity_get(i,"sess.sessionTeam"))
				if team == 1 or team == 2 then
					local ping = tonumber(et.gentity_get(i,"ps.ping"))
					local inact = tonumber(et.gentity_get(i, "client.inactivityTime"))
					local g_inactivity = tonumber(et.trap_Cvar_Get("g_inactivity")) * 1000
					-- afk check
					if levelTime >= inact - (g_inactivity - max_player_inactivity) then
						matchesafk = matchesafk + 1
						et.trap_SendConsoleCommand( et.EXEC_APPEND, "ref remove " .. i .. "\n" )
					end
					-- 999 check
					if pings[i][1] == 0 then
						pings[i][1] = ping
					elseif pings[i][1] ~= 0 then
						if pings[i][2] == 0 then
							pings[i][2] = ping
						elseif pings[i][2] ~= 0 then
							pings[i][3] = ping
							if pings[i][1] >= 999 and pings[i][2] >= 999 and pings[i][3] >= 999 then
								matches999 = matches999 + 1
								et.trap_SendConsoleCommand( et.EXEC_APPEND, "ref remove " .. i .. "\n" )
							else
								pings[i][1] = 0
								pings[i][2] = 0
								pings[i][3] = 0
							end
						end
					end
				end
			end
			if matches999 ~= 0 then
				et.trap_SendConsoleCommand( et.EXEC_APPEND, "qsay ^3auto-spec999: ^7Moving ^1" ..matches999.. " ^7999 ping player(s) to spectator\n" )
				matches999 = 0
			end
			if matchesafk ~= 0 then
				et.trap_SendConsoleCommand( et.EXEC_APPEND, "qsay ^3auto-afk: ^7Moving ^1" ..matchesafk.. " ^7AFK player(s) to spectator\n" )
				matchesafk = 0
			end
		end
	end
end

function et_ClientCommand(id, command)
	admin_flag = false
	guid = et.Info_ValueForKey(et.trap_GetUserinfo(id), "cl_guid")
	if et.trap_Argv(0) == "say" or et.trap_Argv(0) == "say_team" or et.trap_Argv(0) == "say_buddy" or et.trap_Argv(0) == "m" or et.trap_Argv(0) == "pm" then
		if et.trap_Argv(0) == "m" or et.trap_Argv(0) == "pm" then
			if (string.sub(et.trap_Argv(2), 1, 6) == "!specs") then
				fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
				if len ~= -1 then
					filestr = et.trap_FS_Read(fd, len)
					et.trap_FS_FCloseFile(fd)
					for v in string.gfind(filestr, guid .. "\nlevel\t%= ([^\n])") do
						if tonumber(v) >= 4 then -- level 4+ (Deputy+)
							admin_flag = true
							break
						end
					end
					filestr = nil
				else
					et.trap_FS_FCloseFile(fd)
				end
				if admin_flag == true then
					local cnt = 0
					for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
						local team = tonumber(et.gentity_get(i, "sess.sessionTeam"))
						if team == 3 then
							if et.gentity_get(i, "sess.spectatorState") == 2 then
								cnt = cnt + 1
								if cnt == 1 then
									et.trap_SendServerCommand(id, "chat \"^1Spectators watching:\"")
								end
								local specced = et.gentity_get(i, "sess.spectatorClient")
								local msg = string.format("chat  \"" ..  et.gentity_get(i, "pers.netname") .. "^3 is spectating: ^7" .. et.gentity_get(specced, "pers.netname"))
								et.trap_SendServerCommand(id, msg)
							end
						end
					end
					return 1
				else
					et.trap_SendServerCommand(id, "chat \"^7This command is not available to you.\"\n")
				end
			end
		else
			if et.trap_Argv(1) == "!specs" then
				if gamestate == 0 then
					fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
					if len ~= -1 then
						filestr = et.trap_FS_Read(fd, len)
						et.trap_FS_FCloseFile(fd)
						for v in string.gfind(filestr, guid .. "\nlevel\t%= ([^\n])") do
							if tonumber(v) >= 4 then -- level 4+ (Deputy+)
								admin_flag = true
								break
							end
						end
						filestr = nil
					else
						et.trap_FS_FCloseFile(fd)
					end
					if admin_flag == true then
						local cnt = 0
						for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
							local team = tonumber(et.gentity_get(i, "sess.sessionTeam"))
							if team == 3 then
								if et.gentity_get(i, "sess.spectatorState") == 2 then
									cnt = cnt + 1
									if cnt == 1 then
										et.trap_SendServerCommand(id, "chat \"^1Spectators watching:\"")
									end
									local specced = et.gentity_get(i, "sess.spectatorClient")
									local msg = string.format("chat  \"" ..  et.gentity_get(i, "pers.netname") .. "^3 is spectating: ^7" .. et.gentity_get(specced, "pers.netname"))
									et.trap_SendServerCommand(id, msg)
								end
							end
						end
						if cnt == 0 then
							et.trap_SendServerCommand(id, "chat \"^7No spectators watching anyone.\"\n")
						end
						et.G_LogPrint("say: " .. et.gentity_get(id, "pers.netname") .. ": !specs\n")
						return 1
					else
						et.trap_SendServerCommand(id, "chat \"^7This command is not available to you.\"\n")
					end
				else
					et.trap_SendServerCommand(id, "chat \"^7You can only use !specs during the game.\"\n")
					return 1
				end
			end
			args = et.ConcatArgs(1)
			local args_table = {}
			local cnt = 0
			for i in string.gfind(args, "%S+") do
				table.insert(args_table, i)
				cnt = cnt + 1
			end
			if args_table[1] == "!speclock" then
				fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
				if len ~= -1 then
					filestr = et.trap_FS_Read(fd, len)
					et.trap_FS_FCloseFile(fd)
					for v in string.gfind(filestr, guid .. "\nlevel\t%= ([^\n]+)") do
						if tonumber(v) >= 7 then
							admin_flag = true
							break
						end
					end
					filestr = nil
				else
					et.trap_FS_FCloseFile(fd)
					et.trap_SendServerCommand(id, "chat \"^7shrubbot.cfg not found.\"\n")
				end
				if admin_flag == true then
					if cnt ~= 2 then
						et.trap_SendServerCommand(id, "chat \"Usage: ^7!speclock <^3clientNum^7>\"\n")
					else
						cno = tonumber(args_table[2])
						if cno then
							if et.gentity_get(cno, "pers.connected") == 2 then
								local team = tonumber(et.gentity_get(cno, "sess.sessionTeam"))
								if team == 3 then
									speclock[cno] = true
									table.insert(speclock_id, cno)
									speclock_flag = true
								else
									et.trap_SendServerCommand(id, "chat \"^7Target is not a spectator.\"\n")
								end
							else
								et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
							end
						else
							et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
						end
					end
				else
					et.trap_SendServerCommand(id, "chat \"^7This command is not available to you.\"\n")
				end
			end
			if args_table[1] == "!unspeclock" then
				fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
				if len ~= -1 then
					filestr = et.trap_FS_Read(fd, len)
					et.trap_FS_FCloseFile(fd)
					for v in string.gfind(filestr, guid .. "\nlevel\t%= ([^\n]+)") do
						if tonumber(v) >= 7 then
							admin_flag = true
							break
						end
					end
					filestr = nil
				else
					et.trap_FS_FCloseFile(fd)
					et.trap_SendServerCommand(id, "chat \"^7shrubbot.cfg not found.\"\n")
				end
				if admin_flag == true then
					if cnt ~= 2 then
						et.trap_SendServerCommand(id, "chat \"Usage: ^7!unspeclock <^3clientNum^7>\"\n")
					else
						cno = tonumber(args_table[2])
						if cno then
							if et.gentity_get(cno, "pers.connected") == 2 then
								if speclock[cno] == true then
									speclock[cno] = nil
									table.remove(speclock_id, cno)
									if next(speclock) == nil then
										speclock_flag = false
									end
								else
									et.trap_SendServerCommand(id, "chat \"^7Target is not speclocked.\"\n")
								end
							else
								et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
							end
						else
							et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
						end
					end
				else
					et.trap_SendServerCommand(id, "chat \"^7This command is not available to you.\"\n")
				end
			end
		end
	end
	return(0)
end
