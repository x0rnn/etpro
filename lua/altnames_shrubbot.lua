-- altnames.lua by x0rnn, limited to players with level > x in shrubbot.cfg
-- saves all unique GUID and player name pairs to a text file
-- !altnames <clientNum> will list all the names the player used on the server

-- modify etadmin_mod/bin/shrub_management.pl line 161 to:
-- if ( !defined($level) || $level < -1000 || !$guid || ( !$name && $level != 0 ) || length($guid) != 32 )
-- you have to symlink /etadmin_mod/etc/shrubbot.cfg to etpro folder

filename = "altnames.log"
shrubbot = "shrubbot.cfg"
names_table = {}

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("altnames.lua "..et.FindSelf())
	local fd, len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len > -1 then
		local filestr = et.trap_FS_Read(fd, len)
		for v in string.gfind(filestr, "([%x]+\t[^\n]+)") do
			table.insert(names_table, v)
		end
		filestr = nil
		et.trap_FS_FCloseFile(fd)
	else
		et.G_Print("altnames.lua: no altnames.log\n")
	end
end

function inSlot( PartName )
  local x=0
  local j=1
  local size=tonumber(et.trap_Cvar_Get("sv_maxclients"))     --get the serversize
  local matches = {}
  while (x<size) do
    found = string.find(string.lower(et.Q_CleanStr( et.Info_ValueForKey( et.trap_GetUserinfo( x ), "name" ) )),string.lower(PartName))
    if(found~=nil) then
        matches[j]=x
        j=j+1
    end
    x=x+1
  end
  if (table.getn(matches)~=nil) then
    x=1
    while (x<=table.getn(matches)) do
        matchingSlot = matches[x] 
      x=x+1
    end
    if table.getn(matches) == 0 then
      et.G_Print("You had no matches to that name.\n")
      matchingSlot = nil
    else
      if table.getn(matches) >= 2 then
        et.G_Print("Partial playername got more than 1 match\n")
        matchingSlot = nil
      end
    end
  end
  return matchingSlot
end

function et_ClientBegin(clientNum)
	clean_name = et.Q_CleanStr(et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "name"))
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")

	local function has_value (tab, val)
		for index, value in ipairs(tab) do
			if value == val then
				return true
			end
		end
		return false
	end

	if string.lower(clean_name) ~= "etplayer" then
		if string.len(cl_guid) == 32 then
			if next(names_table) ~= nil then
				if not has_value(names_table, cl_guid .. "	" .. clean_name) then
					fd,len = et.trap_FS_FOpenFile(filename, et.FS_APPEND)
					count = et.trap_FS_Write(cl_guid .. "	" .. clean_name .. "\n", string.len(cl_guid .. "	" .. clean_name .. "\n"), fd)
					et.trap_FS_FCloseFile(fd)
					table.insert(names_table, cl_guid .. "	" .. clean_name)
				end
			else
				fd,len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
				count = et.trap_FS_Write(cl_guid .. "	" .. clean_name .. "\n", string.len(cl_guid .. "	" .. clean_name .. "\n"), fd)
				et.trap_FS_FCloseFile(fd)
				table.insert(names_table, cl_guid .. "	" .. clean_name)
			end
		end
	end
end

function et_ClientCommand(id, command)
	flag2 = false
	admin_flag = false
	guid = et.Info_ValueForKey(et.trap_GetUserinfo(id), "cl_guid")
	if et.trap_Argv(0) == "say" or et.trap_Argv(0) == "say_team" or et.trap_Argv(0) == "say_buddy" or et.trap_Argv(0) == "m" or et.trap_Argv(0) == "pm" then
		if et.trap_Argv(0) == "m" or et.trap_Argv(0) == "pm" then
			if (string.sub(et.trap_Argv(2), 1, 10) == "!altnames ") then
				fd,len = et.trap_FS_FOpenFile(shrubbot, et.FS_READ)
				if len ~= -1 then
					filestr = et.trap_FS_Read(fd, len)
					et.trap_FS_FCloseFile(fd)
					for v in string.gfind(filestr, guid .. "\nlevel\t%= ([^\n]+)") do
						if tonumber(v) >= 4 then -- level 4+ (Deputy+)
							admin_flag = true
							break
						end
					end
					filestr = nil
				else
					et.trap_FS_FCloseFile(fd)
					et.trap_SendServerCommand(id, "chat \"^7shrubbot.cfg not found.\"\n")
				end
				if admin_flag == true then
					local chunks = {}
					for substr in string.gfind(et.trap_Argv(2), "%S+") do
						table.insert(chunks, substr)
					end
					cno = tonumber(chunks[2])
					if cno then
						if et.gentity_get(cno, "pers.connected") == 2 then
							flag2 = true
						else
							et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
						end
					else
						cno = inSlot(chunks[2])
						if cno ~= nil then
							flag2 = true
						else
							et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
						end
					end
				else
					et.trap_SendServerCommand(id, "chat \"^7This command is not available to you.\"\n")
				end
			end
		else
			args = et.ConcatArgs(1)
			local args_table = {}
			cnt = 0
			for i in string.gfind(args, "%S+") do
				table.insert(args_table, i)
				cnt = cnt + 1
			end
			if args_table[1] == "!altnames" then
				fd,len = et.trap_FS_FOpenFile(shrubbot, et.FS_READ)
				if len ~= -1 then
					filestr = et.trap_FS_Read(fd, len)
					et.trap_FS_FCloseFile(fd)
					for v in string.gfind(filestr, guid .. "\nlevel\t%= ([^\n]+)") do
						if tonumber(v) >= 4 then -- level 4+ (Deputy+)
							admin_flag = true
							break
						end
					end
					filestr = nil
				else
					et.trap_FS_FCloseFile(fd)
					et.trap_SendServerCommand(id, "chat \"^7shrubbot.cfg not found.\"\n")
				end
				if admin_flag == true then
					if cnt ~= 2 then
						et.trap_SendServerCommand(id, "chat \"Usage: ^7!altnames <^3PartOfName^7> or <^3clientNum^7>\"\n")
					else
						if string.len(args_table[2]) < 3 then
							cno = tonumber(args_table[2])
							if cno then
								if et.gentity_get(cno, "pers.connected") == 2 then
									flag2 = true
								else
									et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
									return 1
								end
							else
								et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
								return 1
							end
						else
							cno = inSlot(args_table[2])
							if cno ~= nil then
								flag2 = true
							else
								et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
								return 1
							end
						end
					end
				else
					et.trap_SendServerCommand(id, "chat \"^7This command is not available to you.\"\n")
				end
			end
		end
		if flag2 == true then
			cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(cno), "cl_guid")
			i = 1
			player_name_tbl = {}
			for key, value in pairs(names_table) do
				for v in string.gfind(value, cl_guid .. "\t([^\n]+)") do
					if player_name_tbl[i] == nil then
						player_name_tbl[i] = v
					else
						if string.len(player_name_tbl[i] .. "^j, ^7" .. v) <= 256 then
							player_name_tbl[i] = player_name_tbl[i] .. "^j, ^7" .. v
						else
							i = i + 1
							player_name_tbl[i] = v
						end
					end
				end
			end
			tbl_cnt = 0
			for index in pairs(player_name_tbl) do
				tbl_cnt = tbl_cnt + 1
			end
			for j = 1, tbl_cnt do
				et.trap_SendServerCommand(id, "chat \"" .. player_name_tbl[j] .. "\"")
			end
			et.G_LogPrint("say: " .. et.gentity_get(id, "pers.netname") .. ": !altnames " .. et.gentity_get(cno, "pers.netname") .. "\n")
			return 1
		end
	end
	return(0)
end
