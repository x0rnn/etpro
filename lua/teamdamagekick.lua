checkInterval = 180000 -- interval in milliseconds to check team damage (3 minutes)
kickReason = "You made too much team damage."
banTime = 1800 -- ban time in seconds (30 minutes)

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("teamdamagekick.lua "..et.FindSelf())
end

function et_RunFrame(levelTime)
	if math.mod(levelTime,checkInterval) ~= 0 then return end
	for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
		local team = tonumber(et.gentity_get(i, "sess.sessionTeam"))
		if team == 1 or team == 2 then
			local teamdamage = et.gentity_get(i, "sess.team_damage")
			if teamdamage == 1200 then
				et.trap_DropClient(i, kickReason, banTime)
			end
		end
	end
end
