-- voteannounce2.lua, publicly shows who voted yes/no except for player-specific votes (kick, mute, etc.)

votecount = {}
noannounce = false

function et_InitGame(levelTime, randomSeed, restart)
 	et.RegisterModname("voteannounce2.lua "..et.FindSelf())

	local i = 0
	for i=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
		votecount[i] = 0
	end
end

function et_ClientCommand(id, command)
	local name = et.gentity_get(id, "pers.netname")
	if et.trap_Argv(0) == "callvote" then
		local cs = et.trap_GetConfigstring(6)
		if cs == "" then
			local i = 0
			for i=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
				votecount[i] = 0
			end
		end
	end

	if et.trap_Argv(0) == "vote" then
		local cs = et.trap_GetConfigstring(6)
		local cs2 = et.trap_GetConfigstring(7)
		if string.sub(cs2,1,5) == "KICK " or string.sub(cs2,1,5) == "MUTE " or string.sub(cs2,1,8) == "PUTSPEC " or string.sub(cs2,1,8) == "PUTAXIS " or string.sub(cs2,1,10) == "PUTALLIES " then
			noannounce = true
		else
			noannounce = false
		end

		if cs ~= "" then
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			if team == 1 or team == 2 then
				if noannounce == false then
					if team == 1 then
						if votecount[id] == 0 then
							if et.trap_Argv(1) == "yes" then
								et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^1voted ^2YES\"")
								votecount[id] = votecount[id] + 1
							elseif et.trap_Argv(1) == "no" then
								et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^1voted NO\"")
								votecount[id] = votecount[id] + 1
							end
						end
					elseif team == 2 then
						if votecount[id] == 0 then
							if et.trap_Argv(1) == "yes" then
								et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^4voted ^2YES\"")
								votecount[id] = votecount[id] + 1
							elseif et.trap_Argv(1) == "no" then
								et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^4voted ^1NO\"")
								votecount[id] = votecount[id] + 1
							end
						end
					end
				end
			end
		end
	end
	return(0)
end
