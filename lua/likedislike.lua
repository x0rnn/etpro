filename = "likedislike.log"
mapname = ""
results = {}

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("likedislike.lua "..et.FindSelf())
	mapname = et.trap_Cvar_Get("mapname")
end

function mapresults()
	fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len ~= -1 then
		filestr = et.trap_FS_Read(fd, len)
		et.trap_FS_FCloseFile(fd)
		like = 0
		hate = 0
		clean_mapname = string.gsub(mapname, "%-", "%%-")
		for m,v in string.gfind(filestr, "[%x]+\t(" .. clean_mapname .. ")\t([^\n]+)") do
			if v == "like" then
				like = like + 1
			elseif v == "hate" then
				hate = hate + 1
			end
		end
		if like == 0 and hate == 0 then
			et.trap_SendServerCommand(-1, "chat \"^7No opinions about ^3" .. mapname .. "^7 yet.\"\n")
		else
			et.trap_SendServerCommand(-1, "chat \"^3" .. mapname .. "^7: likes: ^2" .. like .. "^7, dislikes: ^1" .. hate .. "\"\n")
		end
	else
		et.G_Print("likedislike.lua: no likedislike.log\n")
		return(0)
	end
end

function readLog(filename)
	local fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len == -1 then
		et.G_Print("likedislike.lua: no likedislike.log\n")
		return(0)
	end
	local filestr = et.trap_FS_Read(fd, len)
	et.trap_FS_FCloseFile(fd)

	local guid_map, opinion
	for guid_map, opinion in string.gfind(filestr,"([%x]+\t[%_%-%w]+)\t([^\n]+)") do
		results[guid_map] =
		{
			opinion
		}
	end
end

function writeLog(results)
	local fd, len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
	if len == -1 then
		et.G_Print("likedislike.lua: no likedislike.log\n")
		return(0)
	end
	table.foreach(results,
		function (first, arr)
			local line = first .. "	".. table.concat(arr, "	").."\n"
			count = et.trap_FS_Write(line, string.len(line), fd)
		end
	)
	et.trap_FS_FCloseFile(fd)
end

function vote(id, choice)
	gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
	if gamestate ~= 1 and gamestate ~= 2 then
		cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(id), "cl_guid")
		name = et.Info_ValueForKey(et.trap_GetUserinfo(id), "name")
		readLog(filename)
		if next(results) ~= nil then
			if type(results[cl_guid .. "	" .. mapname]) ~= "table" then
				fd,len = et.trap_FS_FOpenFile(filename, et.FS_APPEND)
				if choice == "like" then
					count = et.trap_FS_Write(cl_guid .. "	" .. mapname .. "	like\n", string.len(cl_guid .. "	" .. mapname .. "	like\n"), fd)
					et.trap_FS_FCloseFile(fd)
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^3liked ^7" .. mapname .. ". Thanks for your vote.\"\n")
				elseif choice == "hate" then
					count = et.trap_FS_Write(cl_guid .. "	" .. mapname .. "	hate\n", string.len(cl_guid .. "	" .. mapname .. "	hate\n"), fd)
					et.trap_FS_FCloseFile(fd)
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^3disliked ^7" .. mapname .. ". Thanks for your vote.\"\n")
				end
			else
				if results[cl_guid .. "	" .. mapname][1] == choice then
					if choice == "like" then
						et.trap_SendServerCommand(-1, "chat \"" .. name .. "^7, you have already liked ^3" .. mapname .. "^7.\"\n")
					else
						et.trap_SendServerCommand(-1, "chat \"" .. name .. "^7, you have already disliked ^3" .. mapname .. "^7.\"\n")
					end
				else
					results[cl_guid .. "	" .. mapname][1] = choice
					if choice == "like" then
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^3liked ^7" .. mapname .. ". Thanks for your vote.\"\n")
					else
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^3disliked ^7" .. mapname .. ". Thanks for your vote.\"\n")
					end
					writeLog(results)
				end
			end
		else
			fd,len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
			if choice == "like" then
				count = et.trap_FS_Write(cl_guid .. "	" .. mapname .. "	like\n", string.len(cl_guid .. "	" .. mapname .. "	like\n"), fd)
				et.trap_FS_FCloseFile(fd)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^3liked ^7" .. mapname .. ". Thanks for your vote.\"\n")
			elseif choice == "hate" then
				count = et.trap_FS_Write(cl_guid .. "	" .. mapname .. "	hate\n", string.len(cl_guid .. "	" .. mapname .. "	hate\n"), fd)
				et.trap_FS_FCloseFile(fd)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^3disliked ^7" .. mapname .. ". Thanks for your vote.\"\n")
			end
		end
	else
		et.trap_SendServerCommand(id, "chat \"^7To prevent end-of-round intermission votes carrying over to the next map by mistake, you can't vote during warmup.\"\n")
	end
end

function et_ClientCommand(id, command)
	if et.trap_Argv(0) == "say" then
		if string.lower(et.trap_Argv(1)) == "!like" or string.lower(et.trap_Argv(1)) == "!love" then
			vote(id, "like")
			mapresults()
		elseif string.lower(et.trap_Argv(1)) == "!dislike" or string.lower(et.trap_Argv(1)) == "!hate" then
			vote(id, "hate")
			mapresults()
		elseif string.lower(et.trap_Argv(1)) == "!mapresults" then
			mapresults()
			end
		end
	end
	return(0)
end