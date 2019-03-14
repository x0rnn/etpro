-- automute.lua by x0rnn, will automute all etadmin level -2 players on connect
-- modify etadmin_mod/bin/shrub_management.pl line 161 to:
-- if ( !defined($level) || $level < -1000 || !$guid || ( !$name && $level != 0 ) || length($guid) != 32 )

filename = "shrubbot.cfg"
unmute_tries = {}
idiots = {}

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("automute.lua "..et.FindSelf())
end

function et_ClientConnect(clientNum, firstTime, isBot)
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len ~= -1 then
		filestr = et.trap_FS_Read(fd, len)
		for v in string.gfind(filestr, cl_guid .. "\nlevel\t%= %-2") do
			idiots[cl_guid] = true
		end
		filestr = nil
		et.trap_FS_FCloseFile(fd)
	else
		et.trap_FS_FCloseFile(fd)
	end
end

function et_ClientBegin(clientNum)
	name = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "name")
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	if idiots[cl_guid] == true then
		et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^1automuted for being a Goon.\"\n")
		et.gentity_set(clientNum, "sess.muted", 1)
	end
end

function et_ClientCommand(cno, cmd)
	if tonumber(et.gentity_get(cno, "sess.muted")) == 1 then
		cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(cno), "cl_guid")
		if string.lower(cmd) == "m" or string.lower(cmd) == "pm" then
			et.trap_SendServerCommand(cno, "cpm \"^1You are muted. This command is not available to you.\n\"")
			return 1
		elseif string.lower(cmd) == "callvote" then
			if idiots[cl_guid] == true then
				if string.lower(et.trap_Argv(1)) == "kick" or string.lower(et.trap_Argv(1)) == "mute" then
					et.trap_SendServerCommand(cno, "cpm \"^1This command is not available to you.\n\"")
					return 1
				elseif string.lower(et.trap_Argv(1)) == "unmute" then
					local client = findClient(et.trap_Argv(2))
					if client ~= nil and cno == client.slot then
						if unmute_tries[cl_guid] == nil then
							unmute_tries[cl_guid] = 1
						else
							unmute_tries[cl_guid] = unmute_tries[cl_guid] + 1
						end
						if unmute_tries[cl_guid] <= 3 then
							msg = string.format("cpm  \"" .. client.name .. "^3 got bummed for trying to unmute himself. What a peon.\n")
							et.trap_SendServerCommand(-1, msg)
							et.trap_SendServerCommand(cno, "cpm \"^1If you learnt your lesson, come to the forum or www.hirntot.org/discord and ask in a nice way to get unmuted.\n\"")
							et.G_Damage(cno, 80, 1022, 1000, 8, 34)
							soundindex = et.G_SoundIndex("/sound/etpro/osp_goat.wav")
							et.G_Sound(cno, soundindex)
							if unmute_tries[cl_guid] == 3 then
								et.trap_SendServerCommand(cno, "cpm \"^1You cannot unmute yourself. Next time you try, you will get kicked.\n\"")
							end
							return 1
						else
							et.trap_DropClient(cno, "You cannot unmute yourself, stop trying.", 900) --15 minutes
						end
					end
				end
			end
		end
	else
		if string.lower(cmd) == "callvote" then
			if string.lower(et.trap_Argv(1)) == "unmute" then
				local client = findClient(et.trap_Argv(2))
				if client ~= nil and idiots[client.guid] == true then
					et.trap_SendServerCommand(cno, "chat \"You can't unmute " .. et.Q_CleanStr(client.name) .. ".\"\n")
					return 1
				end
			end
		end
	end
	return(0)
end

function findClient(identifier)

	local argn = nil
	local sv_maxclients = tonumber(et.trap_Cvar_Get("sv_maxclients"))
	for i = 0, sv_maxclients - 1 do
		local name = et.gentity_get(i, "pers.netname")
		if string.lower(et.Q_CleanStr(name)) == string.lower(et.Q_CleanStr(identifier)) then
			argn = i
			break
		end
	end
	
	if argn == nil then
		argn = tonumber(identifier)
	end
	
	if argn ~= nil then
		return {
			slot = argn,
			name = et.gentity_get(argn, "pers.netname"),
			guid = et.Info_ValueForKey(et.trap_GetUserinfo(argn), "cl_guid")
		}
	end
	
	return nil

end
