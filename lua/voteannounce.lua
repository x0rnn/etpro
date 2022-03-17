-- voteannounce.lua, publicly shows who voted yes/no

votecount = {}
voteflag = false
teamvote = nil

function et_InitGame(levelTime, randomSeed, restart)
 	et.RegisterModname("voteannounce.lua "..et.FindSelf())

	local i = 0
	for i=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
		votecount[i] = 0
	end
end

function getID(cs2_name)
	local i = 0
	for i=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
		local name = et.gentity_get(i, "pers.netname")
		if name == cs2_name then
			voteflag = true
			return i
		end
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
				voteflag = false
				teamvote = nil
			end
		end
	end

	if et.trap_Argv(0) == "vote" then
		local cs = et.trap_GetConfigstring(6)
		local cs2 = et.trap_GetConfigstring(7)
		local cs2_name = ""
		if string.sub(cs2,1,5) == "KICK " then
			cs2_name = string.sub(cs2,6)
		elseif string.sub(cs2,1,8) == "PUTSPEC " then
			cs2_name = string.sub(cs2,9)
		end
		if cs2_name ~= "" then
			if voteflag == false then
				local player = getID(cs2_name)
				local team = tonumber(et.gentity_get(player, "sess.sessionTeam"))
				if team == 1 or team == 2 then
					if team == 1 then
						teamvote = 1
					elseif team == 2 then
						teamvote = 2
					end
				end
			end
		end

		if cs ~= "" then
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			if team == 1 or team == 2 then
				if teamvote == nil then
					if team == 1 then
						if votecount[id] == 0 then
							if et.trap_Argv(1) == "yes" then
								et.trap_SendServerCommand(-1, "sc \"" .. name .. " ^1voted ^2YES\n")
								votecount[id] = votecount[id] + 1
							elseif et.trap_Argv(1) == "no" then
								et.trap_SendServerCommand(-1, "sc \"" .. name .. " ^1voted NO\n")
								votecount[id] = votecount[id] + 1
							end
						end
					elseif team == 2 then
						if votecount[id] == 0 then
							if et.trap_Argv(1) == "yes" then
								et.trap_SendServerCommand(-1, "sc \"" .. name .. " ^4voted ^2YES\n")
								votecount[id] = votecount[id] + 1
							elseif et.trap_Argv(1) == "no" then
								et.trap_SendServerCommand(-1, "sc \"" .. name .. " ^4voted ^1NO\n")
								votecount[id] = votecount[id] + 1
							end
						end
					end
				else
					if teamvote == 1 then
						if team == 1 then
							if votecount[id] == 0 then
								if et.trap_Argv(1) == "yes" then
									et.trap_SendServerCommand(-1, "sc \"" .. name .. " ^1voted ^2YES\n")
									votecount[id] = votecount[id] + 1
								elseif et.trap_Argv(1) == "no" then
									et.trap_SendServerCommand(-1, "sc \"" .. name .. " ^1voted NO\n")
									votecount[id] = votecount[id] + 1
								end
							end
						end
					elseif teamvote == 2 then
						if team == 2 then
							if votecount[id] == 0 then
								if et.trap_Argv(1) == "yes" then
									et.trap_SendServerCommand(-1, "sc \"" .. name .. " ^1voted ^2YES\n")
									votecount[id] = votecount[id] + 1
								elseif et.trap_Argv(1) == "no" then
									et.trap_SendServerCommand(-1, "sc \"" .. name .. " ^1voted NO\n")
									votecount[id] = votecount[id] + 1
								end
							end
						end
					end
				end
			end
		end
	end
	return(0)
end
