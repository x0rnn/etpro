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
checkInterval2 = 30000 -- must be equal or a multiplier of above
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
			et.trap_SendServerCommand(-1, "chat \"^4Allies ^7have ^4" .. numAlliedPlayers-numAxisPlayers .. " ^7players more. Please even the teams!\"\n")
		elseif numAxisPlayers >= numAlliedPlayers + unevenDiff then
			et.trap_SendServerCommand(-1, "chat \"^1Axis ^7have ^1" .. numAxisPlayers-numAlliedPlayers .. " ^7players more. Please even the teams!\"\n")
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
				et.trap_SendServerCommand(-1, "chat \"^1Axis ^7have over ^1" .. diff .. " ^7more damage given. Please balance the teams!\"\n")
			elseif alliesdmg >= axisdmg + unbalancedDiff then
				local subt = alliesdmg - axisdmg
				local diff = subt - math.mod(subt, 1000)
				et.trap_SendServerCommand(-1, "chat \"^4Allies ^7have over ^4" .. diff .. " ^7more damage given. Please balance the teams!\"\n")
			end
		end
	end
end

function et_ClientBegin(clientNum)
	local team = tonumber(et.gentity_get(clientNum, "sess.sessionTeam"))

	if players[clientNum] == nil then
		players[clientNum] = team
	end

	if team == 1 then
		table.insert( axisPlayers, clientNum )
	elseif team == 2 then
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
