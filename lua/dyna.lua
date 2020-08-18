---------------------------------
------- Dynamite counter --------
-------  By Necromancer  --------
-------    5/04/2009     --------
------- www.usef-et.org  --------
---------------------------------

SHOW = 2
-- 0 means disable
-- 1 means only the team that planted the dyno
-- 2 means everyone

-- This script can be freely used and modified as long as the original author\s are mentioned (and their homepage: www.usef-et.org)



-- Constans
COLOR = {}
COLOR.PLACE = '^8'
COLOR.TEXT = '^w'
COLOR.TIME = '^8' -- this constat is changing in the print_message() function

if et.trap_Cvar_Get("gamename") == "etpro" then
	CHAT = "b 8"
	POPUP = "etpro" 
else 
	CHAT = "chat" 
	POPUP = "etpub"
end


timer = {}

OLD = os.time()

function et_InitGame(levelTime, randomSeed, restart)
    et.RegisterModname("dyna.lua" .. et.FindSelf())
end

function et_RunFrame( levelTime )
	current = os.time()
	for dyno, temp in pairs(timer) do
		if timer[dyno]["time"] - current >= 0 then
			for key,temp in pairs(timer[dyno]) do
				if type(key) == "number" then
					if timer[dyno]["time"] - current == key then
						send_print(timer,dyno,key)
						timer[dyno][key] = nil	
						--et.G_LogPrint("dynamite key deleted: " .. dyno .." key: " .. key .. "\n")
					end
				end
			end

		else
			--et.G_LogPrint("dynamite out: " .. dyno .. "\n")
			place_destroyed(timer[dyno]["place"])
			--timer[dyno] = nil
		end
	end
end

function place_destroyed(place) -- removes any dynamties that were planted on this objective
	for dynamite, temp in pairs(timer) do
		if timer[dynamite]["place"] == place then
			timer[dynamite] = nil
		end
	end
end

function send_print(timer,dyno,ttime)
	if SHOW == 0 then return end
	if SHOW == 1 then
		for player=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1, 1 do
			if et.gentity_get(player,"sess.sessionTeam") == timer[dyno]["team"] then
				print_message(player, ttime, timer[dyno]["place"])
			end
		end
	else
		print_message(-1, ttime, timer[dyno]["place"])
	end
end

function print_message(slot, ttime, place)
	if ttime > 3 then
		COLOR.TIME = '^8'
	else
		COLOR.TIME = '^1'
	end

	if ttime == -1 then
		et.trap_SendServerCommand( slot , string.format('%s \"%s"\n',CHAT, COLOR.TEXT .. "Dynamite planted at " .. COLOR.PLACE .. place))
	elseif ttime == -2 then
		et.trap_SendServerCommand( slot , string.format('%s \"%s"\n',CHAT, COLOR.TEXT .. "Dynamite defused at " .. COLOR.PLACE .. place))
	elseif ttime > 0 then
		et.trap_SendServerCommand( slot , string.format('%s \"%s"\n',CHAT, COLOR.TEXT .. "Dynamite at " .. COLOR.PLACE .. place .. COLOR.TEXT .. " exploding in " .. COLOR.TIME ..ttime .. COLOR.TEXT .. " seconds!"))
	end
end

function et_Print( text )
	--etpro popup: axis planted "the Old City MG Nest"
	start,stop = string.find(text, POPUP .. " popup:",1,true) -- check that its not any player print, trying to manipulate the dyno counter
	if start and stop then
		
		start,stop,team,plant = string.find(text, POPUP .. " popup: (%S+) planted \"([^%\"]*)\"")
		if start and stop then -- dynamite planted
			if team == "axis" then team = 1 
			else team = 2 end
			index = table.getn(timer)+1
			timer[index] = {}
			timer[index]["team"] = team
			timer[index]["place"] = plant
			timer[index]["time"] = os.time() +30

			timer[index][20] = true
			timer[index][10] = true
			timer[index][5] = true
			timer[index][3] = true
			timer[index][2] = true
			timer[index][1] = true
			timer[index][0] = true

			print_message(-1, -1, timer[index]["place"])
			--et.G_LogPrint("dynamite set: " .. index .. "\n")
		end

		start,stop,team,plant = string.find(text, POPUP .. " popup: (%S+) defused \"([^%\"]*)\"")
		if start and stop then -- dynamite defused
			if team == "axis" then team = 1 
			else team = 2 end
			for index,temp in pairs(timer) do
				if timer[index]["place"] == plant then
					timer[index] = nil
					print_message(-1, -2, timer[index]["place"])
					--et.G_LogPrint("dynamite removed: " .. index .. "\n")
					return
				end
			end
		end
	end
end
