-- balance.lua, original by harald, modified by x0rnn:
-- notify players when teams are uneven (player count) or unbalanced (damage given)

function et_InitGame(levelTime,randomSeed,restart)
	et.RegisterModname("balance.lua "..et.FindSelf())

	maxClients = tonumber(et.trap_Cvar_Get("sv_maxclients"))
	for i=0,maxClients-1 do
		players[i] = nil
	end
end

players = {}
checkInterval = 15000 -- 15 seconds
checkInterval2 = 45000 -- must be equal or a multiplier of above
unevenDiff = 2
unbalancedDiff = 15000
axisPlayers = {}
alliedPlayers = {}

function et_RunFrame( levelTime )
	if math.mod(levelTime,checkInterval) ~= 0 then return end
	gamestate = tonumber(et.trap_Cvar_Get("gamestate"))

	if gamestate == 0 then
		local numAlliedPlayers = table.getn( alliedPlayers )
		local numAxisPlayers = table.getn( axisPlayers )
		local axisdmg = 0
		local alliesdmg = 0
	
		if numAlliedPlayers >= numAxisPlayers + unevenDiff then
			et.trap_SendServerCommand(-1, "chat \"^4Allies ^7have ^4" .. numAlliedPlayers-numAxisPlayers .. " ^7players more. ^3Please even the teams!\"\n")
		elseif numAxisPlayers >= numAlliedPlayers + unevenDiff then
			et.trap_SendServerCommand(-1, "chat \"^1Axis ^7have ^1" .. numAxisPlayers-numAlliedPlayers .. " ^7players more. ^3Please even the teams!\"\n")
		end

		if math.mod(levelTime,checkInterval2) == 0 then
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
		end
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

	if players[clientNum] == nil then
		players[clientNum] = team
	end

	if players[clientNum] ~= team then
		if team == 1 then
			if players[clientNum] == 2 then
				table.remove( alliedPlayers, clientNum )
			end
			table.insert( axisPlayers, clientNum )
			players[clientNum] = team
		elseif team == 2 then
			if players[clientNum] == 1 then
				table.remove( axisPlayers, clientNum )
			end
			table.insert( alliedPlayers, clientNum )
			players[clientNum] = team
		else
			if players[clientNum] == 1 then
				table.remove( axisPlayers, clientNum )
			elseif players[clientNum] == 2 then
				table.remove( alliedPlayers, clientNum )
			end
			players[clientNum] = team
		end
	end
end

function et_ClientDisconnect( clientNum )
	if players[clientNum] == 1 then
		table.remove( axisPlayers, clientNum )
	end
	if players[clientNum] == 2 then
		table.remove( alliedPlayers, clientNum )
	end
	players[clientNum] = nil
end

function et_ConsoleCommand()
	if et.trap_Argv(0) == "pb_sv_kick" then
		if et.trap_Argc() == 2 then
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