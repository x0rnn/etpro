-- idiots.lua by x0rnn, custom troll measures against etadmin level -2 and -3 (idiot) players
-- level -2 players get automuted on connect (they cannot callvote mute/unmute/kick or get callvote unmuted by others, they cannot use /m, /pm either)
-- level -3 players get handicaps such as:
---- weapons taken from them, their skill stays 0, their kills don't count, they end with 69 deaths, health halved, ammo halved
---- they emit a beacon sound to the enemy team, they can't selfkill, they get randomly (10% chance) gibbed or teleported into their death on respawn
---- block them from joining a specific team (axis or allies) (!putaxis by admins still works for example) (can also be set for non -3 level players)
---- block them from playing a specific class (can also be set for non -3 level players)
---- they don't have spawn protection, etc. (can be set unique for each player by guid)
---- invisible mute: their chat will only be visible to them, not knowing other players can't see anything they write (can also be set for non -3 level players) (doesn't seem to work for /m or /pm)
-- also added a !teleport id X Y Z command for level 6+ players to teleport players to input coordinates (/viewpos to see your location)
-- !fakechat id text: send chat in the name of another player
-- !set_lua id entity value1 (value2): set client entity (health, ammo, etc.) to a value
-- prevent 2 players from playing on the same team (go to line 63)

-- modify etadmin_mod/bin/shrub_management.pl line 161 to:
-- if ( !defined($level) || $level < -1000 || !$guid || ( !$name && $level != 0 ) || length($guid) != 32 )
-- you have to symlink /etadmin_mod/etc/shrubbot.cfg to etpro folder

filename = "shrubbot.cfg"
unmute_tries = {}
goons = {}
idiots = {}
idiots2 = {}
idiots_id = {}
random_gib = {} -- disabled by default; random_gib[clientNum] = true in et_ClientBegin function to enable
beacon = {} -- disabled by default
block_team = {} -- disabled by default
block_class = {} -- disabled by default
block_class_flag = false
zero_kills = {} -- disabled by default
invisible_mute = {} -- disabled by default
flag = false
soundindex = ""
mapname = ""
ps_origin = {}
EV_GLOBAL_CLIENT_SOUND = 54
crestrict_id = {}
cflag = false
player1 = {}
player2 = {}
player1_id = {}
player2_id = {}
connect_time = {}

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("idiots.lua "..et.FindSelf())

	soundindex = et.G_SoundIndex("sound/misc/regen.wav")
	mapname = et.trap_Cvar_Get("mapname")

	local fd, len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len > -1 then
		local content = et.trap_FS_Read(fd, len)
		for guid, level in string.gfind(content, "[Gg]uid%s*=%s*(%x+)%s*\n[Ll]evel\t%= %-(%d)") do
			if tonumber(level) == 2 then
				goons[guid] = true
			elseif tonumber(level) == 3 then
				idiots[guid] = true
			end
		end
		content = nil
	end
	et.trap_FS_FCloseFile(fd)
	
	player1[1] = { "bla", nil, nil }
	--player1[2] = { "bla", nil, nil }
	player2[1] = { "bla", nil, nil }
	--player2[2] = { "blabla", nil, nil }
end

function et_ClientBegin(clientNum)
	name = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "name")
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	block_team[clientNum] = { [1]=false, [2]="s" }
	block_class[clientNum] = { [1]=false, [2]=3, [3]=3 }
	invisible_mute[clientNum] = false

	if idiots[cl_guid] == true then
		idiots2[cl_guid] = true
		table.insert(idiots_id, clientNum)
		beacon[clientNum] = false
		zero_kills[clientNum] = false
		random_gib[clientNum] = false
		invisible_mute[clientNum] = false
		flag = true

		---- automute all idiots too? ----
		-- goons[cl_guid] = true

		--------------- set handicaps to an idiot ---------------
		if cl_guid == "bla" then
			-- block_team[clientNum][1] = true
			-- block_team[clientNum][2] = "r" -- r = axis, b = allies
			-- zero_kills[clientNum] = true
			-- random_gib[clientNum] = true
			-- invisible_mute[clientNum] = true
			-- beacon[clientNum] = true

			block_class[clientNum][1] = true
			block_class[clientNum][2] = 3 -- 0 = soldier, 1 = medic, 2 = engineer, 3 = fieldops, 4 = covertops
			block_class[clientNum][3] = 3 -- second class to block. Set to same as above if only 1 class is restricted for this idiot
			block_class_flag = false -- set this to false if no class blocks, otherwise set to true
			
			---- mute this specific idiot too? ----
			-- goons[cl_guid] = true
		end
	end

	if goons[cl_guid] == true then
		et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^1automuted for being a Goon.\"\n")
		et.G_LogPrint("LUA event: " .. name .. " automuted for being a Goon.\n")
		et.gentity_set(clientNum, "sess.muted", 1)
	end

	----- block a team/class or invisibly mute someone who is not -3 -----

	-- class blocking players who aren't -3:
	if cl_guid == "bla" then
		table.insert(crestrict_id, clientNum)
		cflag = true
		block_class[clientNum][1] = true
		block_class[clientNum][2] = 3 -- 0 = soldier, 1 = medic, 2 = engineer, 3 = fieldops, 4 = covertops
		block_class[clientNum][3] = 3 -- second class to block. Set to same as above if only 1 class is restricted for this idiot
	end

	-- team blocking players who aren't -3:
	if cl_guid == "bla" then
		--block_team[clientNum] = { [1]=true, [2]="r" }
	end

	-- invisimuting players who aren't -3:
	if cl_guid == "bla" or cl_guid == "bla2" or cl_guid == "bla3" then
		invisible_mute[clientNum] = true
	end
end

function et_ClientConnect(clientNum, firstTime, isBot)
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")

	connect_time[clientNum] = et.trap_Milliseconds()
	for i=1, table.getn(player1) do
		if player1[i][1] == cl_guid then
			player1[i][2] = clientNum
			player1_id[clientNum] = i
		elseif player2[i][1] == cl_guid then
			player2[i][2] = clientNum
			player2_id[clientNum] = i
		end
	end
end

function et_ClientUserinfoChanged(clientNum)
	local team = tonumber(et.gentity_get(clientNum, "sess.sessionTeam"))

	if player1_id[clientNum] ~= nil or player2_id[clientNum] ~= nil then
		if player1_id[clientNum] ~= nil then
			if team == 3 then
				player1[player1_id[clientNum]][3] = nil
			elseif team == 1 or team == 2 then
				if player1[player1_id[clientNum]][3] == nil or player1[player1_id[clientNum]][3] ~= team then
					if player2[player1_id[clientNum]][2] ~= nil then
						if player2[player1_id[clientNum]][3] == team then
							et.trap_SendServerCommand(-1, "cpm \"" .. et.gentity_get(clientNum, "pers.netname") .. " ^3can't play on the same team as " .. et.gentity_get(player2[player1_id[clientNum]][2], "pers.netname") .. "\n\"")
							et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref remove " .. clientNum .. "\n")
							et.G_LogPrint("LUA event: " .. et.gentity_get(clientNum, "pers.netname") .. " can't play on the same team as " .. et.gentity_get(player2[player1_id[clientNum]][2], "pers.netname") .. "\n")
						else
							player1[player1_id[clientNum]][3] = team
						end
					else
						player1[player1_id[clientNum]][3] = team
					end
				end
			end
		elseif player2_id[clientNum] ~= nil then
			if team == 3 then
				player2[player2_id[clientNum]][3] = nil
			elseif team == 1 or team == 2 then
				if player2[player2_id[clientNum]][3] == nil or player2[player2_id[clientNum]][3] ~= team then
					if player1[player2_id[clientNum]][2] ~= nil then
						if player1[player2_id[clientNum]][3] == team then
							et.trap_SendServerCommand(-1, "cpm \"" .. et.gentity_get(clientNum, "pers.netname") .. " ^3can't play on the same team as " .. et.gentity_get(player1[player2_id[clientNum]][2], "pers.netname") .. "\n\"")
							et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref remove " .. clientNum .. "\n")
							et.G_LogPrint("LUA event: " .. et.gentity_get(clientNum, "pers.netname") .. " can't play on the same team as " .. et.gentity_get(player1[player2_id[clientNum]][2], "pers.netname") .. "\n")
						else
							player2[player2_id[clientNum]][3] = team
						end
					else
						player2[player2_id[clientNum]][3] = team
					end
				end
			end
		end
	end
end

function et_ClientDisconnect(clientNum)
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	if idiots2[cl_guid] == true then
		idiots2[cl_guid] = nil
		beacon[clientNum] = nil
		random_gib[clientNum] = nil
		block_team[clientNum] = nil
		block_class[clientNum] = nil
		invisible_mute[clientNum] = nil
		zero_kills[clientNum] = nil
		block_class_flag = false
		local index={}
		for k,v in pairs(idiots_id) do
			index[v]=k
		end
		table.remove(idiots_id, index[clientNum])
		if next(idiots2) == nil then
			flag = false
		end
	end
	if block_team[clientNum] ~= nil then
		block_team[clientNum] = nil
	end
	if invisible_mute[clientNum] ~= nil then
		invisible_mute[clientNum] = nil
	end
	local index={}
	for k,v in pairs(crestrict_id) do
		index[v]=k
	end
	if crestrict_id[index[clientNum]] ~= nil then
		table.remove(crestrict_id, index[clientNum])
	end

	if player1_id[clientNum] ~= nil then
		player1[player1_id[clientNum]][2] = nil
		player1[player1_id[clientNum]][3] = nil
		player1_id[clientNum] = nil
	end
	if player2_id[clientNum] ~= nil then
		player2[player2_id[clientNum]][2] = nil
		player2[player2_id[clientNum]][3] = nil
		player2_id[clientNum] = nil
	end
	connect_time[clientNum] = nil
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

function et_ClientSpawn(clientNum, revived)
	if flag == true then
		cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
		if idiots2[cl_guid] == true then
			if revived ~= 1 then
				local team = et.gentity_get(clientNum, "sess.sessionTeam")
				if team == 1 or team == 2 then
					math.randomseed(et.trap_Milliseconds())
					name = et.gentity_get(clientNum, "pers.netname")
					weapon = et.gentity_get(clientNum, "sess.playerWeapon")
					weapon2 = et.gentity_get(clientNum, "sess.playerWeapon2")
					ammo = et.gentity_get(clientNum, "ps.ammo", weapon)
					ammoclip = et.gentity_get(clientNum, "ps.ammoclip", weapon)
					ammo2 = et.gentity_get(clientNum, "ps.ammo", weapon2)
					ammoclip2 = et.gentity_get(clientNum, "ps.ammoclip", weapon2)
					if block_class_flag == false and block_class[clientNum][1] == true then
						block_class_flag = true
					end
					-- if taking away weapons, do not forget to also remove them in et_Print function

					----- handicaps that need to be reset each respawn: -----
					if cl_guid == "bla" then
						et.gentity_set(clientNum,"ps.ammo",12,0) -- ammo boxes; see noweapon.lua (google) for weapon indexes
						et.gentity_set(clientNum,"ps.ammoclip",12,0)
						et.gentity_set(clientNum, "sess.skill", 3, 0) -- field ops
					elseif cl_guid == "bla" then
						if zero_kills[clientNum] == true then
							et.gentity_set(clientNum, "sess.kills", 0)
							et.gentity_set(clientNum, "sess.deaths", 69)
						end
						et.gentity_set(clientNum, "ps.stats", 4, 69) -- max_health
						et.gentity_set(clientNum, "health", 69)
						et.gentity_set(clientNum, "sess.skill", 0, 0) -- battle sense
						et.gentity_set(clientNum, "sess.skill", 1, 0) -- engineer
						et.gentity_set(clientNum, "sess.skill", 2, 0) -- medic
						et.gentity_set(clientNum, "sess.skill", 3, 0) -- field ops
						et.gentity_set(clientNum, "sess.skill", 4, 0) -- light weapons
						et.gentity_set(clientNum, "sess.skill", 5, 0) -- heavy weapons
						et.gentity_set(clientNum, "sess.skill", 6, 0) -- covert ops
						et.gentity_set(clientNum, "ps.ammo", weapon, 0)
						et.gentity_set(clientNum, "ps.ammoclip", weapon, ammoclip/2)
						et.gentity_set(clientNum, "ps.ammo", weapon2, 0)
						et.gentity_set(clientNum, "ps.ammoclip", weapon2, ammoclip2/2)
						et.gentity_set(clientNum, "ps.powerups", 1, 0) -- no spawn protection
					end
	
					if random_gib[clientNum] == true then
						et.gentity_set(clientNum, "ps.powerups", 1, 0)
						local choice = math.random(1, 100)
						if choice <= 10 then
							local choice2 = math.random(1, 2)
							if choice2 == 1 then
								msg = string.format("chat  \"" .. name .. " ^3randomly gibbed for being an idiot.\n")
								et.trap_SendServerCommand(-1, msg)
								et.G_Damage(clientNum, 80, 1022, 1000, 8, 34)
								et.G_Sound(clientNum, et.G_SoundIndex("/sound/etpro/osp_goat.wav"))
							elseif choice2 == 2 then
								if mapname == "goldrush" then
									et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
									et.gentity_set(clientNum, "ps.ammo", weapon, 0)
									ps_origin = { [1]=3698, [2]=1623, [3]=666 }
									et.gentity_set(clientNum, "ps.origin", ps_origin)
									msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
									et.trap_SendServerCommand(-1, msg)
								elseif mapname == "sw_battery" or mapname == "battery" then
									et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
									et.gentity_set(clientNum, "ps.ammo", weapon, 0)
									ps_origin = { [1]=10164, [2]=-3063, [3]=3687 }
									et.gentity_set(clientNum, "ps.origin", ps_origin)
									msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
									et.trap_SendServerCommand(-1, msg)
								elseif mapname == "railgun" then
									et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
									et.gentity_set(clientNum, "ps.ammo", weapon, 0)
									ps_origin = { [1]=4538, [2]=5661, [3]=2561 }
									et.gentity_set(clientNum, "ps.origin", ps_origin)
									msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
									et.trap_SendServerCommand(-1, msg)
								elseif mapname == "radar" then
									et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
									et.gentity_set(clientNum, "ps.ammo", weapon, 0)
									ps_origin = { [1]=1135, [2]=6091, [3]=1835 }
									et.gentity_set(clientNum, "ps.origin", ps_origin)
									msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
									et.trap_SendServerCommand(-1, msg)
								elseif mapname == "fueldump" then
									et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
									et.gentity_set(clientNum, "ps.ammo", weapon, 0)
									ps_origin = { [1]=-13725, [2]=-2391, [3]=3103 }
									et.gentity_set(clientNum, "ps.origin", ps_origin)
									msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
									et.trap_SendServerCommand(-1, msg)
								elseif mapname == "oasis" then
									et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
									et.gentity_set(clientNum, "ps.ammo", weapon, 0)
									ps_origin = { [1]=12251, [2]=4353, [3]=1552 }
									et.gentity_set(clientNum, "ps.origin", ps_origin)
									msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
									et.trap_SendServerCommand(-1, msg)
								elseif mapname == "frostbite" then
									et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
									et.gentity_set(clientNum, "ps.ammo", weapon, 0)
									ps_origin = { [1]=-975, [2]=1411, [3]=2050 }
									et.gentity_set(clientNum, "ps.origin", ps_origin)
									msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
									et.trap_SendServerCommand(-1, msg)
								elseif mapname == "pirates" then
									et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
									et.gentity_set(clientNum, "ps.ammo", weapon, 0)
									ps_origin = { [1]=1593, [2]=6696, [3]=4118 }
									et.gentity_set(clientNum, "ps.origin", ps_origin)
									msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
									et.trap_SendServerCommand(-1, msg)
								elseif mapname == "venice" then
									et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
									et.gentity_set(clientNum, "ps.ammo", weapon, 0)
									ps_origin = { [1]=-2246, [2]=796, [3]=2049 }
									et.gentity_set(clientNum, "ps.origin", ps_origin)
									msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
									et.trap_SendServerCommand(-1, msg)
								elseif mapname == "missile_b3" then
									et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
									et.gentity_set(clientNum, "ps.ammo", weapon, 0)
									ps_origin = { [1]=4755, [2]=-2441, [3]=2292 }
									et.gentity_set(clientNum, "ps.origin", ps_origin)
									msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
									et.trap_SendServerCommand(-1, msg)
								elseif mapname == "eagles_2ways_b3" then
									et.gentity_set(clientNum, "ps.ammoclip", weapon, 0)
									et.gentity_set(clientNum, "ps.ammo", weapon, 0)
									ps_origin = { [1]=3535, [2]=2265, [3]=2688 }
									et.gentity_set(clientNum, "ps.origin", ps_origin)
									msg = string.format("chat  \"" .. name .. " ^3randomly teleported into another dimension for being an idiot.\n")
									et.trap_SendServerCommand(-1, msg)
								end
							end
						end
					end
				end
			end
		end
	end
end

function et_Obituary(victim, killer, mod)
	gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
	if gamestate == 0 then
		if killer ~= 1022 and killer ~= 1023 then -- no world / unknown kills
			cl_guid_k = et.Info_ValueForKey(et.trap_GetUserinfo(killer), "cl_guid")
			cl_guid_v = et.Info_ValueForKey(et.trap_GetUserinfo(victim), "cl_guid")
			if idiots2[cl_guid_k] == true then
				if zero_kills[killer] == true then
					local v_teamid = et.gentity_get(victim, "sess.sessionTeam")
					local k_teamid = et.gentity_get(killer, "sess.sessionTeam")
					local v_deaths = tonumber(et.gentity_get(victim, "sess.deaths"))

					if v_teamid ~= k_teamid then
						et.gentity_set(killer, "sess.kills", 0)
						et.gentity_set(victim, "sess.deaths", v_deaths - 1)
					end
				end
			elseif idiots2[cl_guid_v] == true then
				if zero_kills[victim] == true then
					et.gentity_set(victim, "sess.deaths", 69)
				end
			end
		end
	end
end

function et_Print(text)
	if flag == true then
		if string.find(text, "weapon_magicammo") then
			gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
			if gamestate == 0 then
				local i, j = string.find(text, "%d+")
				local id = tonumber(string.sub(text, i, j))
				local cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(id), "cl_guid")
				if idiots2[cl_guid] == true then
					if cl_guid == "bla" then
						et.gentity_set(id,"ps.ammo",12,0)
						et.gentity_set(id,"ps.ammoclip",12,0)
					end
				end
			end
		end
	end
end

function et_RunFrame(levelTime)
	if math.mod(levelTime, 1500) ~= 0 then return end
	gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
	if gamestate == 0 then
		if flag == true then
			if block_class_flag == true then
				local x = 1
				for index in pairs(idiots_id) do
					if block_class[idiots_id[x]][1] == true then
						if et.gentity_get(idiots_id[x],"sess.latchPlayerType") == block_class[idiots_id[x]][2] or et.gentity_get(idiots_id[x],"sess.latchPlayerType") == block_class[idiots_id[x]][3] then
							et.gentity_set(idiots_id[x],"sess.latchPlayerType", 1)
							et.trap_SendServerCommand(idiots_id[x], "cpm \"^1You are not allowed to play that class.\n\"")
						end
						if et.gentity_get(idiots_id[x],"sess.PlayerType") == block_class[idiots_id[x]][2] or et.gentity_get(idiots_id[x],"sess.PlayerType") == block_class[idiots_id[x]][3] then
							local health = tonumber(et.gentity_get(idiots_id[x], "health"))
							if health > 0 then
								et.gentity_set(idiots_id[x], "ps.powerups", 1, 0)
								et.G_Damage(idiots_id[x], 80, 1022, 1000, 8, 34)
								et.G_Sound(idiots_id[x], et.G_SoundIndex("/sound/etpro/osp_goat.wav"))
							end
						end
					end
					x = x + 1
				end
			end

			local i = 1
			for index in pairs(idiots_id) do
				if beacon[idiots_id[i]] == true then
					idiot_team = tonumber(et.gentity_get(idiots_id[i], "sess.sessionTeam"))
					if idiot_team == 1 or idiot_team == 2 then
						for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
							opponent_team = tonumber(et.gentity_get(j, "sess.sessionTeam"))
							if opponent_team ~= 0 and opponent_team ~= 3 and opponent_team ~= idiot_team then
								local health = tonumber(et.gentity_get(idiots_id[i], "health"))
								if health > 0 then
									tempentity = et.G_TempEntity(et.gentity_get(idiots_id[1], "r.currentOrigin"), EV_GLOBAL_CLIENT_SOUND)
									et.gentity_set(tempentity, "s.teamNum", j)
									et.gentity_set(tempentity, "s.eventParm", soundindex)
								end
							end
						end
					end
				end
				i = i + 1
			end
		end

		if cflag == true then
			local x = 1
			for index in pairs(crestrict_id) do
				if block_class[crestrict_id[x]][1] == true then
					if et.gentity_get(crestrict_id[x],"sess.latchPlayerType") == block_class[crestrict_id[x]][2] or et.gentity_get(crestrict_id[x],"sess.latchPlayerType") == block_class[crestrict_id[x]][3] then
						et.gentity_set(crestrict_id[x],"sess.latchPlayerType", 1)
						et.trap_SendServerCommand(crestrict_id[x], "cpm \"^1You are not allowed to play that class.\n\"")
					end
					if et.gentity_get(crestrict_id[x],"sess.PlayerType") == block_class[crestrict_id[x]][2] or et.gentity_get(crestrict_id[x],"sess.PlayerType") == block_class[crestrict_id[x]][3] then
						local health = tonumber(et.gentity_get(crestrict_id[x], "health"))
						if health > 0 then
							et.gentity_set(crestrict_id[x], "ps.powerups", 1, 0)
							et.G_Damage(crestrict_id[x], 80, 1022, 1000, 8, 34)
							et.G_Sound(crestrict_id[x], et.G_SoundIndex("/sound/etpro/osp_goat.wav"))
						end
					end
				end
				x = x + 1
			end
		end
	end
end

function inSlot( PartName )
  local x=0
  local j=1
  local size=tonumber(et.trap_Cvar_Get("sv_maxclients"))     --get the serversize
  local matches = {}
  while (x<size) do
    found = string.find(string.lower(et.Q_CleanStr( et.Info_ValueForKey( et.trap_GetUserinfo( x ), "name" ) )),string.lower(PartName))
    if(found~=nil) then
        matches[j]=x
        j=j+1
    end
    x=x+1
  end
  if (table.getn(matches)~=nil) then
    x=1
    while (x<=table.getn(matches)) do
        matchingSlot = matches[x] 
      x=x+1
    end
    if table.getn(matches) == 0 then
      et.G_Print("You had no matches to that name.\n")
      matchingSlot = nil
    else
      if table.getn(matches) >= 2 then
        et.G_Print("Partial playername got more than 1 match\n")
        matchingSlot = nil
      end
    end
  end
  return matchingSlot
end

function et_ClientCommand(id, cmd)
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(id), "cl_guid")
	if cl_guid == "bla" and string.lower(cmd) == "callvote" then
		if string.lower(et.trap_Argv(1)) == "kick" or string.lower(et.trap_Argv(1)) == "mute" then
			et.trap_SendServerCommand(id, "cpm \"^1This command is not available to you.\n\"")
			return 1
		end
	end
	if goons[cl_guid] == true then
		if string.lower(cmd) == "m" or string.lower(cmd) == "pm" or string.lower(cmd) == "msg" then
			et.trap_SendServerCommand(id, "cpm \"^1You are muted. This command is not available to you.\n\"")
			return 1
		elseif string.lower(cmd) == "callvote" then
			if string.lower(et.trap_Argv(1)) == "kick" or string.lower(et.trap_Argv(1)) == "mute" then
				et.trap_SendServerCommand(id, "cpm \"^1This command is not available to you.\n\"")
				return 1
			elseif string.lower(et.trap_Argv(1)) == "unmute" then
				local client = findClient(et.trap_Argv(2))
				if client ~= nil and id == client.slot then
					if unmute_tries[cl_guid] == nil then
						unmute_tries[cl_guid] = 1
					else
						unmute_tries[cl_guid] = unmute_tries[cl_guid] + 1
					end
					if unmute_tries[cl_guid] <= 3 then
						msg = string.format("cpm  \"" .. client.name .. "^3 got bummed for trying to unmute himself. What a peon.\n")
						et.trap_SendServerCommand(-1, msg)
						et.trap_SendServerCommand(id, "cpm \"^1If you learnt your lesson, come to the forum or www.hirntot.org/discord and ask in a nice way to get unmuted.\n\"")
						et.gentity_set(id, "ps.powerups", 1, 0)
						et.G_Damage(id, 80, 1022, 1000, 8, 34)
						soundindex = et.G_SoundIndex("/sound/etpro/osp_goat.wav")
						et.G_Sound(id, soundindex)
						if unmute_tries[cl_guid] == 3 then
							et.trap_SendServerCommand(id, "cpm \"^1You cannot unmute yourself. Next time you try, you will get kicked.\n\"")
						end
						return 1
					else
						et.trap_DropClient(id, "You cannot unmute yourself, stop trying.", 900) --15 minutes
					end
				end
			end
		end
	elseif idiots2[cl_guid] == true then
		if string.lower(cmd) == "kill" then
			et.trap_SendServerCommand(id, "cpm \"^1You are an idiot. This command is not available to you.\n\"")
			return 1
		elseif string.lower(cmd) == "callvote" then
			if string.lower(et.trap_Argv(1)) == "kick" or string.lower(et.trap_Argv(1)) == "mute" then
				et.trap_SendServerCommand(id, "cpm \"^1This command is not available to you.\n\"")
				return 1
			end
		elseif string.lower(cmd) == "team" then
			if block_team[id][1] == true then
				local team = string.lower(et.trap_Argv(1))
				if team == block_team[id][2] then
					et.trap_SendServerCommand(id, "cpm \"^1You are not allowed to join that team.\n\"")
					return 1
				end
			end
		end
		if invisible_mute[id] == true then
			if string.lower(cmd) == "say" or string.lower(cmd) == "say_team" or string.lower(cmd) == "say_teamnl" or string.lower(cmd) == "say_buddy" or string.lower(cmd) == "m" or string.lower(cmd) == "pm" or string.lower(cmd) == "msg" then
				if string.lower(cmd) == "say" then
					et.trap_SendServerCommand(id, "chat \"" .. et.gentity_get(id, "pers.netname") .. "^7: ^2" .. et.ConcatArgs(1) .. "\"")
					et.G_LogPrint("say: " .. et.gentity_get(id, "pers.netname") .. ": " .. et.ConcatArgs(1) .. " (InvisiMute)\n")
					return 1
				elseif string.lower(cmd) == "say_team" or string.lower(cmd) == "say_teamnl" then
					et.trap_SendServerCommand(id, "chat \"" .. et.gentity_get(id, "pers.netname") .. "^7: ^5" .. et.ConcatArgs(1) .. "\"")
					et.G_LogPrint("sayteam: " .. et.gentity_get(id, "pers.netname") .. ": " .. et.ConcatArgs(1) .. " (InvisiMute)\n")
					return 1
				elseif string.lower(cmd) == "say_buddy" then
					et.trap_SendServerCommand(id, "chat \"" .. et.gentity_get(id, "pers.netname") .. "^7: ^3" .. et.ConcatArgs(1) .. "\"")
					et.G_LogPrint("saybuddy: " .. et.gentity_get(id, "pers.netname") .. ": " .. et.ConcatArgs(1) .. " (InvisiMute)\n")
					return 1
				elseif string.lower(cmd) == "m" or string.lower(cmd) == "pm" or string.lower(cmd) == "msg" then
					et.trap_SendServerCommand(id, "chat \"" .. et.gentity_get(id, "pers.netname") .. "^7: ^1(private to '" .. et.trap_Argv(1) .. "^1')^7" .. et.ConcatArgs(2) .. "\"")
					et.G_LogPrint("etpro privmsg: " .. et.gentity_get(id, "pers.netname") .. " to " .. et.trap_Argv(1) .. ": InvisiMute: " .. et.ConcatArgs(2) .. "\n")
					return 1
				end
			end
		end
	else
		if string.lower(cmd) == "callvote" then
			if string.lower(et.trap_Argv(1)) == "unmute" then
				local client = findClient(et.trap_Argv(2))
				if client ~= nil and goons[client.guid] == true then
					et.trap_SendServerCommand(-1, "chat \"You can't unmute " .. et.Q_CleanStr(client.name) .. ".\"\n")
					return 1
				end
			elseif string.lower(et.trap_Argv(1)) == "kick" then
				local client = findClient(et.trap_Argv(2))
				if client ~= nil and tonumber(et.gentity_get(client.slot, "sess.sessionTeam")) == 3 then
					if et.trap_Milliseconds() - connect_time[client.slot] < 120000 then -- 2 minutes
						et.trap_SendServerCommand(-1, "chat \"You can't kick " .. et.Q_CleanStr(client.name) .. " so fast.\"\n")
						return 1
					end
				end
			end
		end
		if (block_team[id] ~= nil and block_team[id][1] == true) or (invisible_mute[id] ~= nil and invisible_mute[id] == true) then
			if string.lower(cmd) == "team" then
				if block_team[id][1] == true then
					local team = string.lower(et.trap_Argv(1))
					if team == block_team[id][2] then
						et.trap_SendServerCommand(id, "cpm \"^1You are not allowed to join that team.\n\"")
						return 1
					end
				end
			end
			if invisible_mute[id] == true then
				if string.lower(cmd) == "say" or string.lower(cmd) == "say_team" or string.lower(cmd) == "say_teamnl" or string.lower(cmd) == "say_buddy" or string.lower(cmd) == "m" or string.lower(cmd) == "pm" or string.lower(cmd) == "msg" then
					if string.lower(cmd) == "say" then
						et.trap_SendServerCommand(id, "chat \"" .. et.gentity_get(id, "pers.netname") .. "^7: ^2" .. et.ConcatArgs(1) .. "\"")
						et.G_LogPrint("say: " .. et.gentity_get(id, "pers.netname") .. ": " .. et.ConcatArgs(1) .. " (InvisiMute)\n")
						return 1
					elseif string.lower(cmd) == "say_team" or string.lower(cmd) == "say_teamnl" then
						et.trap_SendServerCommand(id, "chat \"" .. et.gentity_get(id, "pers.netname") .. "^7: ^5" .. et.ConcatArgs(1) .. "\"")
						et.G_LogPrint("sayteam: " .. et.gentity_get(id, "pers.netname") .. ": " .. et.ConcatArgs(1) .. " (InvisiMute)\n")
						return 1
					elseif string.lower(cmd) == "say_buddy" then
						et.trap_SendServerCommand(id, "chat \"" .. et.gentity_get(id, "pers.netname") .. "^7: ^3" .. et.ConcatArgs(1) .. "\"")
						et.G_LogPrint("saybuddy: " .. et.gentity_get(id, "pers.netname") .. ": " .. et.ConcatArgs(1) .. " (InvisiMute)\n")
						return 1
					elseif string.lower(cmd) == "m" or string.lower(cmd) == "pm" or string.lower(cmd) == "msg" then
						et.trap_SendServerCommand(id, "chat \"" .. et.gentity_get(id, "pers.netname") .. "^7: ^1(private to '" .. et.trap_Argv(1) .. "^1')^7" .. et.ConcatArgs(2) .. "\"")
						et.G_LogPrint("etpro privmsg: " .. et.gentity_get(id, "pers.netname") .. " to " .. et.trap_Argv(1) .. ": InvisiMute: " .. et.ConcatArgs(2) .. "\n")
						return 1
					end
				end
			end
		end
		if player1_id[id] ~= nil or player2_id[id] ~= nil then
			if string.lower(cmd) == "team" then
				local team = string.lower(et.trap_Argv(1))
				if team == "r" then
					team = 1
				end
				if team == "b" then
					team = 2
				end
				if team == 1 or team == 2 then
					if player1_id[id] ~= nil then
						if player2[player1_id[id]][2] ~= nil then
							if player2[player1_id[id]][3] == team then
								et.trap_SendServerCommand(-1, "cpm \"" .. et.gentity_get(id, "pers.netname") .. " ^3can't play on the same team as " .. et.gentity_get(player2[player1_id[id]][2], "pers.netname") .. "\n\"")
								et.G_LogPrint("LUA event: " .. et.gentity_get(id, "pers.netname") .. " can't play on the same team as " .. et.gentity_get(player2[player1_id[id]][2], "pers.netname") .. "\n")
								return 1
							end
						end
					elseif player2_id[id] ~= nil then
						if player1[player2_id[id]][2] ~= nil then
							if player1[player2_id[id]][3] == team then
								et.trap_SendServerCommand(-1, "cpm \"" .. et.gentity_get(id, "pers.netname") .. " ^3can't play on the same team as " .. et.gentity_get(player1[player2_id[id]][2], "pers.netname") .. "\n\"")
								et.G_LogPrint("LUA event: " .. et.gentity_get(id, "pers.netname") .. " can't play on the same team as " .. et.gentity_get(player1[player2_id[id]][2], "pers.netname") .. "\n")
								return 1
							end
						end
					end
				end
			end
		end
	end

	flag2 = false
	admin_flag = false
	if et.trap_Argv(0) == "say" then
			args = et.ConcatArgs(1)
			local args_table = {}
			cnt = 0
			for i in string.gfind(args, "%S+") do
				table.insert(args_table, i)
				cnt = cnt + 1
			end
			local function Util_Concat(tab, seperator)
				if seperator == nil then return table.concat(tab) end
				local buffer = {}
				for i, v in ipairs(tab) do
					buffer[table.getn(buffer) + 1] = v
					if i < table.getn(tab) then
						buffer[table.getn(buffer) + 1] = seperator
					end
				end
				return table.concat(buffer)
			end
			if args_table[1] == "!teleport" then
				fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
				if len ~= -1 then
					filestr = et.trap_FS_Read(fd, len)
					et.trap_FS_FCloseFile(fd)
					for v in string.gfind(filestr, cl_guid .. "\nlevel\t%= ([^\n]+)") do
						if tonumber(v) >= 7 then -- level 7+
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
					if cnt ~= 5 then
						et.trap_SendServerCommand(id, "chat \"Usage: ^7!teleport ^3PartOfName X Y Z ^7(/viewpos to see your location)\"\n")
					else
						if string.len(args_table[2]) < 3 then
							cno = tonumber(args_table[2])
							if cno then
								if et.gentity_get(cno, "pers.connected") == 2 then
									if et.gentity_get(cno, "sess.sessionTeam") == 1 or et.gentity_get(cno, "sess.sessionTeam") == 2 then
										if tonumber(et.gentity_get(cno, "health")) > 0 then
											if tonumber(args_table[3]) and tonumber(args_table[4]) and tonumber(args_table[5]) then
												flag2 = true
											else
												et.trap_SendServerCommand (id, "chat \"Usage: ^7!teleport ^3id X Y Z ^7(/viewpos to see your location)\"\n")
											end
										else
											et.trap_SendServerCommand (id, "chat \"^7Target is not alive.\"\n")
										end
									else
										et.trap_SendServerCommand(id, "chat \"^7Target is not in Axis or Allied team.\"\n")
									end
								else
									et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
								end
							else
								et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
							end
						else
							cno = inSlot(args_table[2])
							if cno ~= nil then
								if et.gentity_get(cno, "sess.sessionTeam") == 1 or et.gentity_get(cno, "sess.sessionTeam") == 2 then
									if tonumber(et.gentity_get(cno, "health")) > 0 then
										if tonumber(args_table[3]) and tonumber(args_table[4]) and tonumber(args_table[5]) then
											flag2 = true
										else
											et.trap_SendServerCommand (id, "chat \"Usage: ^7!teleport ^3id X Y Z ^7(/viewpos to see your location)\"\n")
										end
									else
										et.trap_SendServerCommand (id, "chat \"^7Target is not alive.\"\n")
									end
								else
									et.trap_SendServerCommand(id, "chat \"^7Target is not in Axis or Allied team.\"\n")
								end
							else
								et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
							end
						end
					end
				else
					et.trap_SendServerCommand(id, "chat \"^7This command is not available to you.\"\n")
				end
			elseif args_table[1] == "!fakechat" then
				fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
				if len ~= -1 then
					filestr = et.trap_FS_Read(fd, len)
					et.trap_FS_FCloseFile(fd)
					for v in string.gfind(filestr, cl_guid .. "\nlevel\t%= ([^\n]+)") do
						if tonumber(v) >= 7 then -- level 7+
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
					if cnt < 3 then
						et.trap_SendServerCommand(id, "chat \"Usage: ^7!fakechat ^3PartOfName text ^3(IN CONSOLE!)\"\n")
					else
						local temp = args_table
						local temp2 = args_table[2]
						table.remove(temp, 1)
						table.remove(temp, 1)
						if string.len(temp2) < 3 then
							cno = tonumber(temp2)
							if cno then
								if et.gentity_get(cno, "pers.connected") == 2 then
									et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(cno, "pers.netname") .. "^7: ^2" .. Util_Concat(temp, " ") .. "\"")
									et.G_LogPrint("say: (FakeChat): " .. et.gentity_get(id, "pers.netname") .. ": " .. et.gentity_get(cno, "pers.netname") .. ": " .. Util_Concat(temp, " ") .. "\n")
								else
									et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
								end
							else
								et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
							end
						else
							cno = inSlot(temp2)
							if cno ~= nil then
								et.trap_SendServerCommand(-1, "chat \"" .. et.gentity_get(cno, "pers.netname") .. "^7: ^2" .. Util_Concat(temp, " ") .. "\"")
								et.G_LogPrint("say: (FakeChat): " .. et.gentity_get(id, "pers.netname") .. ": " .. et.gentity_get(cno, "pers.netname") .. ": " .. Util_Concat(temp, " ") .. "\n")
							else
								et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
							end
						end
					end
					return 1
				else
					et.trap_SendServerCommand(id, "chat \"^7This command is not available to you.\"\n")
				end
			elseif args_table[1] == "!set_lua" then
				fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
				if len ~= -1 then
					filestr = et.trap_FS_Read(fd, len)
					et.trap_FS_FCloseFile(fd)
					for v in string.gfind(filestr, cl_guid .. "\nlevel\t%= ([^\n]+)") do
						if tonumber(v) >= 8 then
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
					if cnt < 4 or cnt > 5 then
						et.trap_SendServerCommand(id, "chat \"Usage: ^7!set_lua ^3id entity value (value2)\"\n")
					else
						cno = tonumber(args_table[2])
						if cno then
							if et.gentity_get(cno, "pers.connected") == 2 then
								if cnt == 4 then
									val = tonumber(args_table[4])
									if val then
										et.gentity_set(cno, args_table[3], val)
									else
										et.trap_SendServerCommand(id, "chat \"^7Not a number.\"\n")
									end
								elseif cnt == 5 then
									val1 = tonumber(args_table[4])
									if val1 then
										val2 = tonumber(args_table[5])
										if val2 then
											et.gentity_set(cno, args_table[3], val1, val2)
										else
											et.trap_SendServerCommand(id, "chat \"^7Not a number.\"\n")
										end
									else
										et.trap_SendServerCommand(id, "chat \"^7Not a number.\"\n")
									end
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

			if flag2 == true then
				ps_origin = { [1]=tonumber(args_table[3]),  [2]=tonumber(args_table[4]), [3]=tonumber(args_table[5]) }
				et.gentity_set(cno, "ps.origin", ps_origin)
				msg = string.format("chat  \"" ..  et.gentity_get(cno, "pers.netname") .. " ^3got teleported.")
				et.trap_SendServerCommand(-1, msg)
				et.G_LogPrint("LUA event: " .. et.gentity_get(cno, "pers.netname") .. " got teleported by " .. et.gentity_get(id, "pers.netname") .. ".\n")
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