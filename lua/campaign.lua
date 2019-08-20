-- campaign vote script to only enable voting campaigns (not maps) on goldrush (1st map in campaign) when there are 24 players or more (and disable voting certain campaigns like default, etc.)

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("campaign.lua "..et.FindSelf())
end

function et_ClientCommand(id, cmd)
		if string.lower(cmd) == "callvote" then
			if string.lower(et.trap_Argv(1)) == "map" and et.trap_Cvar_Get("vote_allow_map") == "1" then
				et.trap_SendServerCommand(id, "cpm \"^1Map voting is not enabled.\n\"")
				return 1
			elseif string.lower(et.trap_Argv(1)) == "nextmap" and et.trap_Cvar_Get("vote_allow_nextmap") == "1" then
				et.trap_SendServerCommand(id, "cpm \"^1Nextmap voting is not allowed.\n\"")
				return 1
			elseif string.lower(et.trap_Argv(1)) == "campaign" and et.trap_Cvar_Get("vote_allow_map") == "1" then
				local mapname = et.trap_Cvar_Get("mapname")
				if mapname ~= "goldrush" then
					et.trap_SendServerCommand(id, "cpm \"^1Campaign voting is only enabled on the first map (goldrush)\n\"")
					return 1
				else
					local players = 0
					for i=0,tonumber(et.trap_Cvar_Get("sv_maxClients"))-1 do
						if et.gentity_get(i,"inuse") then
							players = players + 1
						end
					end
					if players < 24 then
						et.trap_SendServerCommand(id, "cpm \"^1Not enough players to callvote a campaign (24 required).\n\"")
						return 1
					else
						if string.lower(et.trap_Argv(2)) == "cmpgn_centraleurope" or string.lower(et.trap_Argv(2)) == "cmpgn_northafrica" or
							string.lower(et.trap_Argv(2)) == "tot_6" or string.lower(et.trap_Argv(2)) == "tot_xmas" or string.lower(et.trap_Argv(2)) == "tot_final" or
							string.lower(et.trap_Argv(2)) == "los_10" then
								et.trap_SendServerCommand(id, "cpm \"^1Voting that campaign is not allowed, choose a different one.\n\"")
							return 1
						end
					end
				end
			end
		end
	return(0)
end
