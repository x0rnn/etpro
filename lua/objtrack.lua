-- objtrack.lua by x0rnn, tracks who stole and secured objectives

mapname = ""
goldcarriers = {}
goldcarriers_id = {}
doccarriers = {}
doccarriers_id = {}
objcarriers = {}
objcarriers_id = {}
second_obj = false
eastflag = false
westflag = false

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("objtrack.lua "..et.FindSelf())

	mapname = string.lower(et.trap_Cvar_Get("mapname"))
end

function et_Print(text)
	if mapname == "radar" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			objcarriers[id] = true
			table.insert(objcarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			if eastflag == true then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the West Radar Parts!\"\n")
			elseif westflag == true then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the East Radar Parts!\"\n")
			else
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole a Radar Part!\"\n")
			end
		end
		if(string.find(text, "Allies have secured the East")) then
			local x = 1
			for index in pairs(objcarriers_id) do
				if objcarriers[objcarriers_id[x]] == true then
					local redflag = et.gentity_get(objcarriers_id[x], "ps.powerups", 6)
					if redflag == 0 then
						local name = et.gentity_get(objcarriers_id[x], "pers.netname")
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the East Radar Parts!\"\n")
						objcarriers[objcarriers_id[x]] = nil
						table.remove(objcarriers_id, x)
					end
				end
				x = x + 1
			end
			eastflag = true
		end
		if(string.find(text, "Allies have secured the West")) then
			local x = 1
			for index in pairs(objcarriers_id) do
				if objcarriers[objcarriers_id[x]] == true then
					local redflag = et.gentity_get(objcarriers_id[x], "ps.powerups", 6)
					if redflag == 0 then
						local name = et.gentity_get(objcarriers_id[x], "pers.netname")
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the West Radar Parts!\"\n")
						objcarriers[objcarriers_id[x]] = nil
						table.remove(objcarriers_id, x)
					end
				end
				x = x + 1
			end
			westflag = true
		end
	end -- end radar

	if mapname == "goldrush" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			goldcarriers[id] = true
			table.insert(goldcarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			if table.getn(goldcarriers_id) == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the first Gold Crate!\"\n")
			elseif table.getn(goldcarriers_id) == 2 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the second Gold Crate!\"\n")
			end
		end
		if(string.find(text, "Allied team has secured the first Gold Crate")) then
			local x = 1
			for index in pairs(goldcarriers_id) do
				if goldcarriers[goldcarriers_id[x]] == true then
					local redflag = et.gentity_get(goldcarriers_id[x], "ps.powerups", 6)
					if redflag == 0 then
						local name = et.gentity_get(goldcarriers_id[x], "pers.netname")
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the first Gold Crate!\"\n")
						goldcarriers[goldcarriers_id[x]] = nil
						table.remove(goldcarriers_id, x)
					end
				end
				x = x + 1
			end
		end
		if(string.find(text, "Allied team has secured the second Gold Crate")) then
			local name = et.gentity_get(goldcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the second Gold Crate!\"\n")
			goldcarriers[goldcarriers_id[1]] = nil
			table.remove(goldcarriers_id, 1)
		end
	end -- end goldrush

	if mapname == "uje_goldrush" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			goldcarriers[id] = true
			table.insert(goldcarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			if table.getn(goldcarriers_id) == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the first Gold Crate!\"\n")
			elseif table.getn(goldcarriers_id) == 2 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the second Gold Crate!\"\n")
			end
		end
		if(string.find(text, "Allied team has secured the first Gold Crate")) then
			local x = 1
			for index in pairs(goldcarriers_id) do
				if goldcarriers[goldcarriers_id[x]] == true then
					local redflag = et.gentity_get(goldcarriers_id[x], "ps.powerups", 6)
					if redflag == 0 then
						local name = et.gentity_get(goldcarriers_id[x], "pers.netname")
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the first Gold Crate!\"\n")
						goldcarriers[goldcarriers_id[x]] = nil
						table.remove(goldcarriers_id, x)
					end
				end
				x = x + 1
			end
		end
		if(string.find(text, "Allied team has secured the second Gold Crate")) then
			local name = et.gentity_get(goldcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the second Gold Crate!\"\n")
			goldcarriers[goldcarriers_id[1]] = nil
			table.remove(goldcarriers_id, 1)
		end
	end -- end uje_goldrush

	if mapname == "frostbite" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			doccarriers[id] = true
			table.insert(doccarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			if second_obj == false then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Supply Documents!\"\n")
			else
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Deciphered Supply Documents!\"\n")
			end
		end
		if(string.find(text, "The Allies have transmitted the Supply")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Supply Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
			second_obj = true
		end
		if(string.find(text, "The Allies have transmitted the Deciphered")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Deciphered Supply Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
		end
	end -- end frostbite

	if mapname == "missile_b3" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			objcarriers[id] = true
			table.insert(objcarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			if second_obj == false then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Gate Power Supply!\"\n")
			else
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Rocket Control!\"\n")
			end
		end
		if(string.find(text, "Allies have transported the Power")) then
			local name = et.gentity_get(objcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Gate Power Supply!\"\n")
			objcarriers[objcarriers_id[1]] = nil
			table.remove(objcarriers_id, 1)
			second_obj = true
		end
		if(string.find(text, "Allies have transported the Rocket")) then
			local name = et.gentity_get(objcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Rocket Control!\"\n")
			objcarriers[objcarriers_id[1]] = nil
			table.remove(objcarriers_id, 1)
		end
	end -- end missile_b3

	if mapname == "sp_delivery_te" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			goldcarriers[id] = true
			table.insert(goldcarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole a Gold Crate!\"\n")
		end
		if(string.find(text, "The Allies have secured a gold crate")) then
			local x = 1
			for index in pairs(goldcarriers_id) do
				if goldcarriers[goldcarriers_id[x]] == true then
					local redflag = et.gentity_get(goldcarriers_id[x], "ps.powerups", 6)
					if redflag == 0 then
						local name = et.gentity_get(goldcarriers_id[x], "pers.netname")
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured a Gold Crate!\"\n")
						goldcarriers[goldcarriers_id[x]] = nil
						table.remove(goldcarriers_id, x)
					end
				end
				x = x + 1
			end
		end
	end -- end sp_delivery_te

	if mapname == "sw_goldrush_te" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			goldcarriers[id] = true
			table.insert(goldcarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Gold Bars!\"\n")
		end
		if(string.find(text, "Allied team is escaping with the Gold")) then
			local name = et.gentity_get(goldcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Gold Bars!\"\n")
			goldcarriers[goldcarriers_id[1]] = nil
			table.remove(goldcarriers_id, 1)
		end
	end -- end sw_goldrush_te

	if mapname == "bremen_b3" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			objcarriers[id] = true
			table.insert(objcarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Keycard!\"\n")
		end
		if(string.find(text, "The Allies have captured the keycard")) then
			local name = et.gentity_get(objcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Keycard!\"\n")
			objcarriers[objcarriers_id[1]] = nil
			table.remove(objcarriers_id, 1)
		end
	end -- end bremen_b3

	if mapname == "adlernest" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			doccarriers[id] = true
			table.insert(doccarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Documents!\"\n")
		end
		if(string.find(text, "Allied team has transmitted the documents")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
		end
	end -- end adlernest

	if mapname == "et_beach" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			doccarriers[id] = true
			table.insert(doccarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the War Documents!\"\n")
		end
		if(string.find(text, "Allied team transmit the War Documents")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the War Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
		end
	end -- end et_beach

	if mapname == "venice" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			objcarriers[id] = true
			table.insert(objcarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Relic!\"\n")
		end
		if(string.find(text, "Allied team has secured the Relic")) then
			local name = et.gentity_get(objcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Relic!\"\n")
			objcarriers[objcarriers_id[1]] = nil
			table.remove(objcarriers_id, 1)
		end
	end -- end venice

	if mapname == "library_b3" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			doccarriers[id] = true
			table.insert(doccarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Secret Documents!\"\n")
		end
		if(string.find(text, "The Allies have sent the secret docs")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Secret Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
		end
	end -- end library_b3

	if mapname == "pirates" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			goldcarriers[id] = true
			table.insert(goldcarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			if table.getn(goldcarriers_id) == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the first Gold Crate!\"\n")
			elseif table.getn(goldcarriers_id) == 2 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the second Gold Crate!\"\n")
			end
		end
		if(string.find(text, "Allied team has secured the first Gold Crate")) then
			local x = 1
			for index in pairs(goldcarriers_id) do
				if goldcarriers[goldcarriers_id[x]] == true then
					local redflag = et.gentity_get(goldcarriers_id[x], "ps.powerups", 6)
					if redflag == 0 then
						local name = et.gentity_get(goldcarriers_id[x], "pers.netname")
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the first Gold Crate!\"\n")
						goldcarriers[goldcarriers_id[x]] = nil
						table.remove(goldcarriers_id, x)
					end
				end
				x = x + 1
			end
		end
		if(string.find(text, "Allied team has secured the second Gold Crate")) then
			local name = et.gentity_get(goldcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the second Gold Crate!\"\n")
			goldcarriers[goldcarriers_id[1]] = nil
			table.remove(goldcarriers_id, 1)
		end
	end -- end pirates

	if mapname == "karsiah_te2" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			objcarriers[id] = true
			table.insert(objcarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			if eastflag == true then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the South Documents!\"\n")
			elseif westflag == true then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the North Documents!\"\n")
			else
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole a stack of Documents!\"\n")
			end
		end
		if(string.find(text, "Allies have transmitted the North Documents")) then
			local x = 1
			for index in pairs(objcarriers_id) do
				if objcarriers[objcarriers_id[x]] == true then
					local redflag = et.gentity_get(objcarriers_id[x], "ps.powerups", 6)
					if redflag == 0 then
						local name = et.gentity_get(objcarriers_id[x], "pers.netname")
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the North Documents!\"\n")
						objcarriers[objcarriers_id[x]] = nil
						table.remove(objcarriers_id, x)
					end
				end
				x = x + 1
			end
			eastflag = true
		end
		if(string.find(text, "Allies have transmitted the South Documents")) then
			local x = 1
			for index in pairs(objcarriers_id) do
				if objcarriers[objcarriers_id[x]] == true then
					local redflag = et.gentity_get(objcarriers_id[x], "ps.powerups", 6)
					if redflag == 0 then
						local name = et.gentity_get(objcarriers_id[x], "pers.netname")
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the South Documents!\"\n")
						objcarriers[objcarriers_id[x]] = nil
						table.remove(objcarriers_id, x)
					end
				end
				x = x + 1
			end
			westflag = true
		end
	end -- end karsiah_te2

	if mapname == "et_ufo_final" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			doccarriers[id] = true
			table.insert(doccarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the UFO Documents!\"\n")
		end
		if(string.find(text, "Allies Transmitted the UFO Documents")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the UFO Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
		end
	end -- end et_ufo_final

	if mapname == "et_ice" then
		if(string.find(text, "team_CTF_blueflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			doccarriers[id] = true
			table.insert(doccarriers_id, id)
			local name = et.gentity_get(id, "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Secret War Documents!\"\n")
		end
		if(string.find(text, "The Axis team has transmited the Secret")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Secret War Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
		end
	end -- end et_ice
end

function et_Obituary(victim, killer, mod)
	if mapname == "radar" then
		objcarriers[victim] = nil
		local x = 1
		for index in pairs(objcarriers_id) do
			if objcarriers_id[x] == victim then
				table.remove(objcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "goldrush" then
		goldcarriers[victim] = nil
		local x = 1
		for index in pairs(goldcarriers_id) do
			if goldcarriers_id[x] == victim then
				table.remove(goldcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "uje_goldrush" then
		goldcarriers[victim] = nil
		local x = 1
		for index in pairs(goldcarriers_id) do
			if goldcarriers_id[x] == victim then
				table.remove(goldcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "frostbite" then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "missile_b3" then
		objcarriers[victim] = nil
		if objcarriers_id[1] == victim then
			table.remove(objcarriers_id, 1)
		end
	end
	if mapname == "sp_delivery_te" then
		goldcarriers[victim] = nil
		local x = 1
		for index in pairs(goldcarriers_id) do
			if goldcarriers_id[x] == victim then
				table.remove(goldcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "sw_goldrush_te" then
		goldcarriers[victim] = nil
		if goldcarriers_id[1] == victim then
			table.remove(goldcarriers_id, 1)
		end
	end
	if mapname == "bremen_b3" then
		objcarriers[victim] = nil
		if objcarriers_id[1] == victim then
			table.remove(objcarriers_id, 1)
		end
	end
	if mapname == "adlernest" then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "et_beach" then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "venice" then
		objcarriers[victim] = nil
		if objcarriers_id[1] == victim then
			table.remove(objcarriers_id, 1)
		end
	end
	if mapname == "library_b3" then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "pirates" then
		goldcarriers[victim] = nil
		local x = 1
		for index in pairs(goldcarriers_id) do
			if goldcarriers_id[x] == victim then
				table.remove(goldcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "karsiah_te2" then
		objcarriers[victim] = nil
		local x = 1
		for index in pairs(objcarriers_id) do
			if objcarriers_id[x] == victim then
				table.remove(objcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "et_ufo_final" then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "et_ice" then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
end

function et_ClientDisconnect(i)
	if mapname == "radar" then
		objcarriers[i] = nil
		local x = 1
		for index in pairs(objcarriers_id) do
			if objcarriers_id[x] == victim then
				table.remove(objcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "goldrush" then
		goldcarriers[i] = nil
		local x = 1
		for index in pairs(goldcarriers_id) do
			if goldcarriers_id[x] == i then
				table.remove(goldcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "uje_goldrush" then
		goldcarriers[i] = nil
		local x = 1
		for index in pairs(goldcarriers_id) do
			if goldcarriers_id[x] == i then
				table.remove(goldcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "frostbite" then
		doccarriers[i] = nil
		if doccarriers_id[1] == i then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "missile_b3" then
		objcarriers[i] = nil
		if objcarriers_id[1] == i then
			table.remove(objcarriers_id, 1)
		end
	end
	if mapname == "sp_delivery_te" then
		goldcarriers[i] = nil
		local x = 1
		for index in pairs(goldcarriers_id) do
			if goldcarriers_id[x] == i then
				table.remove(goldcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "sw_goldrush_te" then
		goldcarriers[i] = nil
		if goldcarriers_id[1] == i then
			table.remove(goldcarriers_id, 1)
		end
	end
	if mapname == "bremen_b3" then
		objcarriers[i] = nil
		if objcarriers_id[1] == i then
			table.remove(objcarriers_id, 1)
		end
	end
	if mapname == "adlernest" then
		doccarriers[i] = nil
		if doccarriers_id[1] == i then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "et_beach" then
		doccarriers[i] = nil
		if doccarriers_id[1] == i then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "venice" then
		objcarriers[victim] = nil
		if objcarriers_id[1] == victim then
			table.remove(objcarriers_id, 1)
		end
	end
	if mapname == "library_b3" then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "pirates" then
		goldcarriers[victim] = nil
		local x = 1
		for index in pairs(goldcarriers_id) do
			if goldcarriers_id[x] == victim then
				table.remove(goldcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "karsiah_te2" then
		objcarriers[victim] = nil
		local x = 1
		for index in pairs(objcarriers_id) do
			if objcarriers_id[x] == victim then
				table.remove(objcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "et_ufo_final" then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "et_ice" then
		doccarriers[i] = nil
		if doccarriers_id[1] == i then
			table.remove(doccarriers_id, 1)
		end
	end
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
    return(0)
end
