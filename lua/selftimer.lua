-- selftimer.lua by x0rnn, notifies you with sound last 3 seconds before your next respawn so you can selfkill in time
-- commands: !timer during match to activate it, !untimer to turn it off

EV_GLOBAL_CLIENT_SOUND = 54
redspawn = 0
bluespawn = 0
players = {}
spawns = {}
redflag = false
blueflag = false
redlimbo1 = 0
bluelimbo1 = 0
redlimbo2 = 0
bluelimbo2 = 0
changedred = false
changedblue = false
alertflag = false
alerted = {}
alerted_id = {}
sound = "sound/player/hurt_barbwire.wav"

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("selftimer.lua "..et.FindSelf())

	maxClients = tonumber(et.trap_Cvar_Get("sv_maxclients"))
	for i=0,maxClients-1 do
		players[i] = nil
		spawns[i] = nil
	end
end

function et.G_ClientSound(id, soundfile)
	local tempentity = et.G_TempEntity(et.gentity_get(id, "r.currentOrigin"), EV_GLOBAL_CLIENT_SOUND)
	et.gentity_set(tempentity, "s.teamNum", id)
	et.gentity_set(tempentity, "s.eventParm", et.G_SoundIndex(soundfile))
end

function et_RunFrame(levelTime)
	if math.mod(levelTime, 1000) ~= 0 then return end

	local gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
	if gamestate == 0 then
		redlimbo1 = tonumber(et.trap_Cvar_Get("g_redlimbotime"))
		bluelimbo1 = tonumber(et.trap_Cvar_Get("g_bluelimbotime"))
		if redlimbo2 == 0 then
			redlimbo2 = redlimbo1
			bluelimbo2 = bluelimbo1
		end
		if redlimbo1 ~= redlimbo2 or bluelimbo1 ~= bluelimbo2 then
			if redlimbo1 ~= redlimbo2 then
				changedred = true
				redflag = false
				redlimbo2 = redlimbo1
			elseif bluelimbo1 ~= bluelimbo2 then
				changedblue = true
				blueflag = false
				bluelimbo2 = bluelimbo1
			end
		end
		local ltm = os.time()
		if redflag == true then
			if alertflag == true then
				local x = 1
				for index in pairs(alerted_id) do
					local team = tonumber(et.gentity_get(alerted_id[x], "sess.sessionTeam"))
					if team == 1 then
						local health = tonumber(et.gentity_get(alerted_id[x], "health"))
						if health > 0 then
							if redspawn + redlimbo1 / 1000 - ltm <= 3 and redspawn + redlimbo1 / 1000 - ltm > 0 then
								et.G_ClientSound(alerted_id[x], sound)
								et.trap_SendServerCommand(-1, "chat \"^1" .. redspawn + redlimbo1 / 1000 - ltm .. "\"\n")
							end
						end
					end
					x = x + 1
				end
			end
			if ltm == redspawn + redlimbo1 / 1000 then
				redspawn = ltm
			end
		end
		if blueflag == true then
			if alertflag == true then
				local x = 1
				for index in pairs(alerted_id) do
					local team = tonumber(et.gentity_get(alerted_id[x], "sess.sessionTeam"))
					if team == 2 then
						local health = tonumber(et.gentity_get(alerted_id[x], "health"))
						if health > 0 then
							if bluespawn + bluelimbo1 / 1000 - ltm <= 3 and bluespawn + bluelimbo1 / 1000 - ltm > 0 then
								et.G_ClientSound(alerted_id[x], sound)
								et.trap_SendServerCommand(-1, "chat \"^1" .. bluespawn + bluelimbo1 / 1000 - ltm .. "\"\n")
							end
						end
					end
					x = x + 1
				end
			end
			if ltm == bluespawn + bluelimbo1 / 1000 then
				bluespawn = ltm
			end
		end
	end
end

function et_ClientSpawn(id, revived)
	local gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
	if gamestate == 0 then
		if revived ~= 1 then
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			if team == 1 then
				if redflag == false then
					if spawns[id] == nil then
						spawns[id] = 1
					else
						spawns[id] = spawns[id] + 1
					end
					if spawns[id] == 2 then
						redflag = true
						redspawn = os.time()
					end
					if changedred == true then
						redflag = true
						redspawn = os.time()
						changedred = false
					end
				end
			elseif team == 2 then
				if blueflag == false then
					if spawns[id] == nil then
						spawns[id] = 1
					else
						spawns[id] = spawns[id] + 1
					end
					if spawns[id] == 2 then
						blueflag = true
						bluespawn = os.time()
					end
					if changedblue == true then
						blueflag = true
						bluespawn = os.time()
						changedblue = false
					end
				end
			end
		end
	end
end

function et_ClientBegin(id)
	local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
	if players[id] == nil then
		players[id] = team
	end
end

function et_ClientUserinfoChanged(id)
	local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
	if players[id] == nil then
		players[id] = team
	end

	if players[id] ~= team then
		spawns[id] = nil
	end
end

function et_ClientDisconnect(id)
	local cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(id), "cl_guid")
	if alerted[cl_guid] == true then
		alerted[cl_guid] = nil
		local index={}
		for k,v in pairs(alerted_id) do
			index[v]=k
		end
		table.remove(alerted_id, index[id])
		if next(alerted) == nil then
			alertflag = false
		end
	end

	players[id] = nil
	spawns[id] = nil
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
	return 0
end

function et_ClientCommand(id, cmd)
	local cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(id), "cl_guid")
	local function has_value (tab, val)
		for index, value in ipairs(tab) do
			if value == val then
				return true
			end
		end
		return false
	end
	if et.trap_Argv(0) == "say" or et.trap_Argv(0) == "say_team" or et.trap_Argv(0) == "say_buddy" then
		if et.trap_Argv(0) == "m" or et.trap_Argv(0) == "pm" then
			if (string.sub(et.trap_Argv(2), 1, 6) == "!timer") then
				alerted[cl_guid] = true
				if not has_value(alerted_id, id) then
					table.insert(alerted_id, id)
				end
				alertflag = true
			end
			if (string.sub(et.trap_Argv(2), 1, 8) == "!untimer") then
				if alerted[cl_guid] == true then
					alerted[cl_guid] = nil
					local index={}
					for k,v in pairs(alerted_id) do
						index[v]=k
					end
					table.remove(alerted_id, index[id])
					if next(alerted) == nil then
						alertflag = false
					end
				end
			end
		else
			if string.lower(et.trap_Argv(1)) == "!timer" then
				alerted[cl_guid] = true
				if not has_value(alerted_id, id) then
					table.insert(alerted_id, id)
				end
				alertflag = true
				return 1
			end
			if string.lower(et.trap_Argv(1)) == "!untimer" then
				if alerted[cl_guid] == true then
					alerted[cl_guid] = nil
					local index={}
					for k,v in pairs(alerted_id) do
						index[v]=k
					end
					table.remove(alerted_id, index[id])
					if next(alerted) == nil then
						alertflag = false
					end
				end
				return 1
			end
		end
	end
	return(0)
end