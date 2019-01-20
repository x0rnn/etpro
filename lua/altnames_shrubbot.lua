-- altnames.lua by x0rnn, limited to players with level > x in shrubbot.cfg
-- saves all unique GUID and player name pairs to a text file
-- !altnames <clientNum> (in console, doesn't work in chat for some reason) will list all the names the player used on the server
-- modify etadmin_mod/bin/shrub_management.pl line 161 to:
-- if ( !defined($level) || $level < -1000 || !$guid || ( !$name && $level != 0 ) || length($guid) != 32 )

filename = "altnames.log"
shrubbot = "shrubbot.cfg"

replacements = {
["-"] = "%-",
["+"] = "%+",
["="] = "%=",
["<"] = "%<",
[">"] = "%>",
["?"] = "%?",
["*"] = "%*",
["("] = "%(",
[")"] = "%)",
["["] = "%[",
["]"] = "%]",
["_"] = "%_"
}

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("altnames.lua "..et.FindSelf())
end

function et_ClientBegin(clientNum)
	flag = false
	clean_name = et.Q_CleanStr(et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "name"))
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len ~= -1 then
		filestr = et.trap_FS_Read(fd, len)
		clean_name2 = string.gsub(clean_name, "[-+=<>?*[%]()_]", function(str) return replacements[str] end)
		for v in string.gfind(filestr, cl_guid .. "\t" .. clean_name2 .. "\n") do
			if v == cl_guid .. "\t" .. clean_name .."\n" then
				flag = true
				break
			end
		end
		if flag == false then
			fd,len = et.trap_FS_FOpenFile(filename, et.FS_APPEND)
			count = et.trap_FS_Write(cl_guid .. "	" .. clean_name .. "\n", string.len(cl_guid .. "	" .. clean_name .. "\n"), fd)
		end
		filestr = nil
		et.trap_FS_FCloseFile(fd)
	else
		et.trap_FS_FCloseFile(fd)
		fd,len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
		count = et.trap_FS_Write(cl_guid .. "	" .. clean_name .. "\n", string.len(cl_guid .. "	" .. clean_name .. "\n"), fd)
		et.trap_FS_FCloseFile(fd)
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
					for v in string.gfind(filestr, guid .. "\nlevel\t%= ([^\n])") do
						if tonumber(v) >= 4 then -- level 4+ (Deputy+)
							admin_flag = true
							break
						end
					end
					filestr = nil
				else
					et.trap_FS_FCloseFile(fd)
				end
				if admin_flag == true then
					cno = tonumber(string.sub(et.trap_Argv(2), 11, 12))
					if cno then
						if et.gentity_get(cno, "pers.connected") == 2 then
							flag2 = true
						else
							et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
						end
					else
						et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
					end
				else
					et.trap_SendServerCommand(id, "chat \"^7This command is not available to you.\"\n")
				end
			end
		else
			if et.trap_Argv(1) == "!altnames" then
				fd,len = et.trap_FS_FOpenFile(shrubbot, et.FS_READ)
				if len ~= -1 then
					filestr = et.trap_FS_Read(fd, len)
					et.trap_FS_FCloseFile(fd)
					for v in string.gfind(filestr, guid .. "\nlevel\t%= ([^\n])") do
						if tonumber(v) >= 4 then -- level 4+ (Deputy+)
							admin_flag = true
							break
						end
					end
					filestr = nil
				else
					et.trap_FS_FCloseFile(fd)
				end
				if admin_flag == true then
					if et.trap_Argc() ~= 3 then
						et.trap_SendServerCommand(id, "chat \"Usage: ^7!altnames <^3clientNum^7> (in console)\"\n")
					else
						cno = tonumber(et.trap_Argv(2))
						if cno then
							if et.gentity_get(cno, "pers.connected") == 2 then
								flag2 = true
							else
								et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
							end
						else
							et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
						end
					end
				else
					et.trap_SendServerCommand(id, "chat \"^7This command is not available to you.\"\n")
				end
			end
		end
		if flag2 == true then
			cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(cno), "cl_guid")
			fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
			if len ~= -1 then
				filestr = et.trap_FS_Read(fd, len)
				et.trap_FS_FCloseFile(fd)
				i = 1
				player_name_tbl = {}
				for v in string.gfind(filestr, cl_guid .. "\t([^\n]+)") do
					if player_name_tbl[i] == nil then
						player_name_tbl[i] = v
					else
						if string.len(player_name_tbl[i] .. "^j, ^7" ..v) <= 256 then
							player_name_tbl[i] = player_name_tbl[i] .. "^j, ^7" .. v
						else
							i = i + 1
							player_name_tbl[i] = v
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
				filestr = nil
			else
				et.trap_SendServerCommand(id, "chat \"^7" .. filename .. " ^7not found.\"\n")
			end
		end
	end
	return(0)
end
