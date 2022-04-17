-- tts.py by x0rnn, primitive TTS (text-to-speech) system based on arpabet (https://en.wikipedia.org/wiki/Arpabet)
-- use with https://github.com/x0rnn/etpro/blob/master/lua/tts.pk3 and https://github.com/x0rnn/etpro/blob/master/lua/tts.txt

shrubbot = "shrubbot.cfg"
filename = "tts.txt"
dict = {}
arpabet = ""
timers = {}
steps = {}

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("tts.lua "..et.FindSelf())
end

function et_RunFrame(lvltime)
	levelTime = lvltime
	table.foreach(timers, -- usually this is empty, so nothing is done
		function(i, timer)
			if timer[1] <= levelTime then 
				et.G_globalSound("sound/tts/" .. string.lower(timer[2]) .. ".wav")
				local step = steps[1]
				table.remove(steps, 1)
				if steps[1] == "XX" then
					table.remove(timers, 1)
					table.remove(steps, 1)
				else
					timer[2] = step
					timer[1] = levelTime + 180
				end
			end
		end
	)
end

function readDict(args_table, id)
	arpabet = ""
	local wordcount = table.getn(args_table)
	if next(dict) == nil then
		local fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
		if len == -1 then
			et.G_Print("tts.lua: no tts.txt\n")
			return(0)
		end
		local filestr = et.trap_FS_Read(fd, len)
		et.trap_FS_FCloseFile(fd)

		local word, arpa
		for word, arpa in string.gfind(filestr,"([^\n]+)\t([^\n]+)") do
			dict[word] =
			{
				arpa
			}
		end
	end
	if next(dict) ~= nil then
		local cnt = 0
		for i = 1, wordcount do
			if type(dict[args_table[i]]) == "table" then
				cnt = cnt + 1
				arpabet = arpabet .. dict[args_table[i]][1] .. " "
			end
		end
		if cnt ~= wordcount then
			arpabet = ""
			local missing = "" 
			for i = 1, wordcount do
				if type(dict[args_table[i]]) ~= "table" then
					missing = missing .. args_table[i] .. " "
				end
			end
			et.trap_SendServerCommand(id, "chat \"^7Didn't find the following words: ^3" .. string.sub(missing, 1, -2) .. "^7, can't do TTS.\"\n")
		end
		if arpabet ~= "" then
			local arpa_table = {}
			cnt = 0
			for i in string.gfind(arpabet, "%S+") do
				table.insert(arpa_table, i)
				cnt = cnt + 1
			end
			for i = 1, table.getn(arpa_table) do
				if i > 1 then
					table.insert(steps, arpa_table[i])
				end
			end
			table.insert(steps, "X")
			table.insert(steps, "XX")
			table.insert(timers, {levelTime + 180, arpa_table[1]})
		end
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
			table.insert(args_table, string.lower(i))
			cnt = cnt + 1
		end
		if args_table[1] ~= nil and args_table[1] == "!tts" then
			fd,len = et.trap_FS_FOpenFile(shrubbot, et.FS_READ)
				if len ~= -1 then
					filestr = et.trap_FS_Read(fd, len)
					et.trap_FS_FCloseFile(fd)
					for v in string.gfind(filestr, guid .. "\nlevel\t%= ([^\n]+)") do
						if tonumber(v) >= 8 then -- level 8+
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
					if cnt == 1 then
						et.trap_SendServerCommand(id, "chat \"Usage: ^7!tts <^3bla bla^7>\"\n")
					else
						table.remove(args_table, 1)
						readDict(args_table, id)
					end
				else
					et.trap_SendServerCommand(id, "chat \"^7This command is not available to you.\"\n")
				end
		end
	end
	return(0)
end
