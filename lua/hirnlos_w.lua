-- hirnlos players announcement, version for hirnlos server (write version)

mapname = ""
filename = "hirnlos_announce.txt"

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("hirnlos_w.lua "..et.FindSelf())

	mapname = et.trap_Cvar_Get("mapname")
	fd,len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
	count = et.trap_FS_Write("", 0, fd)
	et.trap_FS_FCloseFile(fd)
end

function et_ClientBegin(clientNum)
	players = 0
	for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
		if et.gentity_get(i,"inuse") then
			players = players + 1
		end
	end

	if players > 0 and players < 24 then
		fd,len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
		count = et.trap_FS_Write(players .. "	" .. mapname .. "\n", string.len(players .. "	" .. mapname .. "\n"), fd)
		et.trap_FS_FCloseFile(fd)
	else
		fd,len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
		count = et.trap_FS_Write("", 0, fd)
		et.trap_FS_FCloseFile(fd)
	end
end

function et_ClientDisconnect(clientNum)
	players = 0
	for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
		if et.gentity_get(i,"inuse") then
			players = players + 1
		end
	end
	if players-1 > 0 and players-1 < 24 then
		fd,len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
		count = et.trap_FS_Write(players-1 .. "	" .. mapname .. "\n", string.len(players-1 .. "	" .. mapname .. "\n"), fd)
		et.trap_FS_FCloseFile(fd)
	else
		fd,len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
		count = et.trap_FS_Write("", 0, fd)
		et.trap_FS_FCloseFile(fd)
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
	return 0
end