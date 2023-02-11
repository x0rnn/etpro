-- anagram game for spectators by x0rnn
-- words from e.g.: http://www.yougowords.com/5-letters

game_running = false
shuffled = ""
score = {}
words_ix = 1

words = {
"meme",
"mole",
"rifle",
"again",
"clear",
"self",
"gone",
"dirty",
"yellow",
"panda",
"wind",
"scarf",
"dolphin",
"mouse",
"courage",
"truck",
"crazy",
"penguin",
"open",
"wolf",
"mango",
"sunday",
"revenge",
"blanket",
"party",
"teacher",
"month",
"smith",
"money",
"circle",
"problem",
"daily",
"iron",
"rose",
"rich",
"words",
"fifty",
"honor",
"never",
"school",
"down",
"banana",
"monkey",
"sixteen",
"cloud",
"nothing",
"bird",
"fish",
"fall",
"dark",
"river",
"bully",
"history",
"five",
"llama",
"ball",
"star",
"death",
"state",
"knife",
"twenty",
"father",
"twelve",
"world",
"teen",
"thirty",
"chair",
"worth",
"glory",
"evil",
"hero",
"metal",
"stone",
"cough",
"admin",
"black",
"land",
"badge",
"poetry",
"America",
"seven",
"honey",
"over",
"awesome",
"cake",
"media",
"music",
"purple",
"turtle",
"tuesday",
"family",
"train",
"amber",
"blood",
"stone",
"sugar",
"able",
"future",
"foot",
"above",
"nine",
"vegan",
"girl",
"blue",
"away",
"jelly",
"live",
"house",
"film",
"high",
"long",
"August",
"come",
"wife",
"room",
"change",
"march",
"hard",
"kitchen",
"bell",
"donate",
"fifteen",
"pumpkin",
"moment",
"friday",
"musical",
"dancing",
"broken",
"secret",
"photo",
"magic",
"bean",
"woman",
"energy",
"cross",
"other",
"harmony",
"puppy",
"eleven",
"silver",
"ever",
"sixty",
"fire",
"wish",
"welcome",
"person",
"faith",
"pirate",
"born",
"moon",
"spring",
"anger",
"once",
"hair",
"monster",
"pasta",
"sing",
"tree",
"being",
"morning",
"voice",
"green",
"forever",
"dance",
"silence",
"today",
"table",
"goat",
"hundred",
"ninety",
"country",
"piano",
"head",
"thing",
"husband",
"watch",
"Jupiter",
"light",
"line",
"zebra",
"home",
"people",
"anime",
"near",
"system",
"three",
"king",
"mine",
"love",
"apple",
"forty",
"safe",
"mother",
"candy",
"alive",
"dress",
"work",
"journey",
"ship",
"amazing",
"lover",
"baby",
"phone",
"night",
"mouth",
"care",
"cycle",
"sure",
"rock",
"bread",
"ally",
"leaf",
"truth",
"pizza",
"animal",
"list",
"golf",
"office",
"beard",
"wood",
"hope",
"nature",
"breath",
"special",
"earth",
"potato",
"city",
"diamond",
"science",
"smart",
"less",
"penny",
"power",
"tina",
"field",
"snitch",
"lemon",
"picture",
"radio",
"value",
"white",
"life",
"hand",
"sorry",
"lion",
"London",
"soul",
"have",
"else",
"under",
"point",
"youtube",
"lady",
"story",
"circus",
"seventy",
"perfect",
"plant",
"ring",
"grace",
"math",
"paper",
"someone",
"queen",
"sister",
"women",
"body",
"justice",
"color",
"about",
"forum",
"back",
"water",
"smile",
"board",
"place",
"heart",
"freedom",
"dream",
"brain",
"time",
"holiday",
"kids",
"royal",
"north",
"alone",
"happy",
"peace",
"scarce",
"with",
"South",
"food",
"laugh",
"rain",
"birth",
"pain",
"monday",
"orange",
"late",
"tiger",
"after",
"fruit",
"santa",
"duck"
}

cnt = 0
for index in pairs(words) do
	cnt = cnt + 1
end

math.randomseed(et.trap_Milliseconds())

function shuffle_tbl(tbl)
    local tReturn = {}
    for i = cnt, 1, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
        table.insert(tReturn, tbl[i])
    end
    return tReturn
end

words = shuffle_tbl(words)

function shuffle_word(inputStr)
	local outputStr = ""
	local strLength = string.len(inputStr)
	
	while (strLength ~=0) do
		local pos = math.random(strLength)
		outputStr = outputStr .. string.sub(inputStr, pos, pos)
		inputStr = string.sub(inputStr, 1, pos-1) .. string.sub(inputStr, pos + 1)
		strLength = string.len(inputStr)
	end

	return outputStr
end

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("anagram.lua "..et.FindSelf())
	local i = 0
	for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
		score[i] = 0
	end
end

function sayClients(msg)
	local message = string.format("chat \"^7(Quiz Bot): %s^7\"", msg)
	for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
		local team = tonumber(et.gentity_get(i, "sess.sessionTeam"))
		if team == 3 then
			et.trap_SendServerCommand(i, message)
		end
	end
end

function resetMinigame()
	game_running = false
	local i = 0
	for i=0,tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
		score[i] = 0
	end
end

function et_ClientBegin(id)
	local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
	if team == 3 then
		if game_running then
			et.trap_SendServerCommand(id, "chat \"^5The spectator minigame is running! The current word to solve is: ^3" .. shuffled .. " ^5(only team chat is accepted!)\"")
		else
			et.trap_SendServerCommand(id, "chat \"^5Type ^3!minigame ^5(in team chat) to start the spectator minigame!\"")
		end
	end
end

function et_ClientDisconnect(id)
	if score[id] ~= 0 then
		score[id] = 0
	end
end

function et_ClientSpawn(id, revived)
	if score[id] ~= 0 then
		score[id] = 0
	end
end

function et_ClientCommand(id, command)
	local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
	if team == 3 then
		if et.trap_Argv(0) == "say_team" or et.trap_Argv(0) == "say_teamnl" then
			if game_running then
				if et.trap_Argv(1) == "!minigame" then
					sayClients("^5The spectator minigame is already running! The current word to solve is: ^3" .. shuffled)
				else
					if et.trap_Argv(1) == words[words_ix] then
						score[id] = score[id] + 5
						if score[id] == 50 then
							sayClients(et.gentity_get(id, "pers.netname") .. "^5 won the minigame with 50 points! The word behind ^3" ..  shuffled .. " ^5was: ^3" .. words[words_ix])
							words_ix = words_ix + 1
							if words_ix > cnt then
								words_ix = 1
								words = shuffle_tbl(words)
							end
							resetMinigame()
							sayClients("^5Type ^3!minigame ^5(in team chat) to start a new game!")
						else
							sayClients(et.gentity_get(id, "pers.netname") .. "^5 guessed the word behind ^3" ..  shuffled .. "^5: ^3" .. words[words_ix] .. "^5. He has ^3" .. score[id] .. "^5 points.")
							words_ix = words_ix + 1
							if words_ix > cnt then
								words_ix = 1
								words = shuffle_tbl(words)
							end
							shuffled = words[words_ix]
							while shuffled == words[words_ix] do
								shuffled = shuffle_word(words[words_ix])
							end
							sayClients("^5Next word to solve is: ^3" .. shuffled)
						end
					end
				end
			else
				if et.trap_Argv(1) == "!minigame" then
					game_running = true
					shuffled = words[words_ix]
					while shuffled == words[words_ix] do
						shuffled = shuffle_word(words[words_ix])
					end
					sayClients("^5The spectator minigame started! The first word to solve is: ^3" .. shuffled .. " ^5(only team chat is accepted!)")
				end
			end
		else
			if et.trap_Argv(0) == "say" then
				if et.trap_Argv(1) == "!minigame" then
					et.trap_SendServerCommand(id, "chat \"^7(Quiz Bot): ^5You need to type !minigame in team chat!\"")
				end
			end
		end
	end
	return 0
end
