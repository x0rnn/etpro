-- balance.lua, original by harald, modified by x0rnn:
-- notify players when teams are uneven (player count) or unbalanced (damage given)
-- pause the match when one team has 3+ players more and unpause when teams are even again

players = {}
checkInterval = 60000 -- 60 seconds
checkInterval2 = 180000 -- must be equal or a multiplier of above
unevenDiff = 2
unbalancedDiff = 15000
axisPlayers = {}
alliedPlayers = {}
numAlliedPlayers = 0
numAxisPlayers = 0
paused = false
filename = "teameveners.log"
eveners = {}

function et_InitGame(levelTime,randomSeed,restart)
	et.RegisterModname("balance.lua "..et.FindSelf())

	maxClients = tonumber(et.trap_Cvar_Get("sv_maxclients"))
	for i=0,maxClients-1 do
		players[i] = nil
	end

	local fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len == -1 then
		et.G_Print("balance.lua: no teameveners.log\n")
		return(0)
	end
	local filestr = et.trap_FS_Read(fd, len)
	et.trap_FS_FCloseFile(fd)

	local guid, num
	for guid, num in string.gfind(filestr,"([%x]+)\t([^\n]+)") do
		eveners[guid] = tonumber(num)
	end
end

function writeLog(eveners)
	local fd, len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
	if len == -1 then
		et.G_Print("balance.lua: no teameveners.log\n")
		return(0)
	end
	for key in pairs(eveners) do
		local line = key .. "\t" .. eveners[key] .. "\n"
		count = et.trap_FS_Write(line, string.len(line), fd)
	end
	et.trap_FS_FCloseFile(fd)
end

function et_RunFrame( levelTime )
	if math.mod(levelTime,checkInterval) ~= 0 then return end
	gamestate = tonumber(et.trap_Cvar_Get("gamestate"))

	if gamestate == 0 then
		numAlliedPlayers = table.getn( alliedPlayers )
		numAxisPlayers = table.getn( axisPlayers )
		local axisdmg = 0
		local alliesdmg = 0
		if math.mod(levelTime,checkInterval2) == 0 then
			if numAlliedPlayers >= numAxisPlayers + unevenDiff then
				if numAlliedPlayers >= numAxisPlayers + 3 then
					if paused == false then
						et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref pause\n")
						paused = true
						et.trap_SendServerCommand(-1, "chat \"^3Match auto-paused: ^4Allies ^7have ^4" .. numAlliedPlayers-numAxisPlayers .. " ^7players more. ^3Even the teams!\"\n")
						et.G_LogPrint("LUA event: match auto-paused\n")
					end
				else
					et.trap_SendServerCommand(-1, "chat \"^4Allies ^7have ^4" .. numAlliedPlayers-numAxisPlayers .. " ^7players more. ^3Please even the teams!\"\n")
				end
			elseif numAxisPlayers >= numAlliedPlayers + unevenDiff then
				if numAxisPlayers >= numAlliedPlayers + 3 then
					if paused == false then
						et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref pause\n")
						paused = true
						et.trap_SendServerCommand(-1, "chat \"^3Match auto-paused: ^1Axis ^7have ^1" .. numAxisPlayers-numAlliedPlayers .. " ^7players more. ^3Even the teams!\"\n")
						et.G_LogPrint("LUA event: match auto-paused\n")
					end
				else
					et.trap_SendServerCommand(-1, "chat \"^1Axis ^7have ^1" .. numAxisPlayers-numAlliedPlayers .. " ^7players more. ^3Please even the teams!\"\n")
				end
			end
		end

		--if math.mod(levelTime,checkInterval) == 0 then
			for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
				local team = tonumber(et.gentity_get(j, "sess.sessionTeam"))
				if team == 1 or team == 2 then
					if team == 1 then
						local dmg = tonumber(et.gentity_get(j, "sess.damage_given"))
						axisdmg = axisdmg + dmg
					elseif team == 2 then
						local dmg = tonumber(et.gentity_get(j, "sess.damage_given"))
						alliesdmg = alliesdmg + dmg
					end
				end
			end
			if axisdmg >= alliesdmg + unbalancedDiff then
				local subt = axisdmg - alliesdmg
				local diff = subt - math.mod(subt, 1000)
				et.trap_SendServerCommand(-1, "chat \"^1Axis ^7have over ^1" .. diff .. " ^7more damage given. ^3Please balance the teams!\"\n")
				local dmg = {0, 0, 0}
				local dmg_id = {0, 0, 0}
				local i = 0
				local cnt = 0
				for i=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
					local team = tonumber(et.gentity_get(i, "sess.sessionTeam"))
					if team == 1 then
						cnt = cnt + 1
						local dg = tonumber(et.gentity_get(i, "sess.damage_given"))
						if dg > dmg[1] then
							dmg[3] = dmg[2]
							dmg[2] = dmg[1]
							dmg[1] = dg
							dmg_id[3] = dmg_id[2]
							dmg_id[2] = dmg_id[1]
							dmg_id[1] = i
						elseif dg > dmg[2] then
							dmg[3] = dmg[2]
							dmg[2] = dg
							dmg_id[3] = dmg_id[2]
							dmg_id[2] = i
						elseif dg > dmg[3] then
							dmg[3] = dg
							dmg_id[3] = i
						end
						if cnt == numAxisPlayers then break end
					end
				end
				et.trap_SendServerCommand(-1, "chat \"^7Top 3 ^1Axis ^7damage dealers: " .. et.gentity_get(dmg_id[1], "pers.netname") .. " ^1(" .. dmg[1] .. ")^7, " .. et.gentity_get(dmg_id[2], "pers.netname") .. " ^1(" .. dmg[2] .. ")^7, " .. et.gentity_get(dmg_id[3], "pers.netname") .. " ^1(" .. dmg[3] .. ")\"\n")
			elseif alliesdmg >= axisdmg + unbalancedDiff then
				local subt = alliesdmg - axisdmg
				local diff = subt - math.mod(subt, 1000)
				et.trap_SendServerCommand(-1, "chat \"^4Allies ^7have over ^4" .. diff .. " ^7more damage given. ^3Please balance the teams!\"\n")
				local dmg = {0, 0, 0}
				local dmg_id = {0, 0, 0}
				local i = 0
				local cnt = 0
				for i=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
					local team = tonumber(et.gentity_get(i, "sess.sessionTeam"))
					if team == 2 then
						cnt = cnt + 1
						local dg = tonumber(et.gentity_get(i, "sess.damage_given"))
						if dg > dmg[1] then
							dmg[3] = dmg[2]
							dmg[2] = dmg[1]
							dmg[1] = dg
							dmg_id[3] = dmg_id[2]
							dmg_id[2] = dmg_id[1]
							dmg_id[1] = i
						elseif dg > dmg[2] then
							dmg[3] = dmg[2]
							dmg[2] = dg
							dmg_id[3] = dmg_id[2]
							dmg_id[2] = i
						elseif dg > dmg[3] then
							dmg[3] = dg
							dmg_id[3] = i
						end
						if cnt == numAlliedPlayers then break end
					end
				end
				et.trap_SendServerCommand(-1, "chat \"^7Top 3 ^4Allied ^7damage dealers: " .. et.gentity_get(dmg_id[1], "pers.netname") .. " ^4(" .. dmg[1] .. ")^7, " .. et.gentity_get(dmg_id[2], "pers.netname") .. " ^4(" .. dmg[2] .. ")^7, " .. et.gentity_get(dmg_id[3], "pers.netname") .. " ^4(" .. dmg[3] .. ")\"\n")
			end
		--end
	end
end

function et_ClientBegin(clientNum)
	local function has_value (tab, val)
		for index, value in ipairs(tab) do
			if value == val then
				return true
			end
		end
		return false
	end

	local team = tonumber(et.gentity_get(clientNum, "sess.sessionTeam"))

	if players[clientNum] == nil then
		players[clientNum] = team
	end

	if team == 1 and not has_value(axisPlayers, clientNum) then
		table.insert( axisPlayers, clientNum )
	elseif team == 2 and not has_value(alliedPlayers, clientNum) then
		table.insert( alliedPlayers, clientNum )
	end
end

function et_ClientUserinfoChanged(clientNum)
	local team = tonumber(et.gentity_get(clientNum, "sess.sessionTeam"))
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")

	if players[clientNum] == nil then
		players[clientNum] = team
	end

	local tmp = players[clientNum]

	if players[clientNum] ~= team then
		if team == 1 then
			if players[clientNum] == 2 then
				local index={}
				for k,v in pairs(alliedPlayers) do
					index[v]=k
				end
				table.remove( alliedPlayers, index[clientNum] )
				numAlliedPlayers = table.getn( alliedPlayers )
			end
			table.insert( axisPlayers, clientNum )
			numAxisPlayers = table.getn( axisPlayers )
			players[clientNum] = team
		elseif team == 2 then
			if players[clientNum] == 1 then
				local index={}
				for k,v in pairs(axisPlayers) do
					index[v]=k
				end
				table.remove( axisPlayers, index[clientNum] )
				numAxisPlayers = table.getn( axisPlayers )
			end
			table.insert( alliedPlayers, clientNum )
			numAlliedPlayers = table.getn( alliedPlayers )
			players[clientNum] = team
		else
			if players[clientNum] == 1 then
				local index={}
				for k,v in pairs(axisPlayers) do
					index[v]=k
				end
				table.remove( axisPlayers, index[clientNum] )
				numAxisPlayers = table.getn( axisPlayers )
			elseif players[clientNum] == 2 then
				local index={}
				for k,v in pairs(alliedPlayers) do
					index[v]=k
				end
				table.remove( alliedPlayers, index[clientNum] )
				numAlliedPlayers = table.getn( alliedPlayers )
			end
			players[clientNum] = team
		end
	end

	if paused == true then
		if numAlliedPlayers > numAxisPlayers then
			if tmp == 2 and team == 1 then
				if eveners[cl_guid] == nil then
					eveners[cl_guid] = 1
				else
					eveners[cl_guid] = eveners[cl_guid] + 1
				end
				writeLog(eveners)
				et.trap_SendServerCommand(clientNum, "chat \"^7Thank you for switching. Your good deed has been logged.\"\n")
			end
			if numAlliedPlayers - numAxisPlayers < 2 then
				et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref unpause\n")
				et.trap_SendServerCommand(-1, "chat \"^3Match unpaused!\"\n")
				paused = false
			end
		elseif numAxisPlayers > numAlliedPlayers then
			if tmp == 1 and team == 2 then
				if eveners[cl_guid] == nil then
					eveners[cl_guid] = 1
				else
					eveners[cl_guid] = eveners[cl_guid] + 1
				end
				writeLog(eveners)
				et.trap_SendServerCommand(clientNum, "chat \"^7Thank you for switching. Your good deed has been logged.\"\n")
			end
			if numAxisPlayers - numAlliedPlayers < 2 then
				et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref unpause\n")
				et.trap_SendServerCommand(-1, "chat \"^3Match unpaused!\"\n")
				paused = false
			end
		elseif numAxisPlayers == numAlliedPlayers then
			if (tmp == 1 and team == 2) or (tmp == 2 and team == 1) then
				if eveners[cl_guid] == nil then
					eveners[cl_guid] = 1
				else
					eveners[cl_guid] = eveners[cl_guid] + 1
				end
				writeLog(eveners)
				et.trap_SendServerCommand(clientNum, "chat \"^7Thank you for switching. Your good deed has been logged.\"\n")
			end
			et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref unpause\n")
			et.trap_SendServerCommand(-1, "chat \"^3Match unpaused!\"\n")
			paused = false
		end
	else
		if numAlliedPlayers == numAxisPlayers then
			if (tmp == 1 and team == 2) or (tmp == 2 and team == 1) then
				if eveners[cl_guid] == nil then
					eveners[cl_guid] = 1
				else
					eveners[cl_guid] = eveners[cl_guid] + 1
				end
				writeLog(eveners)
				et.trap_SendServerCommand(clientNum, "chat \"^7Thank you for switching. Your good deed has been logged.\"\n")
			end
		end
	end
end

function et_ClientDisconnect( clientNum )
	if players[clientNum] == 1 then
		local index={}
		for k,v in pairs(axisPlayers) do
			index[v]=k
		end
		table.remove( axisPlayers, index[clientNum] )
		numAxisPlayers = table.getn( axisPlayers )
	end
	if players[clientNum] == 2 then
		local index={}
		for k,v in pairs(alliedPlayers) do
			index[v]=k
		end
		table.remove( alliedPlayers, index[clientNum] )
		numAlliedPlayers = table.getn( alliedPlayers )
	end
	players[clientNum] = nil

	if paused == true then
		if numAlliedPlayers > numAxisPlayers then
			if numAlliedPlayers - numAxisPlayers < 2 then
				et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref unpause\n")
				et.trap_SendServerCommand(-1, "chat \"^3Match unpaused!\"\n")
				paused = false
			end
		elseif numAxisPlayers > numAlliedPlayers then
			if numAxisPlayers - numAlliedPlayers < 2 then
				et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref unpause\n")
				et.trap_SendServerCommand(-1, "chat \"^3Match unpaused!\"\n")
				paused = false
			end
		elseif numAxisPlayers == numAlliedPlayers then
			et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref unpause\n")
			et.trap_SendServerCommand(-1, "chat \"^3Match unpaused!\"\n")
			paused = false
		end

		local players = 0
		for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
			if et.gentity_get(i,"inuse") then
				players = players + 1
			end
		end
		if players-1 == 0 then
			et.trap_SendConsoleCommand(et.EXEC_APPEND, "ref unpause\n")
		end 
	end
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