-- /cmd vdr
-- et_ClientUserinfoChanged health: 20
-- et_ClientSpawn health: 100 (not actually spawned)
-- et_ClientBegin health: 0
-- et_ClientSpawn health: 100 (on real spawn)

local STATE_DEAD         = 0
local STATE_ALIVE        = 1
local STATE_SPAWN        = 2
local STATE_BEGIN        = 3
local STATE_WEIRD        = 4
local STATE_REALLY_WEIRD = 5
local STATE_PENDING_NUKE = 6

local state = {}
local nuke = false

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("cmd.lua " .. et.FindSelf())
end

function et_ClientConnect(clientNum, firstTime, isBot)
	state[clientNum] = STATE_DEAD
end

function et_ClientDisconnect(clientNum)
	state[clientNum] = nil
end

function et_RunFrame(levelTime)

	if nuke and math.mod(levelTime, 1000) == 0 then
		
		nuke = false

		for i = 0, 63 do
		
			if state[i] == STATE_PENDING_NUKE then

				-- make sure the player has no spawninvul.
				if is_active(i) and et.gentity_get(i, "health") > 0 and et.gentity_get(i, "ps.powerups", 1) < levelTime then
					state[i] = STATE_ALIVE
					et.G_LogPrint("cmd.lua: nuke " .. i .. "\n")
					et.G_Damage(i, 80, 1022, 1000, 8, 34)
				else
					nuke = true -- someone still not punished.
				end

			end
		
		end
		
	end

end

function et_ClientBegin(clientNum)
	
	if state[clientNum] == STATE_PENDING_NUKE then
		return
	end
	
	local health = et.gentity_get(clientNum, "health")
	local active = is_active(clientNum)

	if active and health == 0 and state[clientNum] == STATE_WEIRD then
		state[clientNum] = STATE_REALLY_WEIRD
	elseif active and health > 0 then
		state[clientNum] = STATE_ALIVE
	else
		state[clientNum] = STATE_DEAD
	end
	
end

function et_ClientSpawn(clientNum, revived)

	if state[clientNum] == STATE_PENDING_NUKE then
		return
	end

	if revived == 0 and state[clientNum] == STATE_REALLY_WEIRD and tonumber(et.trap_Cvar_Get("gamestate")) == 0 then
		
		-- We already know the player used the vdr command by now.
		-- Let's fuck with him once he actually spawns (kill, or yet better, kick).
		state[clientNum] = STATE_PENDING_NUKE
		nuke = true
		
	elseif revived == 0 and state[clientNum] == STATE_ALIVE then
		state[clientNum] = STATE_WEIRD
	else
		state[clientNum] = STATE_ALIVE
	end

end

function et_Obituary(victim, killer, meansOfDeath)
	
	if killer >= 0 and killer < 64 then
		state[killer] = STATE_ALIVE
	end
	
	if victim >= 0 and victim < 64 then
		state[victim] = STATE_DEAD
	end
	
end

function is_active(clientNum)
	local state = et.gentity_get(clientNum, "pers.teamState.state")
	local team = et.gentity_get(clientNum, "sess.sessionTeam")
	return state and team > 0 and team < 3
end
