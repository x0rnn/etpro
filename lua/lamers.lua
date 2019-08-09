-- lamers.lua by x0rnn
-- x% chance (default 10%) to gib panzer/mortar/arty/mg42 lamers on every 5th kill who have more than min_kill (default 25) kills and min_percent (default 75%) or more of all their kills are by panzer/mortar/arty/mg42
-- players who continuously push other players get a warning first and get put to spectators if they continue. Pushing up to 10 sec after spawn doesn't count due to possible blockers, etc.
-- players who continuously walk into other players' artillery (teamkill) will get a warning first and get put to spectators if they continue
-- intended for players with a lame gamestyle of spamming/camping panzer/mortar/arty/mg42 and not doing anything else and overall laming by pushing and intentionally walking into (team) arty

chance = 5
min_kills = 24
min_percent = 85

panzerlamers = {}
mortarlamers = {}
artylamers = {}
mglamers = {}
shoves = {}
artywalkers = {}
flag = false
respawn_time ={}

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("lamers.lua "..et.FindSelf())
	soundindex = et.G_SoundIndex("/sound/etpro/osp_goat.wav")
end

function et_ClientDisconnect(clientNum)
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	if panzerlamers[cl_guid] ~= nil then
		panzerlamers[cl_guid] = nil
	elseif mortarlamers[cl_guid] ~= nil then
		mortarlamers[cl_guid] = nil
	elseif artylamers[cl_guid] ~= nil then
		artylamers[cl_guid] = nil
	elseif mglamers[cl_guid] ~= nil then
		mglamers[cl_guid] = nil
	end
	if shoves[clientNum] ~= nil then
		shoves[clientNum] = nil
	end
	if artywalkers[clientNum] ~= nil then
		artywalkers[clientNum] = nil
	end
end

function et_Obituary(victim, killer, mod)
	-- mod: 17 panzer, 27 airstrike, 30 arty, 49 mobile mg42, 57 mortar
	
	gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
	if gamestate == 0 then
		if killer ~= 1022 and killer ~= 1023 then
			local cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(killer), "cl_guid")
			local k_teamid = et.gentity_get(killer, "sess.sessionTeam")
			local v_teamid = et.gentity_get(victim, "sess.sessionTeam")
			local kills = tonumber(et.gentity_get(killer, "sess.kills"))
			local name = et.gentity_get(killer, "pers.netname")
			local health = tonumber(et.gentity_get(killer, "health"))
			
			math.randomseed(et.trap_Milliseconds())

			if mod == 17 or mod == 27 or mod == 30 or mod == 49 or mod == 57 then
				if v_teamid ~= k_teamid then
					if mod == 17 then
						if tonumber(et.gentity_get(killer, "sess.skill", 5)) == 4 then
							if panzerlamers[cl_guid] == nil then
								panzerlamers[cl_guid] = {1, kills}
							else
								panzerlamers[cl_guid][1] = panzerlamers[cl_guid][1] + 1
								panzerlamers[cl_guid][2] = kills
							end

							if panzerlamers[cl_guid][1] > min_kills then
								if panzerlamers[cl_guid][1] / kills >= min_percent/100 then
									if math.mod(panzerlamers[cl_guid][1], 5) == 0 then
										if health > 0 then
											local choice = math.random(1, 100)
											if choice <= chance then
												msg = string.format("cpm  \"^3Oops. " .. name .. "^3's panzerfaust overheated from excessive use. It blew up in his face.\n")
												et.trap_SendServerCommand(-1, msg)
												et.G_Damage(killer, 80, 1022, 1000, 8, 34)
												et.G_Sound(killer, soundindex)
											end
										end
									end
								end
							end
						end

					elseif mod == 57 then
						if tonumber(et.gentity_get(killer, "sess.skill", 5)) > 0 then
							if mortarlamers[cl_guid] == nil then
								mortarlamers[cl_guid] = {1, kills}
							else
								mortarlamers[cl_guid][1] = mortarlamers[cl_guid][1] + 1
								mortarlamers[cl_guid][2] = kills
							end

							if mortarlamers[cl_guid][1] > min_kills then
								if mortarlamers[cl_guid][1] / kills >= min_percent/100 then
									if math.mod(mortarlamers[cl_guid][1], 5) == 0 then
										if health > 0 then
											local choice = math.random(1, 100)
											if choice <= chance then
												msg = string.format("cpm  \"^3Oops. " .. name .. "^3's mortar overheated from excessive use. It blew up in his face.\n")
												et.trap_SendServerCommand(-1, msg)
												et.G_Damage(killer, 80, 1022, 1000, 8, 34)
												et.G_Sound(killer, soundindex)
											end
										end
									end
								end
							end
						end

					elseif mod == 49 then
						if tonumber(et.gentity_get(killer, "sess.skill", 5)) > 1 then
							if mglamers[cl_guid] == nil then
								mglamers[cl_guid] = {1, kills}
							else
								mglamers[cl_guid][1] = mglamers[cl_guid][1] + 1
								mglamers[cl_guid][2] = kills
							end

							if mglamers[cl_guid][1] > min_kills then
								if mglamers[cl_guid][1] / kills >= min_percent/100 then
									if math.mod(mglamers[cl_guid][1], 5) == 0 then
										if health > 0 then
											local choice = math.random(1, 100)
											if choice <= chance then
												msg = string.format("cpm  \"^3Oops. " .. name .. "^3's MG42 overheated from excessive use. It blew up in his face.\n")
												et.trap_SendServerCommand(-1, msg)
												et.G_Damage(killer, 80, 1022, 1000, 8, 34)
												et.G_Sound(killer, soundindex)
											end
										end
									end
								end
							end
						end


					elseif mod == 27 or mod == 30 then
						if tonumber(et.gentity_get(killer, "sess.skill", 3)) >= 3 then
							if artylamers[cl_guid] == nil then
								artylamers[cl_guid] = {1, kills}
							else
								artylamers[cl_guid][1] = artylamers[cl_guid][1] + 1
								artylamers[cl_guid][2] = kills
							end

							if artylamers[cl_guid][1] > min_kills then
								if artylamers[cl_guid][1] / kills >= min_percent/100 then
									if math.mod(artylamers[cl_guid][1], 5) == 0 then
										if health > 0 then
											local choice = math.random(1, 100)
											if choice <= chance then
												msg = string.format("cpm  \"^3Huh. One of  " .. name .. "^3's airstrike grenades was actually a real grenade. It malfunctioned.\n")
												et.trap_SendServerCommand(-1, msg)
												et.G_Damage(killer, 80, 1022, 1000, 8, 34)
												et.G_Sound(killer, soundindex)
											end
										end
									end
								end
							end
						end
					end
				elseif v_teamid == k_teamid then
					if mod == 30 then
						if artywalkers[victim] == nil then
							artywalkers[victim] = { [killer] = 1 }
						else
							if artywalkers[victim][killer] == nil then
								artywalkers[victim][killer] = 1
							else
								artywalkers[victim][killer] = artywalkers[victim][killer] + 1
							end

							if artywalkers[victim][killer] == 6 then
								et.trap_SendServerCommand(victim, "chat \"^3You have walked into " .. et.gentity_get(killer, "pers.netname") .. "^3's arty a lot of times. This script thinks you're doing it intentionally.\"\n")
							end
							if artywalkers[victim][killer] == 7 then
								et.trap_SendServerCommand(victim, "chat \"^3If you continue walking into " .. et.gentity_get(killer, "pers.netname") .. "^3's arty, you will be put to spectators.\"\n")
							end
							if artywalkers[victim][killer] == 8 then
								et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref remove " .. victim .. "\n")
								et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(victim, "pers.netname") .. " ^3moved to spectators for intentionally walking into " .. et.gentity_get(killer, "pers.netname") .. "^3's arty too many times.\"\n")
							end
						end
					end
				end
			else
				if v_teamid ~= k_teamid then
					if panzerlamers[cl_guid] ~= nil then
						panzerlamers[cl_guid][2] = kills
					end
					if mortarlamers[cl_guid] ~= nil then
						mortarlamers[cl_guid][2] = kills
					end
					if artylamers[cl_guid] ~= nil then
						artylamers[cl_guid][2] = kills
					end
					if mglamers[cl_guid] ~= nil then
						mglamers[cl_guid][2] = kills
					end
				end
			end
		end
	end
end

function et_Print(text)
	if string.find(text, "etpro event:%s+%d+%s+%d+%s+(.*)shoved") then
		gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
		if gamestate == 0 then
			local junk1,junk2,id1,id2 = string.find(text, "etpro event:%s+(%d+)%s+(%d+)%s+(.*)shoved")
			if (et.gentity_get(tonumber(id2), "ps.powerups", 1) + 1000) <= et.trap_Milliseconds() then
				if respawn_time[tonumber(id2)] <= et.trap_Milliseconds() then
					local id1_team = et.gentity_get(tonumber(id1), "sess.sessionTeam")
					local id2_team = et.gentity_get(tonumber(id2), "sess.sessionTeam")
					if id1_team == id2_team then
						if shoves[tonumber(id1)] == nil then
							shoves[tonumber(id1)] = { [tonumber(id2)] = 1 }
						else
							if shoves[tonumber(id1)][tonumber(id2)] == nil then
								shoves[tonumber(id1)][tonumber(id2)] = 1
							else
								shoves[tonumber(id1)][tonumber(id2)] = shoves[tonumber(id1)][tonumber(id2)] + 1
							end

							if shoves[tonumber(id1)][tonumber(id2)] == 7 then
								et.trap_SendServerCommand(tonumber(id1), "chat \"^3You have shoved " .. et.gentity_get(tonumber(id2), "pers.netname") .. " ^3a lot of times. If you continue, you will be put to spectators.\"\n")
							end
							if shoves[tonumber(id1)][tonumber(id2)] == 10 then
								et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref remove " .. tonumber(id1) .. "\n")
								et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(tonumber(id1), "pers.netname") .. " ^3moved to spectators for pushing " .. et.gentity_get(tonumber(id2), "pers.netname") .. "^3's buttons one too many times.\"\n")
								flag = true
							end

							local i = 0
							local sum = 0
							for key,value in pairs(shoves[tonumber(id1)]) do
								i = i + 1
								sum = sum + value
							end
							if sum == 10 and i > 1 then
								et.trap_SendServerCommand(tonumber(id1), "chat \"^3You have shoved a lot of players. Is it really necessary?\"\n")
							end
							if sum == 15 and i > 1 then
								et.trap_SendServerCommand(tonumber(id1), "chat \"^3You have shoved a lot of players. If you continue, you will be put to spectators.\"\n")
							end
							if sum == 22 then
								et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref remove " .. tonumber(id1) .. "\n")
								et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(tonumber(id1), "pers.netname") .. " ^3moved to spectators for shoving too many players too many times.\"\n")
								flag = true
							end

							if flag == true then
								shoves[tonumber(id1)] = nil
							end
						end
					end
				end
			end
		end
	end
end

function et_ClientSpawn(id, revived)
	if revived ~= 1 then
		respawn_time[id] = et.trap_Milliseconds() + 10000
	end
end