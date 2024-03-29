-- lamers.lua by x0rnn
-- x% chance (default 15%) to gib panzer/mortar/mg42 lamers on every 5th kill who have more than min_kill (default 25) kills and min_percent (default 85%) or more of all their kills are by panzer/mortar/mg42
-- players who continuously push other players get a warning first and get put to spectators if they continue (default: single player 7x warn, 10x spec; multiple players 10x warn, 15x warn, 22x put spec). Pushing up to 10 sec after spawn doesn't count due to possible blockers, etc.
-- players who continuously walk into other players' artillery (teamkill) will get a warning first and get put to spectators if they continue (default: warn at 6 and 7, put spec at 8)
-- players who continuously walk onto other players' landmines (teamkill) will get a warning first and get put to spectators if they continue (default: warn at 4 and 5, put spec at 6)
-- players who continuously teamkill (knife, pistols, smg (for medics only knife counts)) other players will get a warning first and get put to spectators if they continue (default: warn at 2, gib at 3, put spec at 4)
-- fieldops who just hand out ammo and do nothing else will have their ammo packs taken away until they get more kills (defaults: <2 kills/10 ammo given, <5/20, <10/35, <15/55)
-- fieldops who just call arty and do nothing else will have their binoculars/arty taken away until they get more normal kills (defaults: <2 normal kills/10 arty kills, <5/15, <10/20, <15/30)
-- gibs rambo medics with >= 30 kills and revive ratio less than 6.6% on every 10th kill (30, 40, etc.) if their revive ratio doesn't improve (basically 1 new revive is all that's needed)
-- intended for players with a lame gamestyle of ramboing/spamming/camping panzer/mortar/arty/mg42 and not doing anything else and overall laming by pushing and intentionally walking into team arty
-- removed panzerfaust when less than 12 players
-- removed riflenades when less than 6 players
-- removed mortar when less than 16 players
-- warn (td_warn) & kick (td_kick) players on excessive team damage (td remains even after going spec, so they can't reset)

panzerlamers = {}
mortarlamers = {}
mglamers = {}
nonhwkills = {}
fopkills = {}
chance = 15
chance_mortar = 30
chance_mg42 = 15
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

minewalkers = {}
minewalk_warn1 = 4
minewalk_warn2 = 5
minewalk_spec = 6

ammolamers = {}
ammo_given = {}
al_minkills_1 = 2
al_minkills_2 = 5
al_minkills_3 = 10
al_minkills_4 = 15
al_threshold_1 = 10
al_threshold_2 = 20
al_threshold_3 = 35
al_threshold_4 = 55

foplamers = {}
foplamer = {}
fop_minkills_1 = 2
fop_minkills_2 = 5
fop_minkills_3 = 10
fop_minkills_4 = 15
fop_threshold_1 = 10
fop_threshold_2 = 15
fop_threshold_3 = 20
fop_threshold_4 = 30

revives = {}
medickills = {}

players = {}
team_dmg = {}
teamswitch = {}
team2 = {}
td_warn = 700
td_kick = 1100

checkInterval = 10000
checkInterval2 = 60000
playerCount = 0
GS = 2
GSFlag = false

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("lamers.lua "..et.FindSelf())
	soundindex = et.G_SoundIndex("/sound/etpro/osp_goat.wav")

    local i = 0
	for i=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
		team_dmg[i] = 0
		players[i] = nil
		teamswitch[i] = false
		team2[i] = nil
	end
end

function et_ClientDisconnect(clientNum)
	local cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	if panzerlamers[cl_guid] ~= nil then
		panzerlamers[cl_guid] = nil
	end
	if mortarlamers[cl_guid] ~= nil then
		mortarlamers[cl_guid] = nil
	end
	if foplamers[cl_guid] ~= nil then
		foplamers[cl_guid] = nil
	end
	if foplamer[clientNum] ~= nil then
		foplamer[clientNum] = nil
	end
	if mglamers[cl_guid] ~= nil then
		mglamers[cl_guid] = nil
	end
	if nonhwkills[cl_guid] ~= nil then
		nonhwkills[cl_guid] = nil
	end
	if fopkills[cl_guid] ~= nil then
		fopkills[cl_guid] = nil
	end
	if shoves[clientNum] ~= nil then
		shoves[clientNum] = nil
	end
	if artywalkers[clientNum] ~= nil then
		artywalkers[clientNum] = nil
	end
	if minewalkers[clientNum] ~= nil then
		minewalkers[clientNum] = nil
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
	if revives[clientNum] ~= nil then
		revives[clientNum] = nil
	end
	if medickills[clientNum] ~= nil then
		medickills[clientNum] = nil
	end
	team_dmg[clientNum] = 0
	players[clientNum] = nil
	team2[clientNum] = nil
	teamswitch[clientNum] = false
end

function et_ClientBegin(id)
    local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
	if players[id] == nil then
		players[id] = team
	end
end

function et_ClientUserinfoChanged(clientNum)
	local cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid") 
    local team = tonumber(et.gentity_get(clientNum, "sess.sessionTeam"))

	if players[clientNum] == nil then
		players[clientNum] = team
	end

    if players[clientNum] ~= team then
		teamswitch[clientNum] = true
        if (team == 1 or team == 2) and players[clientNum] ~= 3 then
			--team_dmg[clientNum] = 0 -- reset if going from axis to allies or reverse
        end
        if (team == 1 or team == 2) and players[clientNum] == 3 then
            if team2[clientNum] ~= nil then
				if team ~= team2[clientNum] then
					--team_dmg[clientNum] = 0 -- reset if going from axis/allies to spec and then opposite team as before
				end
            end
        end
        if team == 3 then
			team2[clientNum] = players[clientNum]
			nonhwkills[cl_guid] = nil
			panzerlamers[cl_guid] = nil
			mortarlamers[cl_guid] = nil
			mglamers[cl_guid] = nil
			foplamers[cl_guid] = nil
			ammolamers[cl_guid] = nil
			fopkills[cl_guid] = nil
		end
    end

    players[clientNum] = team
end

function et_ConsoleCommand()
	if et.trap_Argv(0) == "pb_sv_kick" then
		if et.trap_Argc() >= 2 then
			local cno = tonumber(et.trap_Argv(1))
			if cno then
				cno = cno - 1
				et_ClientDisconnect(cno)
			end
		end
		return 1
	end
    return(0)
end

local function roundNum(num, n)
	local mult = 10^(n or 0)
	return math.floor(num * mult + 0.5) / mult
end

function et_Obituary(victim, killer, mod)
	-- mod: 17 panzer, 30 arty, 49 mobile mg42, 57 mortar
	
	if GS == 0 then
		if killer ~= 1022 and killer ~= 1023 then
			local cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(killer), "cl_guid")
			local k_teamid = et.gentity_get(killer, "sess.sessionTeam")
			local v_teamid = et.gentity_get(victim, "sess.sessionTeam")
			--local kills = tonumber(et.gentity_get(killer, "sess.kills"))
			local name = et.gentity_get(killer, "pers.netname")
			local name2 = et.gentity_get(victim, "pers.netname")
			local health = tonumber(et.gentity_get(killer, "health"))
			
			math.randomseed(et.trap_Milliseconds())

			if mod == 17 or mod == 30 or mod == 49 or mod == 57 then
				if v_teamid ~= k_teamid then
					if mod == 17 then
						if tonumber(et.gentity_get(killer, "sess.skill", 5)) == 4 then
							if panzerlamers[cl_guid] == nil then
								if nonhwkills[cl_guid] == nil then
									nonhwkills[cl_guid] = 0
									panzerlamers[cl_guid] = {1, nonhwkills[cl_guid]}
								else
									panzerlamers[cl_guid] = {1, nonhwkills[cl_guid]}
								end
							else
								panzerlamers[cl_guid][1] = panzerlamers[cl_guid][1] + 1
							end

							if panzerlamers[cl_guid][1] >= min_kills then
								if panzerlamers[cl_guid][1] / (nonhwkills[cl_guid] + panzerlamers[cl_guid][1]) >= min_percent/100 then
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
								if nonhwkills[cl_guid] == nil then
									nonhwkills[cl_guid] = 0
									mortarlamers[cl_guid] = {1, nonhwkills[cl_guid]}
								else
									mortarlamers[cl_guid] = {1, nonhwkills[cl_guid]}
								end
							else
								mortarlamers[cl_guid][1] = mortarlamers[cl_guid][1] + 1
							end

							if mortarlamers[cl_guid][1] >= min_kills_mortar then
								if mortarlamers[cl_guid][1] / (nonhwkills[cl_guid] + mortarlamers[cl_guid][1]) >= min_percent/100 then
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
								if nonhwkills[cl_guid] == nil then
									nonhwkills[cl_guid] = 0
									mglamers[cl_guid] = {1, nonhwkills[cl_guid]}
								else
									mglamers[cl_guid] = {1, nonhwkills[cl_guid]}
								end
							else
								mglamers[cl_guid][1] = mglamers[cl_guid][1] + 1
							end

							if mglamers[cl_guid][1] >= min_kills then
								if mglamers[cl_guid][1] / (nonhwkills[cl_guid] + mglamers[cl_guid][1]) >= min_percent/100 then
									if math.mod(mglamers[cl_guid][1], 5) == 0 then
										if health > 0 then
											local choice = math.random(1, 100)
											if choice <= chance_mg42 then
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

					elseif mod == 30 then
						--if tonumber(et.gentity_get(killer, "sess.skill", 3)) >= 3 then
							if fopkills[cl_guid] == nil or fopkills[cl_guid] == 0 then
								fopkills[cl_guid] = 1
							else
								fopkills[cl_guid] = fopkills[cl_guid] + 1
							end
							if foplamers[cl_guid] == nil then
								if nonhwkills[cl_guid] == nil then
									nonhwkills[cl_guid] = 0
									foplamers[cl_guid] = {1, nonhwkills[cl_guid]}
								else
									foplamers[cl_guid] = {1, nonhwkills[cl_guid]}
								end
							else
								foplamers[cl_guid][1] = foplamers[cl_guid][1] + 1
							end

							if foplamers[cl_guid][1] >= fop_threshold_1 and foplamers[cl_guid][1] <= fop_threshold_2 then
								if nonhwkills[cl_guid] < fop_minkills_1 then
									foplamer[killer] = true
									et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(killer, "pers.netname") .. " ^3's binoculars broke from overuse. More kills = new pair.\"\n")
									et.gentity_set(killer, "ps.stats", 1, 0)
									et.G_LogPrint("LUA event: " .. et.gentity_get(killer, "pers.netname") .. "'s binoculars broke from overuse\n")
								end
							elseif foplamers[cl_guid][1] >= fop_threshold_2 and foplamers[cl_guid][1] <= fop_threshold_3 then
								if nonhwkills[cl_guid] < fop_minkills_2 then
									foplamer[cl_guid] = true
									et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(killer, "pers.netname") .. " ^3's binoculars broke from overuse. More kills = new pair.\"\n")
									et.gentity_set(killer, "ps.stats", 1, 0)
									et.G_LogPrint("LUA event: " .. et.gentity_get(killer, "pers.netname") .. "'s binoculars broke from overuse\n")
								end
							elseif foplamers[cl_guid][1] > fop_threshold_3 and foplamers[cl_guid][1] <= fop_threshold_4 then
								if nonhwkills[cl_guid] < fop_minkills_3 then
									foplamer[killer] = true
									et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(killer, "pers.netname") .. " ^3's binoculars broke from overuse. More kills = new pair.\"\n")
									et.gentity_set(killer, "ps.stats", 1, 0)
									et.G_LogPrint("LUA event: " .. et.gentity_get(killer, "pers.netname") .. "'s binoculars broke from overuse\n")
								end
							elseif foplamers[cl_guid][1] > fop_threshold_4 then
								if nonhwkills[cl_guid] < fop_minkills_4 then
									foplamer[killer] = true
									et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(killer, "pers.netname") .. " ^3's binoculars broke from overuse. More kills = new pair.\"\n")
									et.gentity_set(killer, "ps.stats", 1, 0)
									et.G_LogPrint("LUA event: " .. et.gentity_get(killer, "pers.netname") .. "'s binoculars broke from overuse\n")
								end
							end
						--end
					end
				elseif v_teamid == k_teamid then
					if killer ~= victim then
						team_dmg[killer] = tonumber(et.gentity_get(killer, "sess.team_damage"))
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
						elseif mod == 45 then
							if minewalkers[victim] == nil then
								minewalkers[victim] = { [killer] = 1 }
							else
								if minewalkers[victim][killer] == nil then
									minewalkers[victim][killer] = 1
								else
									minewalkers[victim][killer] = minewalkers[victim][killer] + 1
								end

								if minewalkers[victim][killer] == minewalk_warn1 then
									et.trap_SendServerCommand(victim, "chat \"^3You have stepped on " .. name .. "^3's mines a lot of times. This script thinks you're doing it intentionally.\"\n")
									et.G_LogPrint("LUA event: " .. et.gentity_get(victim, "pers.netname") .. " stepped on " .. name .. "'s mines " .. minewalk_warn1 .. " times.\n")
								end
								if minewalkers[victim][killer] == minewalk_warn2 then
									et.trap_SendServerCommand(victim, "chat \"^3If you continue stepping on " .. name .. "^3's mines, you will be put to spectators.\"\n")
									et.G_LogPrint("LUA event: " .. et.gentity_get(victim, "pers.netname") .. " stepped on " .. name .. "'s mines " .. minewalk_warn2 .. " times.\n")
								end
								if minewalkers[victim][killer] == minewalk_spec then
									et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref remove " .. victim .. "\n")
									et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(victim, "pers.netname") .. " ^3moved to spectators for intentionally stepping on " .. name .. "^3's mines too many times.\"\n")
									et.G_LogPrint("LUA event: " .. et.gentity_get(victim, "pers.netname") .. " stepped on " .. name .. "'s mines " .. minewalk_spec .. " times. Moved to spec for intentionally stepping on mines.\n")
								end
							end
						end
					end
				end
			else
				if v_teamid ~= k_teamid then
					if et.gentity_get(killer, "sess.PlayerType") == 1 then
						if medickills[killer] == nil then
							medickills[killer] = 1
						else
							medickills[killer] = medickills[killer] + 1
						end
						
						local kr = 0
						if playerCount > 20 then
							if medickills[killer] >= 25 then
								if revives[killer] == nil then
									revives[killer] = 0
								end
								kr = revives[killer] / medickills[killer]
								if kr < 0.066 then
									if math.mod(medickills[killer], 10) == 0 then
										msg = string.format("cpm \"" .. name .. " ^3flexed his Rambo muscles too much and exploded. ^7" .. medickills[killer] .. " ^3kills, ^7" .. revives[killer] .. " ^3revives, ^7" .. roundNum(kr, 3)*100 .. " ^3ratio.\n")
										et.trap_SendServerCommand(-1, msg)
										et.G_LogPrint("LUA event: " .. et.gentity_get(killer, "pers.netname") .. " flexed his Rambo muscles too much and exploded. " .. medickills[killer] .. " kills, " .. revives[killer] .. " revives, " .. roundNum(kr, 3)*100 .. " ratio. \n")
										et.gentity_set(killer, "ps.powerups", 1, 0)
										et.G_Damage(killer, 80, 1022, 1000, 8, 34)
										et.G_Sound(killer, soundindex)
									else
										if math.mod(medickills[killer], 10) >= 5 then
											et.trap_SendServerCommand(killer, "chat \"^3You have ^1" .. 10 - math.mod(medickills[killer], 10) .. " ^3kills left without reviving a teammate before you explode.\"\n")
										end
									end
								end
							end
						end
               	end

					if et.gentity_get(killer, "sess.PlayerType") == 0 then
						if nonhwkills[cl_guid] == nil then
							nonhwkills[cl_guid] = 1
						else
							nonhwkills[cl_guid] = nonhwkills[cl_guid] + 1
						end
					end
					
					if et.gentity_get(killer, "sess.PlayerType") == 3 then
						if fopkills[cl_guid] == nil or fopkills[cl_guid] == 0 then
							fopkills[cl_guid] = 1
						else
							if mod ~= 27 then --airstrike
								if nonhwkills[cl_guid] == nil then
									nonhwkills[cl_guid] = 1
								else
									nonhwkills[cl_guid] = nonhwkills[cl_guid] + 1
								end
							end
							fopkills[cl_guid] = fopkills[cl_guid] + 1
						end
 
						if ammolamers[killer] == true then
							if ammo_given[killer] <= al_threshold_4 then
								if ammo_given[killer] <= al_threshold_3 then
									if ammo_given[killer] <= al_threshold_2 then
										if fopkills[cl_guid] >= al_minkills_1 then
											ammolamers[killer] = false
											et.trap_SendServerCommand(killer, "chat \"^3You've been given your ammo crates back!\"\n")
											et.gentity_set(killer, "ps.ammo", 12, 1)
											et.gentity_set(killer, "ps.ammoclip", 12, 1)
										end
									else
										if fopkills[cl_guid] >= al_minkills_2 then
											ammolamers[killer] = false
											et.trap_SendServerCommand(killer, "chat \"^3You've been given your ammo crates back!\"\n")
											et.gentity_set(killer, "ps.ammo", 12, 1)
											et.gentity_set(killer, "ps.ammoclip", 12, 1)
										end
									end
								else
									if fopkills[cl_guid] >= al_minkills_3 then
										ammolamers[killer] = false
										et.trap_SendServerCommand(killer, "chat \"^3You've been given your ammo crates back!\"\n")
										et.gentity_set(killer, "ps.ammo", 12, 1)
										et.gentity_set(killer, "ps.ammoclip", 12, 1)
									end
								end
							else
								if fopkills[cl_guid] >= al_minkills_4 then
									ammolamers[killer] = false
									et.trap_SendServerCommand(killer, "chat \"^3You've been given your ammo crates back!\"\n")
									et.gentity_set(killer, "ps.ammo", 12, 1)
									et.gentity_set(killer, "ps.ammoclip", 12, 1)
								end
							end
						end

						if foplamer[killer] == true then
							if foplamers[cl_guid][1] <= fop_threshold_4 then
								if foplamers[cl_guid][1] <= fop_threshold_3 then
									if foplamers[cl_guid][1] <= fop_threshold_2 then
										if nonhwkills[cl_guid] >= fop_minkills_1 then
											foplamer[killer] = false
											et.trap_SendServerCommand(killer, "chat \"^3You've been rewarded with a brand new set of binoculars!\"\n")
											et.gentity_set(killer, "ps.stats", 1, 64)
										end
									else
										if nonhwkills[cl_guid] >= fop_minkills_2 then
											foplamer[killer] = false
											et.trap_SendServerCommand(killer, "chat \"^3You've been rewarded with a brand new set of binoculars!\"\n")
											et.gentity_set(killer, "ps.stats", 1, 64)
										end
									end
								else
									if nonhwkills[cl_guid] >= fop_minkills_3 then
										foplamer[killer] = false
										et.trap_SendServerCommand(killer, "chat \"^3You've been rewarded with a brand new set of binoculars!\"\n")
										et.gentity_set(killer, "ps.stats", 1, 64)
									end
								end
							else
								if nonhwkills[cl_guid] >= fop_minkills_4 then
									foplamer[killer] = false
									et.trap_SendServerCommand(killer, "chat \"^3You've been rewarded with a brand new set of binoculars!\"\n")
									et.gentity_set(killer, "ps.stats", 1, 64)
								end
							end
						end
					end
				else
					if killer ~= victim then
						team_dmg[killer] = tonumber(et.gentity_get(killer, "sess.team_damage"))
					end
					if mod == 24 then
						msg = string.format("chat \"" .. name .. " ^3gibbed for pushing " .. et.gentity_get(victim, "pers.netname") .. "^3 into his death.\n")
						et.G_LogPrint("LUA event: " .. name .. " gibbed for pushing " .. et.gentity_get(victim, "pers.netname") .. " into his death.\n")
						et.trap_SendServerCommand(-1, msg)
						et.G_Damage(killer, 80, 1022, 1000, 8, 34)
						et.G_Sound(killer, et.G_SoundIndex("/sound/etpro/osp_goat.wav"))
					end
					if mod == 6 or mod == 7 or mod == 8 or mod == 9 or mod == 10 or mod == 58 or mod == 59 or mod == 11 or mod == 12 or mod == 14 or mod == 15 or mod == 55 or mod == 50 or mod == 60 or mod == 61 or mod == 41 or mod == 42 then -- knife, luger, colt, mp40, thompson, akimbo colt, akimbo luger, sten, garand, silenced luger, fg42, k43, silenced colt, akimbo silenced colt, akimbo silenced luger, garand rifle, k43 rifle
						if tonumber(et.gentity_get(victim, "ps.powerups", 8)) ~= 1 then -- victim not in disguise 
							if et.gentity_get(killer,"sess.PlayerType") ~= 1 then -- killer not medic
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
										et.gentity_set(killer, "ps.powerups", 1, 0)
										et.G_Damage(killer, 80, 1022, 1000, 8, 34)
										et.G_Sound(killer, et.G_SoundIndex("/sound/etpro/osp_goat.wav"))
										et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(killer, "pers.netname") .. " ^3gibbed for teamkilling " .. name2 .. " ^1" .. tks_warn2 .. " ^3times.\n")
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
end

function et_Print(text)
	if string.find(text, "etpro event:%s+%d+%s+%d+%s+(.*)shoved") then
		if GS == 0 then
			local junk1,junk2,id1,id2 = string.find(text, "etpro event:%s+(%d+)%s+(%d+)%s+(.*)shoved")
			if (et.gentity_get(tonumber(id2), "ps.powerups", 1) + 1000) <= et.trap_Milliseconds() then
				if respawn_time[tonumber(id2)] ~= nil and respawn_time[tonumber(id2)] <= et.trap_Milliseconds() then
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
		if GS == 0 then
			local junk1,junk2,id = string.find(text, "^Ammo_Pack:%s+(%d+)%s+%d+")
			if ammo_given[tonumber(id)] == nil then
				ammo_given[tonumber(id)] = 1
			else
				ammo_given[tonumber(id)] = ammo_given[tonumber(id)] + 1
				local cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(tonumber(id)), "cl_guid")
				if fopkills[cl_guid] == nil then
					fopkills[cl_guid] = 0
				end
				if ammo_given[tonumber(id)] >= al_threshold_1 and ammo_given[tonumber(id)] <= al_threshold_2 then
					if fopkills[cl_guid] < al_minkills_1 then
						ammolamers[tonumber(id)] = true
						et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(tonumber(id), "pers.netname") .. " ^3got his ammo packs confiscated until he gets more kills.\"\n")
						et.gentity_set(tonumber(id), "ps.ammo", 12, 0)
						et.gentity_set(tonumber(id), "ps.ammoclip", 12, 0)
						et.G_LogPrint("LUA event: " .. et.gentity_get(tonumber(id), "pers.netname") .. " got his ammo packs confiscated\n")
					end
				elseif ammo_given[tonumber(id)] >= al_threshold_2 and ammo_given[tonumber(id)] <= al_threshold_3 then
					if fopkills[cl_guid] < al_minkills_2 then
						ammolamers[tonumber(id)] = true
						et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(tonumber(id), "pers.netname") .. " ^3got his ammo packs confiscated until he gets more kills.\"\n")
						et.gentity_set(tonumber(id), "ps.ammo", 12, 0)
						et.gentity_set(tonumber(id), "ps.ammoclip", 12, 0)
						et.G_LogPrint("LUA event: " .. et.gentity_get(tonumber(id), "pers.netname") .. " got his ammo packs confiscated\n")
					end
				elseif ammo_given[tonumber(id)] > al_threshold_3 and ammo_given[tonumber(id)] <= al_threshold_4 then
					if fopkills[cl_guid] < al_minkills_3 then
						ammolamers[tonumber(id)] = true
						et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(tonumber(id), "pers.netname") .. " ^3got his ammo packs confiscated until he gets more kills.\"\n")
						et.gentity_set(tonumber(id), "ps.ammo", 12, 0)
						et.gentity_set(tonumber(id), "ps.ammoclip", 12, 0)
						et.G_LogPrint("LUA event: " .. et.gentity_get(tonumber(id), "pers.netname") .. " got his ammo packs confiscated\n")
					end
				elseif ammo_given[tonumber(id)] > al_threshold_4 then
					if fopkills[cl_guid] < al_minkills_4 then
						ammolamers[tonumber(id)] = true
						et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(tonumber(id), "pers.netname") .. " ^3got his ammo packs confiscated until he gets more kills.\"\n")
						et.gentity_set(tonumber(id), "ps.ammo", 12, 0)
						et.gentity_set(tonumber(id), "ps.ammoclip", 12, 0)
						et.G_LogPrint("LUA event: " .. et.gentity_get(tonumber(id), "pers.netname") .. " got his ammo packs confiscated\n")
					end
				end
			end
		end
	elseif string.find(text, "weapon_magicammo") then
		if GS == 0 then
			local i, j = string.find(text, "%d+")
			local id = tonumber(string.sub(text, i, j))
			if ammolamers[id] == true then
				et.gentity_set(id, "ps.ammo", 12, 0)
				et.gentity_set(id, "ps.ammoclip", 12, 0)
			end
		end
	elseif string.find(text, "Medic_Revive") then
		if GS == 0 then
			local junk1,junk2,medic,zombie = string.find(text, "^Medic_Revive:%s+(%d+)%s+(%d+)")
			if revives[tonumber(medic)] == nil then
				revives[tonumber(medic)] = 1
			else
				revives[tonumber(medic)] = revives[tonumber(medic)] + 1
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
		if playerCount ~= 0 then
			GSFlag = true
		end

		for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
			local team = tonumber(et.gentity_get(j, "sess.sessionTeam"))
			if team == 1 or team == 2 then
				if math.mod(levelTime,checkInterval2) == 0 then
					if et.gentity_get(j,"sess.PlayerType") ~= 1 and et.gentity_get(j,"sess.PlayerType") ~= 4 then
						if et.gentity_get(j, "sess.team_damage") > td_warn then
							et.trap_SendServerCommand(j, "chat \"^1" .. et.gentity_get(j, "sess.team_damage") .. "^3 team damage given! Watch your fire or change class or you might get kicked!\"")
						end
					end
				end
				if et.gentity_get(j, "sess.team_damage") > td_kick then
					et.trap_SendConsoleCommand(et.EXEC_APPEND, "pb_sv_kick "..(j + 1).." 15 \"You made too much team damage, please watch your fire.\" \"You made too much team damage, please watch your fire.\"\n")
					et.G_LogPrint("LUA event: " .. et.gentity_get(j, "pers.netname") .. " kicked for too much team damage (" .. et.gentity_get(j, "sess.team_damage") .. ")\n")
				end
			end
		end
	end
end

function et_ClientSpawn(id, revived)
	if revived ~= 1 then
		if GS == 0 then
			if GSFlag == true then
				local team = et.gentity_get(id, "sess.sessionTeam")
				if team == 1 or team == 2 then

					local health = tonumber(et.gentity_get(id, "health"))
 			      -- sess.kills = 0 should mean this is the first spawn.
  			     if health >= 100 and teamswitch[id] and et.gentity_get(id, "sess.kills") == 0 then
						et.gentity_set(id, "sess.team_damage", team_dmg[id])
						teamswitch[id] = false
			       end

					respawn_time[id] = et.trap_Milliseconds() + 10000

					if et.gentity_get(id,"sess.PlayerType") == 3 then
						if ammolamers[id] == true then
							et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(id, "pers.netname") .. " ^3got his ammo packs confiscated until he gets more kills.\"\n")
							et.gentity_set(id, "ps.ammo", 12, 0)
							et.gentity_set(id, "ps.ammoclip", 12, 0)
						end
						if foplamer[id] == true then
							et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(id, "pers.netname") .. " ^3's binoculars broke from overuse. More kills = new pair.\"\n")
							et.gentity_set(id, "ps.stats", 1, 0)
						end
					end
				end

				if playerCount < 16 then
					if et.gentity_get(id,"sess.PlayerType") == 0 then
						if et.gentity_get(id, "sess.latchPlayerWeapon") == 35 then
							et.gentity_set(id,"sess.latchPlayerType", 1)
							et.gentity_set(id, "ps.powerups", 1, 0)
							et.G_Damage(id, 80, 1022, 1000, 8, 34)
							et.trap_SendServerCommand(-1, "chat \"^3No mortar when less than 16 players!\"")
							et.G_LogPrint("LUA event: No mortar when less than 16 players: " .. playerCount .. " players.\n")
						end
					end
					if playerCount < 12 then
						if et.gentity_get(id,"sess.PlayerType") == 0 then
							if et.gentity_get(id, "sess.latchPlayerWeapon") == 5 then
								et.gentity_set(id,"sess.latchPlayerType", 1)
								et.gentity_set(id, "ps.powerups", 1, 0)
								et.G_Damage(id, 80, 1022, 1000, 8, 34)
								et.trap_SendServerCommand(-1, "chat \"^3No panzerfaust when less than 12 players!\"")
								et.G_LogPrint("LUA event: No panzerfaust when less than 12 players: " .. playerCount .. " players.\n")
							end
						end
						if playerCount < 6 then
							if et.gentity_get(id,"sess.PlayerType") == 2 then
								if et.gentity_get(id,"ps.ammo",39) > 0 or et.gentity_get(id,"ps.ammo",40) > 0 then
									local team = et.gentity_get(id, "sess.sessionTeam")
									if team == 1 then
										et.gentity_set(id,"sess.latchPlayerWeapon", 3)
									elseif team == 2 then
										et.gentity_set(id,"sess.latchPlayerWeapon", 8)
									end
									et.gentity_set(id, "ps.powerups", 1, 0)
									et.G_Damage(id, 80, 1022, 1000, 8, 34)
									et.trap_SendServerCommand(-1, "chat \"^3No riflenades when less than 6 players!\"")
									et.G_LogPrint("LUA event: No riflenades when less than 6 players: " .. playerCount .. " players.\n")
								end
							end
						end
					end
				end
			end
		end
	else
		if et.gentity_get(id,"sess.PlayerType") == 3 then
			if foplamer[id] == true then
				--et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(id, "pers.netname") .. " ^3's binoculars broke from overuse. More kills = new pair.\"\n")
				et.gentity_set(id, "ps.stats", 1, 0)
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
				else
					et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(id, "pers.netname") .. "^3: I wish to register a complaint!\"")
					et.G_globalSound("sound/montypython/complaint.wav")
				end
			else
				et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(id, "pers.netname") .. "^3: I wish to register a complaint!\"")
				et.G_globalSound("sound/montypython/complaint.wav")
			end
		end
	end
	return(0)
end
