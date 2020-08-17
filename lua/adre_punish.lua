-- punish medics trying to use adrenaline (1hp, 1 bullet, explode, etc.)

adre_max = 1 -- 0
punish_break = 2000	-- 30000 = 30 seconds; wait at least 30 seconds before punishing again; overall
punish_break_cl = 3000	-- 30000 = 30 seconds; wait at least 30 seconds before punishing again; per client
punish_ratio = 100	-- 50 = 50%
announce_pos = "b 16"
announce = -1	-- -1 = all OR id = private ... nothing else ...

sv_maxclients = tonumber(et.trap_Cvar_Get("sv_maxclients"))
medic_table = {}
PunishQueue = {}
last_punish = 0
last_punish_cl = {}
last_use = {}
adre_count = {}
origin = {}
et.CS_PLAYERS = 689

function et.G_Printf(...)
       et.G_Print(string.format(unpack(arg)))
end

function punish(id)
	last_use[id] = et.trap_Milliseconds() + 6000

	if not adre_count[id] then
		adre_count[id] = 1
	else
		adre_count[id] = adre_count[id] + 1
	end

	if last_punish > et.trap_Milliseconds() then
		return
	end

	if last_punish_cl[id] > et.trap_Milliseconds() then
		return
	end

	if adre_count[id] >= adre_max then
		math.randomseed(et.trap_Milliseconds())

		if math.random(1, 100) <= punish_ratio then

			last_punish_cl[id] = et.trap_Milliseconds() + punish_break_cl
            last_punish = et.trap_Milliseconds() + punish_break

            local msg = ""

            if adre_count[id] == 1 then
            	local choice = math.random(1, 2)
            	if choice == 1 then
                	msg = string.format("%s \"^7%s ^gshoots his first heroin tonite...^7\"",
                		announce_pos, playerName(id))
                else
                    msg = string.format("%s \"^gAdrenaline? ... ^7%s ... ^gBe smart, don't start!^7\"",
                    	announce_pos, playerName(id))
                end
            else
				local choice = math.random(1, 60)
				--choice =
                if choice == 1 then
                	msg = string.format("c %s \"^gThis Is SPARTA!!!!^7\"", id)

                elseif choice == 2 then
                    -- c prints Message as a global chat message on behalf of the client specified by ClientNum.
                    msg = string.format("c %s \"^gDamn i could use some good hit atm!^7\"", id)
                    
                elseif choice == 3 then
                    msg = string.format("%s \"^gHey ^7%s ^gshare the good stuff!^7\"",
                    	announce_pos, playerName(id))
                    et.gentity_set(id, "ps.powerups", 12, 0)
                    et.gentity_set(id, "health", 1)               	
                elseif choice == 4 then
                    msg = string.format("c %s \"^g...and If I were the last junkie on earth...^7\"",
                        id)
                    et.gentity_set(id,"ps.ammoclip",8,1)
                    et.gentity_set(id,"ps.ammo",8,0)
                    et.gentity_set(id,"ps.ammoclip",3,1)
                    et.gentity_set(id,"ps.ammo",3,0)	                    
                elseif choice == 5 then
                    msg = string.format("%s \"^gCops kick down ^7%s^g's door, arrested for possesion!^7\"",
                    	announce_pos, playerName(id))
                    	et.gentity_set(id, "ps.powerups", 12, 0)

                elseif choice > 5 and choice < 11 then
                    msg = string.format("%s \"^gChoose life, ^7%s, ^gCHOOSE LIFE!^7\"",
                    	announce_pos, playerName(id))
                    et.gentity_set(id, "ps.powerups", 12, 0)
                    et.gentity_set(id, "health", 1)
                elseif choice > 10 and choice < 16 then
                    msg = string.format("c %s \"^gWatch out!! I'm shooting drugs!^7\"",
                        id)
                    et.gentity_set(id, "ps.powerups", 12, 0)
                    et.gentity_set(id, "health", 1)
                elseif choice > 15 and choice < 21 then
                    msg = string.format("%s \"^7%s ^gbought some impure H, nothing happens.^7\"",
                        announce_pos, playerName(id))
                    et.gentity_set(id, "ps.powerups", 12, 0)
                    et.gentity_set(id,"ps.ammoclip",8,1)
                    et.gentity_set(id,"ps.ammo",8,0)
                    et.gentity_set(id,"ps.ammoclip",3,1)
                    et.gentity_set(id,"ps.ammo",3,0)                    
                elseif choice > 20 and choice < 26 then
                    msg = string.format("%s \"^7%s^g's dealer is out of supply.^7\"",
                        announce_pos, playerName(id))
                    et.gentity_set(id, "ps.powerups", 12, 0)
                    et.gentity_set(id, "health", 1)
                    et.gentity_set(id,"ps.ammoclip",8,1)
                    et.gentity_set(id,"ps.ammo",8,0)
                    et.gentity_set(id,"ps.ammoclip",3,1)
                    et.gentity_set(id,"ps.ammo",3,0)                    
                elseif choice > 25 and choice < 28 then
                    msg = string.format("%s \"^gDruggy m8's turn up and nick ^7%s^g's supply.^7\"",
                        announce_pos, playerName(id))
                    et.gentity_set(id, "ps.powerups", 12, 0)
                elseif choice == 28 then
                    msg = string.format("%s \"^gDruggy m8's turn up and share ^7%s^g's supply.^7\"",
                        announce_pos, playerName(id))
                    et.gentity_set(id, "ps.powerups", 12, 0)
                    et.gentity_set(id, "health", 1)
                elseif choice > 28 and choice < 40 then
                    msg = string.format("%s \"^7%s^g^'s dealer is out of supply.^7\"",
                        announce_pos, playerName(id))
                    et.gentity_set(id, "ps.powerups", 12, 0)
                    et.gentity_set(id,"ps.ammoclip",8,1)
                    et.gentity_set(id,"ps.ammo",8,0)
                    et.gentity_set(id,"ps.ammoclip",3,1)
                    et.gentity_set(id,"ps.ammo",3,0) 
                elseif choice > 39 and choice < 51 then --i luv it
                    msg = string.format("c %s \"^1Allahu akbar!^7\"",
                        id)
                    et.G_Damage( id, 80, 1022, 667, 8, 34 )
                    et.G_AddEvent( id, 84, 1) --boooOOooom

            	elseif choice == 51 then
                    msg = string.format("%s \"^7%s ^gis a real heroine whore. ^f(^1%d ^gbangs in a row^f)^7\"",
                        announce_pos, playerName(id), adre_count[id])
                    et.gentity_set(id, "ps.powerups", 12, 0)
                elseif choice > 50 and choice < 56 then
                    msg = string.format("%s \"^7%s ^gthe spoon burner. ^f(^1%d ^gbangs in a row^f)^7\"",
                        announce_pos, playerName(id), adre_count[id])
                    et.gentity_set(id,"ps.ammoclip",8,1)
                    et.gentity_set(id,"ps.ammo",8,0)
                    et.gentity_set(id,"ps.ammoclip",3,1)
                    et.gentity_set(id,"ps.ammo",3,0)                    
                elseif choice > 55 and choice < 61 then
                    msg = string.format("%s \"^nNOW PLAYING: ^0Michael Jackson & ^7%s ^7- ^rIn the closet ^7- ^n(^rLive At Neverland^n)^7\"",
                        announce_pos, playerName(id))
                    et.gentity_set(id, "ps.powerups", 12, 0)
                    et.gentity_set(id, "health", 1)                    
                end
            end

            et.trap_SendServerCommand(announce, msg)
            --et.gentity_set(id, "ps.powerups", 12, 0)
            --et.G_AddEvent( ent, event, eventparm' )
        end
	end
end

function et_RunFrame( levelTime )

	if math.mod(levelTime, 430) ~= 0 then return end

--[[
	table.foreach(PunishQueue,
        function(i, pqueue)
        	if pqueue[1] < et.trap_Milliseconds() then
            	table.remove(PunishQueue, 1)
            end
            if pqueue[3] == 1 then
            	et.G_AddEvent( pqueue[2], 84, 4) --smoke
            elseif pqueue[3] == 2 then
				et.gentity_set(pqueue[2],"origin",origin)
            elseif pqueue[3] == 3 then
            	et.G_AddEvent( pqueue[2], 120, 0) --shake it
            end
        end
	)
--]]

	table.foreach(medic_table,
        function(idx, clientNum)
        	if last_use[clientNum] < et.trap_Milliseconds() then
                if et.gentity_get(clientNum, "ps.powerups", 12 ) > 0 then
                   punish(clientNum)
                end
			end

        end
	)

end

function playerName(id)
    local name = et.Info_ValueForKey(et.trap_GetUserinfo(id), "name")
    if name == nil or name == "" then
        return "*unknown*"
    end
    return name
end

function et_ClientSpawn( id, revived )
	if revived == 1 then
		return
	end

    local cs = et.trap_GetConfigstring(et.CS_PLAYERS + id)
    if et.Info_ValueForKey(cs, "c") == "1" then
    	local skillz = et.Info_ValueForKey(cs, "s")
    	if string.sub (skillz, 3, 3) == "4" then
            if not is_medic(id) then
                last_use[id] = 0
                last_punish_cl[id] = 0
                table.insert(medic_table, id)
        	end
    	end
    else
        if is_medic(id) then
        	last_use[id] = nil
        	last_punish_cl[id] = nil
            table.remove(medic_table, is_medic(id))
        end
    end
end

function is_medic(id)
    local found =  table.foreach(medic_table,
        function(idx, clientNum)
            if clientNum == id then
            	return idx
            end

        end
    )
    if found then
    	return found
    else
    	return nil
    end
end

function et_ConsoleCommand()

	if et.trap_Argv(0) == "adre_table" then
		et.G_Printf("----------adre_table-----------\n")
        table.foreach(medic_table,
            function(idx, clientNum)
            	if adre_count[clientNum] then
				et.G_Printf("slot %d = %d hits\n", clientNum, adre_count[clientNum])
				else
					et.G_Printf("slot %d = 0 hits\n", clientNum)
				end
            end
        )
        et.G_Printf("-------------------------------\n")
    	return 1
	end

	return 0
end
