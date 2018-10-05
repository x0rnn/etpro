-- automute.lua by x0rnn
-- create a filename called "automuted.txt"
-- the format must be:
-- guid	dd/mm/yyyy	reason
-- example:
-- 01234567890123456789ABCDEF012345	16/01/2020	being an idiot
-- separate fields with tabs not spaces
-- expire date cannot be more than 19 years over the current date for some reason
-- instead of perma-muting, just add 10 years to the current date e.g. 05/10/2028

filename = "automuted.txt"
unmute_tries = {}

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("automute.lua "..et.FindSelf())
end

function et_ClientBegin(clientNum)
	name = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "name")
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len ~= -1 then
		filestr = et.trap_FS_Read(fd, len)
		for d,m,y,reason in string.gfind(filestr, cl_guid .. "\t(%d+)\/(%d+)\/(%d+)\t([^\n]+)") do
			if reason ~= nil then
				dt = {year=y, month=m, day=d}
				if os.time(dt) >= os.time(os.date("!*t")) then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7automuted until ^1" .. d .. "/" .. m .. "/" .. y .. "^7 for: ^1" .. reason .. "\"\n")
					et.gentity_set(clientNum, "sess.muted", 1)
				end
			end
		end
		filestr = nil
		et.trap_FS_FCloseFile(fd)
	else
		et.trap_FS_FCloseFile(fd)
	end
end

function et_ClientCommand(cno, cmd)
	if tonumber(et.gentity_get(cno, "sess.muted")) == 1 then
		if string.lower(cmd) == "m" or string.lower(cmd) == "pm" then
			et.trap_SendServerCommand(cno, "cpm \"^1You are muted. This command is not available to you.\n\"")
			return 1
		elseif string.lower(cmd) == "callvote" then
			if string.lower(et.trap_Argv(1)) == "unmute" then
				if cno == tonumber(et.trap_Argv(2)) then
					if unmute_tries[cno] == nil then
						unmute_tries[cno] = 1
					else
						unmute_tries[cno] = unmute_tries[cno] + 1
					end
					if unmute_tries[cno] <= 3 then
						msg = string.format("cpm  \"" .. string.format(et.Info_ValueForKey(et.trap_GetUserinfo(cno), "name")) .. "^7 got bummed for trying to unmute himself. What a peon.\n")
						et.trap_SendServerCommand(-1, msg)
						et.G_Damage(cno, 80, 1022, 1000, 8, 34)
						soundindex = et.G_SoundIndex("/sound/etpro/osp_goat.wav")
						et.G_Sound(cno, soundindex)
						if unmute_tries[cno] >= 3 then
							et.trap_SendServerCommand(cno, "cpm \"^1You cannot unmute yourself. Next time you try, you will get kicked.\n\"")
						end
					else
						et.trap_DropClient(cno, "You cannot unmute yourself, stop trying.", 900) --15 minutes
					end
				end
			end
			return 1
		end
	else
		if string.lower(cmd) == "callvote" then
			if string.lower(et.trap_Argv(1)) == "unmute" then
				clean_name = et.Q_CleanStr(et.Info_ValueForKey(et.trap_GetUserinfo(tonumber(et.trap_Argv(2))), "name"))
				cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(tonumber(et.trap_Argv(2))), "cl_guid")
				if cl_guid ~= "" then
					fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
					if len ~= -1 then
						filestr = et.trap_FS_Read(fd, len)
						for d,m,y,reason in string.gfind(filestr, cl_guid .. "\t(%d+)\/(%d+)\/(%d+)\t([^\n]+)") do
							if reason ~= nil then
								dt = {year=y, month=m, day=d}
								if os.time(dt) >= os.time(os.date("!*t")) then
									et.trap_SendServerCommand(-1, "chat \"You can't unmute " .. clean_name .. ".\"\n")
								end
								filestr = nil
								et.trap_FS_FCloseFile(fd)
								return 1
							end
						end
					else
						et.trap_FS_FCloseFile(fd)
					end
				end
			end
		end
	end
	return(0)
end
