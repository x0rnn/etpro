-- specs.lua by x0rnn, list who specs are spectating

filename = "shrubbot.cfg"

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("specs.lua "..et.FindSelf())
end

function et_ClientCommand(id, command)
	admin_flag = false
	guid = et.Info_ValueForKey(et.trap_GetUserinfo(id), "cl_guid")
	if et.trap_Argv(0) == "say" or et.trap_Argv(0) == "say_team" or et.trap_Argv(0) == "say_buddy" then
		if et.trap_Argv(1) == "!specs" then
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
				for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
					local team = tonumber(et.gentity_get(i, "sess.sessionTeam"))
					if team == 3 then
						local pos_spec = et.gentity_get(i, "ps.origin")
						for j=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
							local team2 = tonumber(et.gentity_get(j, "sess.sessionTeam"))
							if team2 == 1 or team2 == 2 then
								local health = tonumber(et.gentity_get(j, "health"))
								if health > 0 then
									local pos_player = et.gentity_get(j, "ps.origin")
									if math.abs(pos_spec[1] - pos_player[1]) < 20 and math.abs(pos_spec[2] - pos_player[2]) < 20 and math.abs(pos_spec[3] - pos_player[3]) < 20 then
										msg = string.format("chat  \"" ..  et.gentity_get(i, "pers.netname") .. "^7 is spectating: " .. et.gentity_get(j, "pers.netname") .. "\n")
										et.trap_SendServerCommand(id, msg)
									end
								end
							end
						end
					end
				end
			else
				et.trap_SendServerCommand(id, "chat \"^7This command is not available to you.\"\n")
			end
		end
	end
	return(0)
end
