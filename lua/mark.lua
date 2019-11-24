-- mark.lua by x0rnn
-- mark players internally as suspicious or whatever (only visible to shrubbot level 6+ players)
-- !mark id <reason>
-- !unmark id
-- !marked (lists all marked players on server)

shrubbot = "shrubbot.cfg"
filename = "marked_players.txt"
markedp = {}
marked = {}
admins = {}

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("mark.lua "..et.FindSelf())

	local fd, len = et.trap_FS_FOpenFile(shrubbot, et.FS_READ)
	if len > -1 then
		local content = et.trap_FS_Read(fd, len)
		for guid, level in string.gfind(content, "[Gg]uid%s*=%s*(%x+)%s*\n[Ll]evel\t%= (%d)") do
			if tonumber(level) >= 6 then
				admins[guid] = true
			end
		end
		content = nil
	end
	et.trap_FS_FCloseFile(fd)

	local fd, len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len > -1 then
		local content = et.trap_FS_Read(fd, len)
		for guid in string.gfind(content, "([%x]+)\t[^\n]+") do
			markedp[guid] = true
		end
		content = nil
	end
	et.trap_FS_FCloseFile(fd)
end

function readFile(filename)
	local fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len == -1 then
		et.G_Print("mark.lua: no " .. filename .. "\n")
		return(0)
	end
	local filestr = et.trap_FS_Read(fd, len)
	et.trap_FS_FCloseFile(fd)

	local guid, reason, by
	for guid, reason, by in string.gfind(filestr,"([%x]+)\t%/([^%/]+)%/\t([^\n]+)") do
		marked[guid] =
		{
			reason,
			by
		}
	end
end

function writeFile(marked)
	local fd, len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
	if len == -1 then
		et.G_Print("mark.lua: no " .. filename .. "\n")
		return(0)
	end
	table.foreach(marked,
		function (first, arr)
			local line = first .. "	/" .. table.concat(arr, "/	") .. "\n"
			count = et.trap_FS_Write(line, string.len(line), fd)
		end
	)
	et.trap_FS_FCloseFile(fd)
end

function et_ClientBegin(clientNum)
	local cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	if admins[cl_guid] == true then
		marked_cmd(clientNum, 0)
	end
	if markedp[cl_guid] == true then
		for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
			if et.gentity_get(i,"inuse") then
				local guid = et.Info_ValueForKey(et.trap_GetUserinfo(i), "cl_guid")
				if admins[guid] == true then
					local name = et.gentity_get(clientNum, "pers.netname")
					et.trap_SendServerCommand(i, "chat \"^1Attention! " .. name .. " ^7joined. Marked as ^3" .. marked[cl_guid][1] .. "^7 by: " .. marked[cl_guid][2] .. "\"\n")
				end
			end
		end
	end
end

function mark(id, guid, reason, by)
	readFile(filename)
	if next(marked) ~= nil then
		if type(marked[guid]) == "table" then
			et.trap_SendServerCommand(id, "chat \"Player already marked.\"\n")
		else
			fd,len = et.trap_FS_FOpenFile(filename, et.FS_APPEND)
			count = et.trap_FS_Write(guid .. "	/" .. reason .. "/	" .. by .. "\n", string.len(guid .. "	/" .. reason .. "/	" .. by .. "\n"), fd)
			et.trap_FS_FCloseFile(fd)
			et.trap_SendServerCommand(id, "chat \"Player marked.\"\n")
			markedp[guid] = true
		end
	else
		fd,len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
		count = et.trap_FS_Write(guid .. "	/" .. reason .. "/	" .. by .. "\n", string.len(guid .. "	/" .. reason .. "/	" .. by .. "\n"), fd)
		et.trap_FS_FCloseFile(fd)
		et.trap_SendServerCommand(id, "chat \"Player marked.\"\n")
	end
end

function unmark(id, guid)
	readFile(filename)
	if next(marked) ~= nil then
		if type(marked[guid]) == "table" then
			marked[guid] = nil
			writeFile(marked)
			et.trap_SendServerCommand(id, "chat \"Player unmarked.\"\n")
			markedp[guid] = nil
		else
			et.trap_SendServerCommand(id, "chat \"Player is not marked.\"\n")
		end
	else
		et.trap_SendServerCommand(id, "chat \"Player is not marked.\"\n")
	end
end

function marked_cmd(id, cmd)
	readFile(filename)
	if next(marked) ~= nil then
		local cnt = 0
		for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
			if et.gentity_get(i,"inuse") then
				local guid = et.Info_ValueForKey(et.trap_GetUserinfo(i), "cl_guid")
				if markedp[guid] == true then
					cnt = cnt + 1
					local name = et.gentity_get(i, "pers.netname")
					if cnt == 1 then
						et.trap_SendServerCommand(id, "chat \"^1Attention! ^7Marked players on server:\"\n")
					end
					et.trap_SendServerCommand(id, "chat \"" .. name .. ": ^3" .. marked[guid][1] .. "^7 by: " .. marked[guid][2] .. "\"\n")
				end
			end
		end
		if cnt == 0 then
			if cmd == 1 then
				et.trap_SendServerCommand(id, "chat \"No marked players.\"\n")
			end
		end
	else
		if cmd == 1 then
			et.trap_SendServerCommand(id, "chat \"No marked players.\"\n")
		end
	end
end

function et_ClientCommand(id, command)
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(id), "cl_guid")
	admin_flag = false
	if et.trap_Argv(0) == "say" then
		args = et.ConcatArgs(1)
		local args_table = {}
		local cnt = 0
		for i in string.gfind(args, "%S+") do
			table.insert(args_table, i)
			cnt = cnt + 1
		end
		if args_table[1] == "!mark" or args_table[1] == "!unmark" or args_table[1] == "!marked" then
			fd,len = et.trap_FS_FOpenFile(shrubbot, et.FS_READ)
			if len ~= -1 then
				filestr = et.trap_FS_Read(fd, len)
				et.trap_FS_FCloseFile(fd)
				for v in string.gfind(filestr, cl_guid .. "\nlevel\t%= ([^\n]+)") do
					if tonumber(v) >= 6 then
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
				if args_table[1] == "!mark" then
					if cnt < 3 then
						et.trap_SendServerCommand(id, "chat \"Usage: ^7!mark ^3id <reason>\"\n")
					else
						local cno = tonumber(args_table[2])
						if cno then
							reason = et.ConcatArgs(3)
							if et.gentity_get(cno, "pers.connected") == 2 then
								mark(id, et.Info_ValueForKey(et.trap_GetUserinfo(cno), "cl_guid"), reason, et.gentity_get(id, "pers.netname"))
							else
								et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
							end
						else
							et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
						end
					end
					return 1
				elseif args_table[1] == "!unmark" then
					if cnt == 2 then
						local cno = tonumber(args_table[2])
						if cno then
							if et.gentity_get(cno, "pers.connected") == 2 then
								unmark(id, et.Info_ValueForKey(et.trap_GetUserinfo(cno), "cl_guid"))
							else
								et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
							end
						else
							et.trap_SendServerCommand(id, "chat \"^7Target not found.\"\n")
						end
						return 1
					else
						et.trap_SendServerCommand(id, "chat \"Usage: ^7!unmark ^3id\"\n")
					end
				elseif args_table[1] == "!marked" then
					marked_cmd(id, 1)
					return 1
				end
			else
				et.trap_SendServerCommand(id, "chat \"^7This command is not available to you.\"\n")
			end
		end
	end
	return(0)
end