-- autoafk999spec.lua - auto-puts 999 and afk players to spectator
-- inactivity code from "Player Inactivity Modification" (inacmod.lua) by hadro
-- g_inactivity needs to be enabled
-- it is strongly recommended to set g_inactivity at least 11 seconds higher than max_player_inactivity

checkInterval = 15000 -- interval in milliseconds to check ping (15 sec)
pings = {} -- pings[clientid][15 sec interval ping]; if 3 intervals (45 sec) are all 999, player is put to spec
max_player_inactivity = 120000 -- time in milliseconds before a player gets moved to spectator for being inactive (2 min)

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("autoafk999spec.lua "..et.FindSelf())
	for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
		pings[i] = {[1]=0, [2]=0, [3]=0}
	end
end

function et_RunFrame(levelTime)
	if math.mod(levelTime,checkInterval) ~= 0 then return end
	local matches999 = 0
	local matchesafk = 0
	gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
	if gamestate == 0 then
		for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
			local team = tonumber(et.gentity_get(i,"sess.sessionTeam"))
			if team == 1 or team == 2 then
				local ping = tonumber(et.gentity_get(i,"ps.ping"))
				local inact = tonumber(et.gentity_get(i, "client.inactivityTime"))
				local g_inactivity = tonumber(et.trap_Cvar_Get("g_inactivity")) * 1000
				-- afk check
				if levelTime >= inact - (g_inactivity - max_player_inactivity) then
					matchesafk = matchesafk + 1
					et.trap_SendConsoleCommand( et.EXEC_APPEND, "ref remove " .. i .. "\n" )
				end
				-- 999 check
				if pings[i][1] == 0 then
					pings[i][1] = ping
				elseif pings[i][1] ~= 0 then
					if pings[i][2] == 0 then
						pings[i][2] = ping
					elseif pings[i][2] ~= 0 then
						pings[i][3] = ping
						if pings[i][1] >= 999 and pings[i][2] >= 999 and pings[i][3] >= 999 then
							matches999 = matches999 + 1
							et.trap_SendConsoleCommand( et.EXEC_APPEND, "ref remove " .. i .. "\n" )
						else
							pings[i][1] = 0
							pings[i][2] = 0
							pings[i][3] = 0
						end
					end
				end
			end
		end
		if matches999 ~= 0 then
			et.trap_SendConsoleCommand( et.EXEC_APPEND, "qsay ^3auto-spec999: ^7Moving ^1" ..matches999.. " ^7999 ping player(s) to spectator\n" )
		end
		if matchesafk ~= 0 then
			et.trap_SendConsoleCommand( et.EXEC_APPEND, "qsay ^3auto-afk: ^7Moving ^1" ..matchesafk.. " ^7AFK player(s) to spectator\n" )
		end
	end
end
