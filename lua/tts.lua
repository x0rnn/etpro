-- tts.py by x0rnn, primitive TTS (text-to-speech) system based on arpabet (https://en.wikipedia.org/wiki/Arpabet)
-- use with https://github.com/x0rnn/etpro/blob/master/lua/tts.pk3 and https://github.com/x0rnn/etpro/blob/master/lua/tts.txt

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
	local fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len == -1 then
		et.G_Print("tts.lua: no tts.txt\n")
		return(0)
	end
	local filestr = et.trap_FS_Read(fd, len)
	et.trap_FS_FCloseFile(fd)

	local word, arpa
	for word, arpa in string.gfind(filestr,"([%a]+)\t([^\n]+)") do
		dict[word] =
		{
			arpa
		}
	end
	if next(dict) ~= nil then
		local cnt = 0
		for i = 0, wordcount-1 do
			if type(dict[args_table[i+1]]) == "table" then
				cnt = cnt + 1
				arpabet = arpabet .. dict[args_table[i+1]][1] .. " "
			end
		end
		if cnt ~= wordcount then
			arpabet = ""
			et.trap_SendServerCommand(id, "chat \"^7Didn't find all words, can't do TTS.\"\n")
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
	if et.trap_Argv(0) == "say" then
		args = et.ConcatArgs(1)
		local args_table = {}
		cnt = 0
		for i in string.gfind(args, "%S+") do
			table.insert(args_table, i)
			cnt = cnt + 1
		end
		if args_table[1] ~= nil and string.lower(args_table[1]) == "!tts" then
			table.remove(args_table, 1)
			readDict(args_table, id)
		end
	end
	return(0)
end
