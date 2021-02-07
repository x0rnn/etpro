-- lamers.lua by x0rnn
-- x% chance (default 10%) to gib panzer/mortar/arty/mg42 lamers on every 5th kill who have more than min_kill (default 25) kills and min_percent (default 85%) or more of all their kills are by panzer/mortar/arty/mg42
-- players who continuously push other players get a warning first and get put to spectators if they continue (default: single player 7x warn, 10x spec; multiple players 10x warn, 15x warn, 22x put spec). Pushing up to 10 sec after spawn doesn't count due to possible blockers, etc.
-- players who continuously walk into other players' artillery (teamkill) will get a warning first and get put to spectators if they continue (default: warn at 6 and 7, put spec at 8)
-- players who continuously teamkill (knife, pistols, smg (for medics only knife counts)) other players will get a warning first and get put to spectators if they continue (default: warn at 2 and 3, put spec at 4)
-- players who just hand out ammo and do nothing else will have their ammo packs taken away until they get more kills (defaults: <1 kills/10 ammo given, <5/20, <10/35, <15/55)
-- intended for players with a lame gamestyle of spamming/camping panzer/mortar/arty/mg42 and not doing anything else and overall laming by pushing and intentionally walking into (team) arty
-- removed panzerfaust when less than 12 players

panzerlamers = {}
mortarlamers = {}
artylamers = {}
mglamers = {}
chance = 15
chance_mortar = 30
min_kills = 25
min_kills_mortar = 20
min_percent = 85

shoves = {}
shove_flag = false
respawn_time = {}
single_shove_warn = 7
single_shove_spec = 10
multi_shove_warn1 = 10
multi_shove_warn2 = 15
multi_shove_spec = 22

tks = {}
tks_warn1 = 2
tks_warn2 = 3
tks_spec = 4

artywalkers = {}
artywalk_warn1 = 5
artywalk_warn2 = 6
artywalk_spec = 7

ammolamers = {}
ammo_given = {}
al_msg = {}
al_minkills_1 = 2
al_minkills_2 = 5
al_minkills_3 = 10
al_minkills_4 = 15
al_threshold_1 = 10
al_threshold_2 = 20
al_threshold_3 = 35
al_threshold_4 = 55

checkInterval = 10000
playerCount = 0
GS = 2

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("lamers.lua "..et.FindSelf())
	soundindex = et.G_SoundIndex("/sound/etpro/osp_goat.wav")
end

function et_ClientDisconnect(clientNum)
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	if panzerlamers[cl_guid] ~= nil then
		panzerlamers[cl_guid] = nil
	end
	if mortarlamers[cl_guid] ~= nil then
		mortarlamers[cl_guid] = nil
	end
	if artylamers[cl_guid] ~= nil then
		artylamers[cl_guid] = nil
	end
	if mglamers[cl_guid] ~= nil then
		mglamers[cl_guid] = nil
	end
	if shoves[clientNum] ~= nil then
		shoves[clientNum] = nil
	end
	if artywalkers[clientNum] ~= nil then
		artywalkers[clientNum] = nil
	end
	if tks[clientNum] ~= nil then
		tks[clientNum] = nil
	end 
	if ammo_given[clientNum] ~= nil then
		ammo_given[clientNum] = nil
	end
	if ammolamers[clientNum] ~= nil then
		ammolamers[clientNum] = nil
	end
	if al_msg[clientNum] ~= nil then
		al_msg[clientNum] = nil
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
			local name2 = et.gentity_get(victim, "pers.netname")
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

							if panzerlamers[cl_guid][1] >= min_kills then
								if panzerlamers[cl_guid][1] / kills >= min_percent/100 then
									if math.mod(panzerlamers[cl_guid][1], 5) == 0 then
										if health > 0 then
											local choice = math.random(1, 100)
											if choice <= chance then
												msg = string.format("cpm \"^3Oops. " .. name .. "^3's panzerfaust overheated from excessive use. It blew up in his face.\n")
												et.trap_SendServerCommand(-1, msg)
												et.G_LogPrint("LUA event: Oops. " .. name .. "'s panzerfaust overheated from excessive use. It blew up in his face.\n")
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

							if mortarlamers[cl_guid][1] >= min_kills_mortar then
								if mortarlamers[cl_guid][1] / kills >= min_percent/100 then
									if math.mod(mortarlamers[cl_guid][1], 5) == 0 then
										if health > 0 then
											local choice = math.random(1, 100)
											if choice <= chance_mortar then
												msg = string.format("cpm \"^3Oops. " .. name .. "^3's mortar overheated from excessive use. It blew up in his face.\n")
												et.trap_SendServerCommand(-1, msg)
												et.G_LogPrint("LUA event: Oops. " .. name .. "'s mortar overheated from excessive use. It blew up in his face.\n")
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

							if mglamers[cl_guid][1] >= min_kills then
								if mglamers[cl_guid][1] / kills >= min_percent/100 then
									if math.mod(mglamers[cl_guid][1], 5) == 0 then
										if health > 0 then
											local choice = math.random(1, 100)
											if choice <= chance then
												msg = string.format("cpm \"^3Oops. " .. name .. "^3's MG42 overheated from excessive use. It blew up in his face.\n")
												et.G_LogPrint("LUA event: Oops. " .. name .. "'s MG42 overheated from excessive use. It blew up in his face.\n")
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

							if artylamers[cl_guid][1] >= min_kills then
								if artylamers[cl_guid][1] / kills >= min_percent/100 then
									if math.mod(artylamers[cl_guid][1], 5) == 0 then
										if health > 0 then
											local choice = math.random(1, 100)
											if choice <= chance then
												msg = string.format("cpm \"^3Huh. One of " .. name .. "^3's airstrike grenades was actually a real grenade. It malfunctioned.\n")
												et.trap_SendServerCommand(-1, msg)
												et.G_LogPrint("LUA event: Huh. One of " .. name .. "'s airstrike grenades was actually a real grenade. It malfunctioned.\n")
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

							if artywalkers[victim][killer] == artywalk_warn1 then
								et.trap_SendServerCommand(victim, "chat \"^3You have walked into " .. name .. "^3's arty a lot of times. This script thinks you're doing it intentionally.\"\n")
								et.G_LogPrint("LUA event: " .. et.gentity_get(victim, "pers.netname") .. " walked into " .. name .. "'s arty " .. artywalk_warn1 .. " times.\n")
							end
							if artywalkers[victim][killer] == artywalk_warn2 then
								et.trap_SendServerCommand(victim, "chat \"^3If you continue walking into " .. name .. "^3's arty, you will be put to spectators.\"\n")
								et.G_LogPrint("LUA event: " .. et.gentity_get(victim, "pers.netname") .. " walked into " .. name .. "'s arty " .. artywalk_warn2 .. " times.\n")
							end
							if artywalkers[victim][killer] == artywalk_spec then
								et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref remove " .. victim .. "\n")
								et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(victim, "pers.netname") .. " ^3moved to spectators for intentionally walking into " .. name .. "^3's arty too many times.\"\n")
								et.G_LogPrint("LUA event: " .. et.gentity_get(victim, "pers.netname") .. " walked into " .. name .. "'s arty " .. artywalk_spec .. " times. Moved to spec for intentionally walking into arty.\n")
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
					if ammolamers[killer] == true then
						if ammo_given[killer] <= al_threshold_4 then
							if ammo_given[killer] <= al_threshold_3 then
								if ammo_given[killer] <= al_threshold_2 then
									if kills >= al_minkills_1 then
										ammolamers[killer] = false
									end
								else
									if kills >= al_minkills_2 then
										ammolamers[killer] = false
									end
								end
							else
								if kills >= al_minkills_3 then
									ammolamers[killer] = false
								end
							end
						else
							if kills >= al_minkills_4 then
								ammolamers[killer] = false
							end
						end
					end
				else
					if mod == 24 then
						msg = string.format("chat \"" .. name .. " ^3gibbed for pushing " .. et.gentity_get(victim, "pers.netname") .. "^3 into his death.\n")
						et.G_LogPrint("LUA event: " .. name .. " gibbed for pushing " .. et.gentity_get(victim, "pers.netname") .. " into his death.\n")
						et.trap_SendServerCommand(-1, msg)
						et.G_Damage(killer, 80, 1022, 1000, 8, 34)
						et.G_Sound(killer, et.G_SoundIndex("/sound/etpro/osp_goat.wav"))
					end
					if mod == 6 or mod == 7 or mod == 8 or mod == 9 or mod == 10 or mod == 58 or mod == 59 then -- knife, luger, colt, mp40, thompson, akimbo colt, akimbo luger
						if et.gentity_get(killer,"sess.PlayerType") ~= 1 then -- medic
							if tks[killer] == nil then
								tks[killer] = { [victim] = 1 }
							else
								if tks[killer][victim] == nil then
									tks[killer][victim] = 1
								else
									tks[killer][victim] = tks[killer][victim] + 1
								end

								if tks[killer][victim] == tks_warn1 then
									et.trap_SendServerCommand(killer, "chat \"^3You teamkilled " .. name2 .. "^3" .. tks_warn1 .. " times. This script thinks you're doing it intentionally.\"\n")
									et.G_LogPrint("LUA event: " .. et.gentity_get(killer, "pers.netname") .. " teamkilled " .. name2 .. " " .. tks_warn1 .. " times.\n")
								end
								if tks[killer][victim] == tks_warn2 then
									et.trap_SendServerCommand(killer, "chat \"^3If you continue teamkilling " .. name2 .. "^3, you will be put to spectators.\"\n")
									et.G_LogPrint("LUA event: " .. et.gentity_get(killer, "pers.netname") .. " teamkilled " .. name2 .. " " .. tks_warn2 .. " times.\n")
								end
								if tks[killer][victim] == tks_spec then
									et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref remove " .. killer .. "\n")
									et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(killer, "pers.netname") .. " ^3moved to spectators for intentionally teamkilling " .. name2 .. "^3 too many times.\"\n")
									et.G_LogPrint("LUA event: " .. et.gentity_get(killer, "pers.netname") .. " teamkilled " .. name2 .. "' " .. tks_spec .. " times. Moved to spec for intentionally teamkilling.\n")
								end
							end
						else
							if mod == 6 then -- knife
								if tks[killer] == nil then
									tks[killer] = { [victim] = 1 }
								else
									if tks[killer][victim] == nil then
										tks[killer][victim] = 1
									else
										tks[killer][victim] = tks[killer][victim] + 1
									end

									if tks[killer][victim] == tks_warn1 then
										et.trap_SendServerCommand(killer, "chat \"^3You teamkilled " .. name2 .. "^3" .. tks_warn1 .. " times. This script thinks you're doing it intentionally.\"\n")
										et.G_LogPrint("LUA event: " .. et.gentity_get(killer, "pers.netname") .. " teamkilled " .. name2 .. " " .. tks_warn1 .. " times.\n")
									end
									if tks[killer][victim] == tks_warn2 then
										et.trap_SendServerCommand(killer, "chat \"^3If you continue teamkilling " .. name2 .. "^3, you will be put to spectators.\"\n")
										et.G_LogPrint("LUA event: " .. et.gentity_get(killer, "pers.netname") .. " teamkilled " .. name2 .. " " .. tks_warn2 .. " times.\n")
									end
									if tks[killer][victim] == tks_spec then
										et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref remove " .. killer .. "\n")
										et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(killer, "pers.netname") .. " ^3moved to spectators for intentionally teamkilling " .. name2 .. "^3 too many times.\"\n")
										et.G_LogPrint("LUA event: " .. et.gentity_get(killer, "pers.netname") .. " teamkilled " .. name2 .. "' " .. tks_spec .. " times. Moved to spec for intentionally teamkilling.\n")
									end
								end
							end
						end
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

							if shoves[tonumber(id1)][tonumber(id2)] == single_shove_warn then
								et.trap_SendServerCommand(tonumber(id1), "chat \"^3You have shoved " .. et.gentity_get(tonumber(id2), "pers.netname") .. " ^3a lot of times. If you continue, you will be put to spectators.\"\n")
								et.G_LogPrint("LUA event: " .. et.gentity_get(tonumber(id1), "pers.netname") .. " shoved " .. et.gentity_get(tonumber(id2), "pers.netname") .. " " .. single_shove_warn .. " times.\n")
							end
							if shoves[tonumber(id1)][tonumber(id2)] == single_shove_spec then
								et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref remove " .. tonumber(id1) .. "\n")
								et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(tonumber(id1), "pers.netname") .. " ^3moved to spectators for pushing " .. et.gentity_get(tonumber(id2), "pers.netname") .. "^3's buttons one too many times.\"\n")
								et.G_LogPrint("LUA event: " .. et.gentity_get(tonumber(id1), "pers.netname") .. " shoved " .. et.gentity_get(tonumber(id2), "pers.netname") .. " " .. single_shove_spec .. " times. Moved to spec.\n")
								shove_flag = true
							end

							local i = 0
							local sum = 0
							for key,value in pairs(shoves[tonumber(id1)]) do
								i = i + 1
								sum = sum + value
							end
							if sum == multi_shove_warn1 and i > 1 then
								et.trap_SendServerCommand(tonumber(id1), "chat \"^3You have shoved a lot of players. Is it really necessary?\"\n")
								et.G_LogPrint("LUA event: " .. et.gentity_get(tonumber(id1), "pers.netname") .. " shoved a lot of players " .. multi_shove_warn1 .. " times.\n")
							end
							if sum == multi_shove_warn2 and i > 1 then
								et.trap_SendServerCommand(tonumber(id1), "chat \"^3You have shoved a lot of players. If you continue, you will be put to spectators.\"\n")
								et.G_LogPrint("LUA event: " .. et.gentity_get(tonumber(id1), "pers.netname") .. " shoved a lot of players " .. multi_shove_warn2 .. " times.\n")
							end
							if sum == multi_shove_spec then
								et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref remove " .. tonumber(id1) .. "\n")
								et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(tonumber(id1), "pers.netname") .. " ^3moved to spectators for shoving too many players too many times.\"\n")
								et.G_LogPrint("LUA event: " .. et.gentity_get(tonumber(id1), "pers.netname") .. " shoved a lot of players " .. multi_shove_spec .. " times. Moved to spec.\n")
								shove_flag = true
							end

							if shove_flag == true then
								shoves[tonumber(id1)] = nil
							end
						end
					end
				end
			end
		end
	elseif string.find(text, "Ammo_Pack") then
		gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
		if gamestate == 0 then
			local junk1,junk2,id = string.find(text, "^Ammo_Pack:%s+(%d+)%s+%d+")
			if ammo_given[tonumber(id)] == nil then
				ammo_given[tonumber(id)] = 1
			else
				ammo_given[tonumber(id)] = ammo_given[tonumber(id)] + 1

				if ammo_given[tonumber(id)] >= al_threshold_1 and ammo_given[tonumber(id)] <= al_threshold_2 then
					local kills = tonumber(et.gentity_get(tonumber(id), "sess.kills"))
					if kills < al_minkills_1 then
						ammolamers[tonumber(id)] = true
						al_msg[tonumber(id)] = false
						if ammolamers[tonumber(id)] == true then
							if al_msg[tonumber(id)] == false then
								et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(tonumber(id), "pers.netname") .. " ^3got his ammo packs confiscated until he gets more kills.\"\n")
								al_msg[tonumber(id)] = true
							end
							et.gentity_set(tonumber(id), "ps.ammo", 12, 0)
							et.gentity_set(tonumber(id), "ps.ammoclip", 12, 0)
						end
					end
				elseif ammo_given[tonumber(id)] >= al_threshold_2 and ammo_given[tonumber(id)] <= al_threshold_3 then
					local kills = tonumber(et.gentity_get(tonumber(id), "sess.kills"))
					if kills < al_minkills_2 then
						ammolamers[tonumber(id)] = true
						al_msg[tonumber(id)] = false
						if ammolamers[tonumber(id)] == true then
							if al_msg[tonumber(id)] == false then
								et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(tonumber(id), "pers.netname") .. " ^3got his ammo packs confiscated until he gets more kills.\"\n")
								al_msg[tonumber(id)] = true
							end
							et.gentity_set(tonumber(id), "ps.ammo", 12, 0)
							et.gentity_set(tonumber(id), "ps.ammoclip", 12, 0)
						end
					end
				elseif ammo_given[tonumber(id)] > al_threshold_3 and ammo_given[tonumber(id)] <= al_threshold_4 then
					local kills = tonumber(et.gentity_get(tonumber(id), "sess.kills"))
					if kills < al_minkills_3 then
						ammolamers[tonumber(id)] = true
						al_msg[tonumber(id)] = false
						if ammolamers[tonumber(id)] == true then
							if al_msg[tonumber(id)] == false then
								et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(tonumber(id), "pers.netname") .. " ^3got his ammo packs confiscated until he gets more kills.\"\n")
								al_msg[tonumber(id)] = true
							end
							et.gentity_set(tonumber(id), "ps.ammo", 12, 0)
							et.gentity_set(tonumber(id), "ps.ammoclip", 12, 0)
						end
					end
				elseif ammo_given[tonumber(id)] > al_threshold_4 then
					local kills = tonumber(et.gentity_get(tonumber(id), "sess.kills"))
					if kills < al_minkills_4 then
						ammolamers[tonumber(id)] = true
						al_msg[tonumber(id)] = false
						if ammolamers[tonumber(id)] == true then
							if al_msg[tonumber(id)] == false then
								et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(tonumber(id), "pers.netname") .. " ^3got his ammo packs confiscated until he gets more kills.\"\n")
								al_msg[tonumber(id)] = true
							end
							et.gentity_set(tonumber(id), "ps.ammo", 12, 0)
							et.gentity_set(tonumber(id), "ps.ammoclip", 12, 0)
						end
					end
				end
			end
		end
	elseif string.find(text, "weapon_magicammo") then
		gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
		if gamestate == 0 then
			local i, j = string.find(text, "%d+")
			local id = tonumber(string.sub(text, i, j))
			if ammolamers[id] == true then
				et.gentity_set(id, "ps.ammo", 12, 0)
				et.gentity_set(id, "ps.ammoclip", 12, 0)
			end
		end
	end
end

function et_RunFrame( levelTime )
	if math.mod(levelTime,checkInterval) ~= 0 then return end

	GS = tonumber(et.trap_Cvar_Get("gamestate"))
	if GS == 0 then
		playerCount = 0
		for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
			local team = tonumber(et.gentity_get(j, "sess.sessionTeam"))
			if team == 1 or team == 2 then
				playerCount = playerCount + 1
			end
		end
	end
end

function et_ClientSpawn(id, revived)
	if revived ~= 1 then
		local team = et.gentity_get(id, "sess.sessionTeam")
		if team == 1 or team == 2 then
			respawn_time[id] = et.trap_Milliseconds() + 10000
	
			if ammolamers[id] == true then
				if al_msg[id] == false then
					et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(id, "pers.netname") .. " ^3got his ammo packs confiscated until he gets more kills.\"\n")
					al_msg[id] = true
				end
				et.gentity_set(id, "ps.ammo", 12, 0)
				et.gentity_set(id, "ps.ammoclip", 12, 0)
			end
		end
		if GS == 0 then
			if playerCount < 12 then
				if et.gentity_get(id,"sess.latchPlayerType") == 0 then
					if et.gentity_get(id, "sess.latchPlayerWeapon") == 5 then
						et.gentity_set(id,"sess.latchPlayerType", 1)
						et.G_Damage(id, 80, 1022, 1000, 8, 34)
						et.trap_SendServerCommand(-1, "chat \"^3No panzerfaust when less than 12 players!\"")
					end
				end
			end
		end
	end
end

function et_ClientCommand(id, command)
	if et.trap_Argv(0) == "say" then
		args = et.ConcatArgs(1)
		local args_table = {}
		cnt = 0
		for i in string.gfind(args, "%S+") do
			table.insert(args_table, i)
			cnt = cnt + 1
		end
		if args_table[1] == "!admin" then
			if cnt == 1 then
				et.trap_SendServerCommand(id, "chat \"^3Please include a reason when you're calling an admin!\"")
				return 1
			elseif cnt == 2 then
				if string.lower(args_table[2]) == "admin" then
					et.trap_SendServerCommand(id, "chat \"^3Please include a valid reason when calling an admin.\"")
					return 1
				end
			end
		end
	end
	return(0)
end
