-- hirnlos players announcement, version for hirntot server (read version)
-- symlink hirnlos_announce.txt from hirnlos etpro server folder to hirntot etpro server folder

checkInterval = 120000 -- interval in milliseconds to check hirnlos player count (2 minutes)
filename = "hirnlos_announce.txt"

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("hirnlos_r.lua "..et.FindSelf())
end

function et_RunFrame(levelTime)
	if math.mod(levelTime,checkInterval) ~= 0 then return end
	players = 0
	for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
		if et.gentity_get(i,"inuse") then
			players = players + 1
		end
	end

	jq_count = tonumber(et.trap_Cvar_Get("jq_count"))
	fullmsg = string.lower(et.trap_Cvar_Get("sv_fullmsg"))
	los_players = 0

	if players > 24 and jq_count > 0 then
		fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
		if len > 0 then
			filestr = et.trap_FS_Read(fd, len)
			for p,m in string.gfind(filestr, "([^\t]+)\t([^\n]+)") do
				los_players = tonumber(p)
				if los_players < 25 then
					et.trap_SendServerCommand(-1, "chat \"^3" .. p .. "/30 ^7players on ^1H^7irntot ^12 ^7playing ^2" .. m  .. "^7. ^3/connect et2.hirntot.org ^7to join. No Battery, Railgun or heavy weapons!\"\n")
				end
			end
			filestr = nil
			if los_players > 0 and los_players < 30 then
				if fullmsg ~= "et://et2.hirntot.org:27960" then
					et.trap_Cvar_Set("sv_fullmsg", "ET://et2.hirntot.org:27960")
				end
			else
				if fullmsg == "et://et2.hirntot.org:27960" then
					et.trap_Cvar_Set("sv_fullmsg", "^6Server is fucking full! Don`t wait... join et2.hirntot.org ^7[^1!!!^7]^1H^7irntot with 10 Maps ^1no ^7Heavy Weapons.       ^2You prefer to wait?    Then donate or join www.hirntot.org/discord :)")
				end
			end
		else
			if fullmsg == "et://et2.hirntot.org:27960" then
				et.trap_Cvar_Set("sv_fullmsg", "^6Server is fucking full! Don`t wait... join et2.hirntot.org ^7[^1!!!^7]^1H^7irntot with 10 Maps ^1no ^7Heavy Weapons.       ^2You prefer to wait?    Then donate or join www.hirntot.org/discord :)")
			end
		end
		if len ~= -1 then
			et.trap_FS_FCloseFile(fd)
		end
	else
		if fullmsg == "et://et2.hirntot.org:27960" then
			et.trap_Cvar_Set("sv_fullmsg", "^6Server is fucking full! Don`t wait... join et2.hirntot.org ^7[^1!!!^7]^1H^7irntot with 10 Maps ^1no ^7Heavy Weapons.       ^2You prefer to wait?    Then donate or join www.hirntot.org/discord :)")
		end
	end
end
