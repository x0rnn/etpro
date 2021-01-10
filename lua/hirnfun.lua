et.MAX_WEAPONS = 50

panzerwar = {
	nil,	--// 1
	false,	--WP_LUGER,				// 2
	false,	--WP_MP40,				// 3
	false,	--WP_GRENADE_LAUNCHER,	// 4
	true,	--WP_PANZERFAUST,		// 5
	false,	--WP_FLAMETHROWER,		// 6
	false,	--WP_COLT,				// 7	// equivalent american weapon to german luger
	false,	--WP_THOMPSON,			// 8	// equivalent american weapon to german mp40
	false,	--WP_GRENADE_PINEAPPLE,	// 9
	false,	--WP_STEN,				// 10	// silenced sten sub-machinegun
	false,	--WP_MEDIC_SYRINGE,		// 11	// JPW NERVE -- broken out from CLASS_SPECIAL per Id request
	false,	--WP_AMMO,				// 12	// JPW NERVE likewise
	false,	--WP_ARTY,				// 13
	false,	--WP_SILENCER,			// 14	// used to be sp5
	false,	--WP_DYNAMITE,			// 15
	nil,	--// 16
	nil,	--// 17
	nil,		--// 18
	false,	--WP_MEDKIT,			// 19
	true,	--WP_BINOCULARS,		// 20
	nil,	--// 21
	nil,	--// 22
	false,	--WP_KAR98,				// 23	// WolfXP weapons
	false,	--WP_CARBINE,			// 24
	false,	--WP_GARAND,			// 25
	false,	--WP_LANDMINE,			// 26
	false,	--WP_SATCHEL,			// 27
	false,	--WP_SATCHEL_DET,		// 28
	nil,	--// 29
	false,	--WP_SMOKE_BOMB,		// 30
	false,	--WP_MOBILE_MG42,		// 31
	false,	--WP_K43,				// 32
	false,	--WP_FG42,				// 33
	nil,	--// 34
	false,	--WP_MORTAR,			// 35
	nil,	--// 36
	false,	--WP_AKIMBO_COLT,		// 37
	false,	--WP_AKIMBO_LUGER,		// 38
	nil,	--// 39
	nil,	--// 40
	false,	--WP_SILENCED_COLT,		// 41
	false,	--WP_GARAND_SCOPE,		// 42
	false,	--WP_K43_SCOPE,			// 43
	false,	--WP_FG42SCOPE,			// 44
	false,	--WP_MORTAR_SET,		// 45
	false,	--WP_MEDIC_ADRENALINE,	// 46
	false,	--WP_AKIMBO_SILENCEDCOLT,// 47
	false	--WP_AKIMBO_SILENCEDLUGER,// 48
}

pistolwar = {
	nil,	--// 1
	true,	--WP_LUGER,				// 2
	false,	--WP_MP40,				// 3
	false,	--WP_GRENADE_LAUNCHER,	// 4
	false,	--WP_PANZERFAUST,		// 5
	false,	--WP_FLAMETHROWER,		// 6
	true,	--WP_COLT,				// 7	// equivalent american weapon to german luger
	false,	--WP_THOMPSON,			// 8	// equivalent american weapon to german mp40
	false,	--WP_GRENADE_PINEAPPLE,	// 9
	false,	--WP_STEN,				// 10	// silenced sten sub-machinegun
	true,	--WP_MEDIC_SYRINGE,		// 11	// JPW NERVE -- broken out from CLASS_SPECIAL per Id request
	false,	--WP_AMMO,				// 12	// JPW NERVE likewise
	false,	--WP_ARTY,				// 13
	true,	--WP_SILENCER,			// 14	// used to be sp5
	false,	--WP_DYNAMITE,			// 15
	nil,	--// 16
	nil,	--// 17
	nil,		--// 18
	true,	--WP_MEDKIT,			// 19
	true,	--WP_BINOCULARS,		// 20
	nil,	--// 21
	nil,	--// 22
	false,	--WP_KAR98,				// 23	// WolfXP weapons
	false,	--WP_CARBINE,			// 24
	false,	--WP_GARAND,			// 25
	false,	--WP_LANDMINE,			// 26
	false,	--WP_SATCHEL,			// 27
	false,	--WP_SATCHEL_DET,		// 28
	nil,	--// 29
	false,	--WP_SMOKE_BOMB,		// 30
	false,	--WP_MOBILE_MG42,		// 31
	false,	--WP_K43,				// 32
	false,	--WP_FG42,				// 33
	nil,	--// 34
	false,	--WP_MORTAR,			// 35
	nil,	--// 36
	false,	--WP_AKIMBO_COLT,		// 37
	false,	--WP_AKIMBO_LUGER,		// 38
	nil,	--// 39
	nil,	--// 40
	true,	--WP_SILENCED_COLT,		// 41
	false,	--WP_GARAND_SCOPE,		// 42
	false,	--WP_K43_SCOPE,			// 43
	false,	--WP_FG42SCOPE,			// 44
	false,	--WP_MORTAR_SET,		// 45
	false,	--WP_MEDIC_ADRENALINE,	// 46
	false,	--WP_AKIMBO_SILENCEDCOLT,// 47
	false	--WP_AKIMBO_SILENCEDLUGER,// 48
}

riflewar = {
	nil,	--// 1
	false,	--WP_LUGER,				// 2
	false,	--WP_MP40,				// 3
	true,	--WP_GRENADE_LAUNCHER,	// 4
	false,	--WP_PANZERFAUST,		// 5
	false,	--WP_FLAMETHROWER,		// 6
	false,	--WP_COLT,				// 7	// equivalent american weapon to german luger
	false,	--WP_THOMPSON,			// 8	// equivalent american weapon to german mp40
	true,	--WP_GRENADE_PINEAPPLE,	// 9
	false,	--WP_STEN,				// 10	// silenced sten sub-machinegun
	false,	--WP_MEDIC_SYRINGE,		// 11	// JPW NERVE -- broken out from CLASS_SPECIAL per Id request
	false,	--WP_AMMO,				// 12	// JPW NERVE likewise
	false,	--WP_ARTY,				// 13
	false,	--WP_SILENCER,			// 14	// used to be sp5
	false,	--WP_DYNAMITE,			// 15
	nil,	--// 16
	nil,	--// 17
	nil,		--// 18
	false,	--WP_MEDKIT,			// 19
	true,	--WP_BINOCULARS,		// 20
	nil,	--// 21
	nil,	--// 22
	false,	--WP_KAR98,				// 23	// WolfXP weapons
	false,	--WP_CARBINE,			// 24
	false,	--WP_GARAND,			// 25
	false,	--WP_LANDMINE,			// 26
	false,	--WP_SATCHEL,			// 27
	false,	--WP_SATCHEL_DET,		// 28
	nil,	--// 29
	false,	--WP_SMOKE_BOMB,		// 30
	false,	--WP_MOBILE_MG42,		// 31
	false,	--WP_K43,				// 32
	false,	--WP_FG42,				// 33
	nil,	--// 34
	false,	--WP_MORTAR,			// 35
	nil,	--// 36
	false,	--WP_AKIMBO_COLT,		// 37
	false,	--WP_AKIMBO_LUGER,		// 38
	true,	--// 39
	true,	--// 40
	false,	--WP_SILENCED_COLT,		// 41
	false,	--WP_GARAND_SCOPE,		// 42
	false,	--WP_K43_SCOPE,			// 43
	false,	--WP_FG42SCOPE,			// 44
	false,	--WP_MORTAR_SET,		// 45
	false,	--WP_MEDIC_ADRENALINE,	// 46
	false,	--WP_AKIMBO_SILENCEDCOLT,// 47
	false	--WP_AKIMBO_SILENCEDLUGER,// 48
}

sniperwar = {
	nil,	--// 1
	false,	--WP_LUGER,				// 2
	false,	--WP_MP40,				// 3
	false,	--WP_GRENADE_LAUNCHER,	// 4
	false,	--WP_PANZERFAUST,		// 5
	false,	--WP_FLAMETHROWER,		// 6
	false,	--WP_COLT,				// 7	// equivalent american weapon to german luger
	false,	--WP_THOMPSON,			// 8	// equivalent american weapon to german mp40
	false,	--WP_GRENADE_PINEAPPLE,	// 9
	false,	--WP_STEN,				// 10	// silenced sten sub-machinegun
	false,	--WP_MEDIC_SYRINGE,		// 11	// JPW NERVE -- broken out from CLASS_SPECIAL per Id request
	false,	--WP_AMMO,				// 12	// JPW NERVE likewise
	false,	--WP_ARTY,				// 13
	false,	--WP_SILENCER,			// 14	// used to be sp5
	false,	--WP_DYNAMITE,			// 15
	nil,	--// 16
	nil,	--// 17
	nil,		--// 18
	false,	--WP_MEDKIT,			// 19
	true,	--WP_BINOCULARS,		// 20
	nil,	--// 21
	nil,	--// 22
	false,	--WP_KAR98,				// 23	// WolfXP weapons
	false,	--WP_CARBINE,			// 24
	true,	--WP_GARAND,			// 25
	false,	--WP_LANDMINE,			// 26
	false,	--WP_SATCHEL,			// 27
	false,	--WP_SATCHEL_DET,		// 28
	nil,	--// 29
	true,	--WP_SMOKE_BOMB,		// 30
	false,	--WP_MOBILE_MG42,		// 31
	true,	--WP_K43,				// 32
	false,	--WP_FG42,				// 33
	nil,	--// 34
	false,	--WP_MORTAR,			// 35
	nil,	--// 36
	false,	--WP_AKIMBO_COLT,		// 37
	false,	--WP_AKIMBO_LUGER,		// 38
	false,	--// 39
	false,	--// 40
	false,	--WP_SILENCED_COLT,		// 41
	true,	--WP_GARAND_SCOPE,		// 42
	true,	--WP_K43_SCOPE,			// 43
	false,	--WP_FG42SCOPE,			// 44
	false,	--WP_MORTAR_SET,		// 45
	false,	--WP_MEDIC_ADRENALINE,	// 46
	false,	--WP_AKIMBO_SILENCEDCOLT,// 47
	false	--WP_AKIMBO_SILENCEDLUGER,// 48
}

panzerwar_flag = false
pistolwar_flag = false
riflewar_flag = false
sniperwar_flag = false
mapname = ""

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("hirnfun.lua "..et.FindSelf())
	mapname = et.trap_Cvar_Get("mapname")
	if mapname == "rifletennis_te" then
		riflewar_flag = true
	end
	if mapname == "basket_panzer" then
		panzerwar_flag = true
	end
	if mapname == "purefrag" then
		pistolwar_flag = true
	end
	if mapname == "ctf-face-fp1" then
		sniperwar_flag = true
	end
end

function et_ClientCommand(id, command)
	admin_flag = false
	guid = et.Info_ValueForKey(et.trap_GetUserinfo(id), "cl_guid")
	if et.trap_Argv(0) == "say" then
		args = et.ConcatArgs(1)
		local args_table = {}
		cnt = 0
		for i in string.gfind(args, "%S+") do
			table.insert(args_table, i)
			cnt = cnt + 1
		end
		if args_table[1] == "!panzerwar" and (mapname == "basket_panzer" or mapname == "q3dm17" or mapname == "ctf-face-fp1") then
			if panzerwar_flag == false then
				panzerwar_flag = true
				pistolwar_flag = false
				sniperwar_flag = false
				et.trap_SendServerCommand(-1, "chat \"^1Panzerwar enabled!\"\n")
				for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
					et.G_Damage(j, 80, 1022, 1000, 8, 34)
				end
			end
		end
		--if args_table[1] == "!riflewar" and mapname == "rifletennis_te" then
		--	if riflewar_flag == false then
		--		riflewar_flag = true
		--		et.trap_SendServerCommand(-1, "chat \"^1Riflewar enabled!\"\n")
		--		for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
		--			et.G_Damage(j, 80, 1022, 1000, 8, 34)
		--		end
		--	end
		--end
		if args_table[1] == "!sniperwar" and mapname == "ctf-face-fp1" then
			if sniperwar_flag == false then
				sniperwar_flag = true
				panzerwar_flag = false
				pistolwar_flag = false
				et.trap_SendServerCommand(-1, "chat \"^1Sniperwar enabled!\"\n")
				for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
					et.G_Damage(j, 80, 1022, 1000, 8, 34)
				end
			end
		end
		if args_table[1] == "!pistolwar" then
			if pistolwar_flag == false and mapname ~= "rifletennis_te" and mapname ~= "basket_panzer" and mapname ~= "ctf-face-fp1" and mapname ~= "puzzlemap" then
				pistolwar_flag = true
				panzerwar_flag = false
				et.trap_SendServerCommand(-1, "chat \"^1Pistolwar enabled! Type !allweapons to disable.\"\n")
				for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
					et.G_Damage(j, 80, 1022, 1000, 8, 34)
				end
			end
		end
		if args_table[1] == "!allweapons" then
			if mapname ~= "rifletennis_te" and mapname ~= "basket_panzer" and mapname ~= "ctf-face-fp1" and mapname ~= "puzzlemap" then
				pistolwar_flag = false
				panzerwar_flag = false
				et.trap_SendServerCommand(-1, "chat \"^1All weapons enabled!\"\n")
			end
		end
	end
	return(0)
end

function et_ClientSpawn(clientNum,revived)
	if panzerwar_flag == true then
		if et.gentity_get(clientNum,"sess.latchPlayerType") ~= 0 then
			et.gentity_set(clientNum,"sess.latchPlayerType", 0)
			et.gentity_set(clientNum, "sess.latchPlayerWeapon", 5)
			et.G_Damage(clientNum, 80, 1022, 1000, 8, 34)
		else
			for i=1,(et.MAX_WEAPONS-1),1 do
				if not panzerwar[i] then
					et.gentity_set(clientNum,"ps.ammoclip",i,0)
					et.gentity_set(clientNum,"ps.ammo",i,0)
				else
					et.gentity_set(clientNum,"ps.ammoclip",i,100)
				end
			end
		end
	end
	if riflewar_flag == true then
		for i=1,(et.MAX_WEAPONS-1),1 do
			if not riflewar[i] then
				et.gentity_set(clientNum,"ps.ammoclip",i,0)
				et.gentity_set(clientNum,"ps.ammo",i,0)
			else
				if i == 4 or i == 9 then
					et.gentity_set(clientNum,"ps.ammoclip",i,100)
				else
					et.gentity_set(clientNum,"ps.ammo",i,100)
				end
			end
		end
	end
	if pistolwar_flag == true then
		if et.gentity_get(clientNum,"sess.latchPlayerType") ~= 1 then
			et.gentity_set(clientNum,"sess.latchPlayerType", 1)
			et.G_Damage(clientNum, 80, 1022, 1000, 8, 34)
		else
			for i=1,(et.MAX_WEAPONS-1),1 do
				if not pistolwar[i] then
					et.gentity_set(clientNum,"ps.ammoclip",i,0)
					et.gentity_set(clientNum,"ps.ammo",i,0)
				else
					et.gentity_set(clientNum,"ps.ammo",i,104)
				end
			end
		end
	end
	if sniperwar_flag == true then
		if et.gentity_get(clientNum,"sess.latchPlayerType") ~= 4 then
			et.gentity_set(clientNum,"sess.latchPlayerType", 4)
			local team = tonumber(et.gentity_get(clientNum, "sess.sessionTeam"))
			if team == 1 then
				et.gentity_set(clientNum, "sess.latchPlayerWeapon", 32)
			elseif team == 2 then
				et.gentity_set(clientNum, "sess.latchPlayerWeapon", 25)
			end
			et.G_Damage(clientNum, 80, 1022, 1000, 8, 34)
		else
			for i=1,(et.MAX_WEAPONS-1),1 do
				if not sniperwar[i] then
					et.gentity_set(clientNum,"ps.ammoclip",i,0)
					et.gentity_set(clientNum,"ps.ammo",i,0)
				else
					et.gentity_set(clientNum,"ps.ammo",i,120)
				end
			end
		end
	end
end
