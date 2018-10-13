-- votepoll.lua by x0rnn
-- usage: !votemap (vote_cmd) or !voteresults

filename = "votemap.log"

vote_cmd = "!votemap"
banner = "^7[^1!!!^7]^1H^7irntot vote system options"
banner2 = "^3Do you want to see custom maps on Hirntot? Vote here"
max_choices = 2 -- max votes per GUID
enable_custom_votes = 1 -- 0 = off; enables voting for maps/choices not on the list, e.g. !votemap new baserace (spaces don't work, "mlb temple" will be saved as "mlb")

no_change = "No custom maps"	-- 0
choices = {
"adlernest",			-- 1
"braundorf_b4",			-- 2
"bremen_b3",			-- 3
"et_beach",				-- 4
"et_ice",				-- 5
"frostbite",			-- 6
"sos_secret_weapon",	-- 7
"sp_delivery_te",		-- 8
"supply",				-- 9
"tc_base"				-- 10
}
choice_cnt = 0
for index in pairs(choices) do
	choice_cnt = choice_cnt + 1
end

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("votepoll.lua "..et.FindSelf())
end

function voteresults(id)
	fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
	if len ~= -1 then
		filestr = et.trap_FS_Read(fd, len)
		et.trap_FS_FCloseFile(fd)
		i = 1
		choices_tbl = {}
		for _,v in string.gfind(filestr, "(%w+)\t([^\n]+)") do
			choices_tbl[i] = v
			i = i + 1
		end
		choice_freq = {}
		for k,v in pairs(choices_tbl) do
			choice_freq[v] = freq(v, choices_tbl)
		end
		sortedKeys = getKeysSortedByValue(choice_freq, function(a, b) return a > b end)
		output_tbl = {}
		i = 1
		for _, key in pairs(sortedKeys) do
			if output_tbl[i] == nil then
				output_tbl[i] = key .. " ^2" .. choice_freq[key]
			else
				if string.len(output_tbl[i] .. "^7, " .. key .. " ^2" .. choice_freq[key]) <= 256 then
					output_tbl[i] = output_tbl[i] .. "^7, " .. key .. " ^2" .. choice_freq[key]
				else
					i = i + 1
					output_tbl[i] = key .. " ^2" .. choice_freq[key]
				end
			end
		end
		tbl_cnt = 0
		for index in pairs(output_tbl) do
			tbl_cnt = tbl_cnt + 1
		end
		for j = 1, tbl_cnt do
			et.trap_SendServerCommand(-1, "chat \"" .. output_tbl[j] .. "\"")
		end
		filestr = nil
	else
		et.trap_FS_FCloseFile(fd)
		et.trap_SendServerCommand(id, "chat \"^7" .. filename .. " ^7not found.\"\n")
	end
end

function vote(id, choice)
	cl_guid = et.Info_ValueForKey(et.trap_GetUserinfo(id), "cl_guid")
	name = et.Info_ValueForKey(et.trap_GetUserinfo(id), "name")
	if tonumber(choice) then
		if choice >= 0 and choice <= choice_cnt then
			if choice == 0 then
				flag = false
				flag2 = false
				fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
				if len ~= -1 then
					filestr = et.trap_FS_Read(fd, len)
					et.trap_FS_FCloseFile(fd)
					i = 1
					for v in string.gfind(filestr, cl_guid .. "\t([^\n]+)") do
						i = i + 1
						if i == max_choices + 1 then
							flag = true
							break
						end
						if v == no_change then
							flag2 = true
							break
						end
					end
					if flag2 == false then
						if flag == false then
							fd,len = et.trap_FS_FOpenFile(filename, et.FS_APPEND)
							count = et.trap_FS_Write(cl_guid .. "	" .. no_change .. "\n", string.len(cl_guid .. "	" .. no_change .. "\n"), fd)
							et.trap_FS_FCloseFile(fd)
							votes_left = max_choices - i
							if votes_left ~= 0 then
								et.trap_SendServerCommand(id, "chat \"You have " .. votes_left .. " votes left.\"\n")
							end
							et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7voted for: ^3" .. no_change .. "^7. Type ^3" .. vote_cmd .. " ^7or ^3!voteresults ^7for more info.\"\n")
							voteresults(id)
						else
							et.trap_SendServerCommand(id, "chat \"You have already voted " .. max_choices .. " times.\"\n")
						end
					else
						et.trap_SendServerCommand(id, "chat \"You have already voted for ^3" .. no_change .. "\"\n")
					end
					filestr = nil
				else
					et.trap_FS_FCloseFile(fd)
					fd,len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
					count = et.trap_FS_Write(cl_guid .. "	" .. no_change .. "\n", string.len(cl_guid .. "	" .. no_change .. "\n"), fd)
					et.trap_FS_FCloseFile(fd)
					if max_choices - 1 ~= 0 then
						et.trap_SendServerCommand(id, "chat \"You have " .. max_choices - 1 .. " votes left.\"\n")
					end
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7voted for: ^3" .. no_change .. "^7. Type ^3" .. vote_cmd .. " ^7or ^3!voteresults ^7for more info.\"\n")
					voteresults(id)
				end
			else
				flag = false
				flag2 = false
				fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
				if len ~= -1 then
					filestr = et.trap_FS_Read(fd, len)
					et.trap_FS_FCloseFile(fd)
					i = 1
					for v in string.gfind(filestr, cl_guid .. "\t([^\n]+)") do
						i = i + 1
						if i == max_choices + 1 then
							flag = true
							break
						end
						if v == choices[choice] then
							flag2 = true
							break
						end
					end
					if flag2 == false then
						if flag == false then
							fd,len = et.trap_FS_FOpenFile(filename, et.FS_APPEND)
							count = et.trap_FS_Write(cl_guid .. "	" .. choices[choice] .. "\n", string.len(cl_guid .. "	" .. choices[choice] .. "\n"), fd)
							et.trap_FS_FCloseFile(fd)
							votes_left = max_choices - i
							if votes_left ~= 0 then
								et.trap_SendServerCommand(id, "chat \"You have " .. votes_left .. " votes left.\"\n")
							end
							et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7voted for: ^3" .. choices[choice] .. "^7. Type ^3" .. vote_cmd .. " ^7or ^3!voteresults ^7for more info.\"\n")
							voteresults(id)
						else
							et.trap_SendServerCommand(id, "chat \"You have already voted " .. max_choices .. " times.\"\n")
						end
					else
						et.trap_SendServerCommand(id, "chat \"You have already voted for ^3" .. choices[choice] .. "\"\n")
					end
					filestr = nil
				else
					et.trap_FS_FCloseFile(fd)
					fd,len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
					count = et.trap_FS_Write(cl_guid .. "	" .. choices[choice] .. "\n", string.len(cl_guid .. "	" .. choices[choice] .. "\n"), fd)
					et.trap_FS_FCloseFile(fd)
					if max_choices - 1 ~= 0 then
						et.trap_SendServerCommand(id, "chat \"You have " .. max_choices - 1 .. " votes left.\"\n")
					end
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7voted for: ^3" .. choices[choice] .. "^7. Type ^3" .. vote_cmd .. " ^7or ^3!voteresults ^7for more info.\"\n")
					voteresults(id)
				end
			end
		else
			et.trap_SendServerCommand(id, "chat \"Invalid voting number.\"\n")
		end
	else
		flag = false
		flag2 = false
		fd,len = et.trap_FS_FOpenFile(filename, et.FS_READ)
		if len ~= -1 then
			filestr = et.trap_FS_Read(fd, len)
			et.trap_FS_FCloseFile(fd)
			i = 1
			for v in string.gfind(filestr, cl_guid .. "\t([^\n]+)") do
				i = i + 1
				if i == 4 then
					flag = true
					break
				end
				if v == choice then
					flag2 = true
					break
				end
			end
			if flag2 == false then
				if flag == false then
					fd,len = et.trap_FS_FOpenFile(filename, et.FS_APPEND)
					count = et.trap_FS_Write(cl_guid .. "	" .. choice .. "\n", string.len(cl_guid .. "	" .. choice .. "\n"), fd)
					et.trap_FS_FCloseFile(fd)
					votes_left = 3 - i
					if votes_left ~= 0 then
						et.trap_SendServerCommand(id, "chat \"You have " .. votes_left .. " votes left.\"\n")
					end
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7voted for: ^3" .. choice .. "^7. Type ^3" .. vote_cmd .. " ^7or ^3!voteresults ^7for more info.\"\n")
					voteresults(id)
				else
					et.trap_SendServerCommand(id, "chat \"You have already voted " .. max_choices .. " times.\"\n")
				end
			else
				et.trap_SendServerCommand(id, "chat \"You have already voted for ^3" .. choice .. "\"\n")
			end
			filestr = nil
		else
			et.trap_FS_FCloseFile(fd)
			fd,len = et.trap_FS_FOpenFile(filename, et.FS_WRITE)
			count = et.trap_FS_Write(cl_guid .. "	" .. choice .. "\n", string.len(cl_guid .. "	" .. choice .. "\n"), fd)
			et.trap_FS_FCloseFile(fd)
			if max_choices - 1 ~= 0 then
				et.trap_SendServerCommand(id, "chat \"You have " .. max_choices - 1 .. " votes left.\"\n")
			end
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7voted for: ^3" .. choice .. "^7. Type ^3" .. vote_cmd .. " ^7or ^3!voteresults ^7for more info.\"\n")
			voteresults(id)
		end
	end
end

function freq(ele, t)
	cnt = 0
	for k,v in pairs(t) do
		if ele == t[k] then
			cnt = cnt + 1
		end
	end
	return cnt
end

function getKeysSortedByValue(tbl, sortFunction)
	local keys = {}
	for key in pairs(tbl) do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b) return sortFunction(tbl[a], tbl[b]) end)
	return keys
end

function et_ClientCommand(id, command)
	if et.trap_Argv(0) == "say" then
		if et.trap_Argv(1) == vote_cmd then
			et.trap_SendServerCommand(id, "chat \"" .. banner.. ":\"\n")
			et.trap_SendServerCommand(id, "chat \"" .. banner2.. ":\"\n")
			et.trap_SendServerCommand(id, "chat \"^50^7: " .. no_change .. "\"\n")
			for n = 1, choice_cnt do
				et.trap_SendServerCommand(id, "chat \"^5" .. n .. "^7: " .. choices[n] .. "\"\n")
			end
			if et.trap_Argc() ~= 3 and et.trap_Argc() ~= 4 then
				if enable_custom_votes == 1 then
					et.trap_SendServerCommand(id, "chat \"Usage: ^5" .. vote_cmd .. " ^7<^3#^7> (^2IN CONSOLE!^7)\"\n")
					et.trap_SendServerCommand(id, "chat \"Usage for choices not on the list: ^5" .. vote_cmd .. " new ^7<^3choice^7> (^1no spaces^7) (^2IN CONSOLE!^7)\"\n")
					et.trap_SendServerCommand(id, "chat \"Example 1: to vote for ^3supply^7, type ^3" .. vote_cmd .. " 9^7 (^2IN CONSOLE!^7)\"\n")
					et.trap_SendServerCommand(id, "chat \"Example 2: to vote for ^3baserace^7, type ^3" .. vote_cmd .. " new baserace ^7(^1no spaces^7) ^7(^2IN CONSOLE!^7)\"\n")
				else
					et.trap_SendServerCommand(id, "chat \"Usage: ^5" .. vote_cmd .. " ^7<^3#^7> (^2IN CONSOLE!^7)\"\n")
					et.trap_SendServerCommand(id, "chat \"Example: to vote for ^3supply^7, type ^3" .. vote_cmd .. " 9^7 (^2IN CONSOLE!^7)\"\n")
				end
				et.trap_SendServerCommand(id, "chat \"^3!voteresults ^7to show vote results.\"\n")
			elseif et.trap_Argc() == 3 then
				num = tonumber(et.trap_Argv(2))
				if num then
					if num >= 0 and num <= choice_cnt then
						vote(id, num)
					else
						et.trap_SendServerCommand(id, "chat \"Invalid voting number.\"\n")
					end
				else
					if enable_custom_votes == 1 then
						et.trap_SendServerCommand(id, "chat \"Usage: ^5" .. vote_cmd .. " ^7<^3#^7> (^2IN CONSOLE!^7)\"\n")
						et.trap_SendServerCommand(id, "chat \"Usage for choices not on the list: ^5" .. vote_cmd .. " new ^7<^3choice^7> (^1no spaces^7) (^2IN CONSOLE!^7)\"\n")
					else
						et.trap_SendServerCommand(id, "chat \"Usage: ^5" .. vote_cmd .. " ^7<^3#^7> (^2IN CONSOLE!^7)\"\n")
					end
				end
			elseif et.trap_Argc() == 4 then
				if enable_custom_votes == 1 then
					if et.trap_Argv(2) == "new" then
						vote(id, et.trap_Argv(3))
					else
						et.trap_SendServerCommand(id, "chat \"Usage: ^5" .. vote_cmd .. " ^7<^3#^7> (^2IN CONSOLE!^7)\"\n")
						et.trap_SendServerCommand(id, "chat \"Usage for choices not on the list: ^5" .. vote_cmd .. " new ^7<^3choice^7> (^1no spaces^7) (^2IN CONSOLE!^7)\"\n")
					end
				else
					et.trap_SendServerCommand(id, "chat \"Usage: " .. vote_cmd .. " <^3#^7> (^2IN CONSOLE!^7)\"\n")
				end
			end
		elseif et.trap_Argv(1) == "!voteresults" then
			voteresults(id)
		end
	end
	return(0)
end
