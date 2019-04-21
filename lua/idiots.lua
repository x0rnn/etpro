-- idiots.lua by x0rnn
-- -3 level players (idiots) emit a beeping sound to the enemy team so they know when they are nearby
-- their health is set to 69, ammo halved and second ammoclip emptied, deaths set to 69, kills to 0 and skills to 0
-- modify etadmin_mod/bin/shrub_management.pl line 161 to:
-- if ( !defined($level) || $level < -1000 || !$guid || ( !$name && $level != 0 ) || length($guid) != 32 )

filename = "shrubbot.cfg"
idiots = {}
flag = false

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("idiots.lua "..et.FindSelf())

	local fd, len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len > -1 then
		local content = et.trap_FS_Read(fd, len)
		for guid in string.gfind(content, "[Gg]uid%s*=%s*(%x+)%s*\n[Ll]evel\t%= %-3") do
			idiots[guid] = true
		end
		content = nil
	end
	et.trap_FS_FCloseFile(fd)
end

function et_ClientBegin(clientNum)
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	if idiots[cl_guid] == true then
		flag = true
	end
end

function et_ClientDisconnect(clientNum)
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	if idiots[cl_guid] == true then
		flag = false
	end
end

function et_ClientSpawn(clientNum, revived)
	if flag == true then
		cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
		if idiots[cl_guid] == true then
			weapon = et.gentity_get(clientNum, "sess.playerWeapon")
			weapon2 = et.gentity_get(clientNum, "sess.playerWeapon2")
			ammo = et.gentity_get(clientNum, "ps.ammo", weapon)
			ammoclip = et.gentity_get(clientNum, "ps.ammoclip", weapon)
			ammo2 = et.gentity_get(clientNum, "ps.ammo", weapon2)
			ammoclip2 = et.gentity_get(clientNum, "ps.ammoclip", weapon2)

			et.gentity_set(clientNum, "ps.stats", 4, 69) -- max_health
			et.gentity_set(clientNum, "health", 69)
			et.gentity_set(clientNum, "sess.kills", 0)
			et.gentity_set(clientNum, "sess.deaths", 69)
			et.gentity_set(clientNum, "sess.skill", 0, 0)
			et.gentity_set(clientNum, "sess.skill", 1, 0)
			et.gentity_set(clientNum, "sess.skill", 2, 0)
			et.gentity_set(clientNum, "sess.skill", 3, 0)
			et.gentity_set(clientNum, "sess.skill", 4, 0)
			et.gentity_set(clientNum, "sess.skill", 5, 0)
			et.gentity_set(clientNum, "sess.skill", 6, 0)
			et.gentity_set(clientNum, "ps.ammo", weapon, 0)
			et.gentity_set(clientNum, "ps.ammoclip", weapon, ammoclip/2)
			et.gentity_set(clientNum, "ps.ammo", weapon2, 0)
			et.gentity_set(clientNum, "ps.ammoclip", weapon2, ammoclip2/2)
		end
	end
end

function et_RunFrame(levelTime)
	if math.mod(levelTime, 1500) ~= 0 then return end
	if flag == true then
		for i=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
			cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(i), "cl_guid")
			if idiots[cl_guid] == true then
				idiot_team = tonumber(et.gentity_get(i, "sess.sessionTeam"))
				if idiot_team == 1 or idiot_team == 2 then
					for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
						opponent_team = tonumber(et.gentity_get(j, "sess.sessionTeam"))
						if opponent_team ~= 0 and opponent_team ~= 3 and opponent_team ~= idiot_team then
							sound = "sound/misc/regen.wav"
							soundindex = et.G_SoundIndex(sound)
							et.G_Sound(i, soundindex)
						end
					end
				end
			end
		end
	end
end