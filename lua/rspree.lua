----------------
-- Vetinari's rspree.lua
--
-- $Date: 2007-03-02 13:35:49 +0100 (Fr, 02 Mär 2007) $
-- $Id: rspree.lua 181 2007-03-02 12:35:49Z vetinari $
-- $Revision: 181 $
--
version = "1.2.3"
--
-- read carefully and adjust the lines to fit your needs
-- between the "-- Config" and "-- END of Config" lines
--
--  Thanks to the Hirntot.org admin [!!!]Harlekin and the [!!!] community
--  for testing on their servers :)
--

local announce_revives, revive_color, revive_pos, spree_pos
local spree_color, spree_cfg, record_cfg, date_fmt, multi_revive
local multi_announce, multi_sound, multi_pos, monster_pos
local multi_msg, monster_msg, multi_without_death, allow_tk_revive
local rspree_cmd_enabled, rspree_cmd, record_cmd
local record_last_nick, stats_cmd, records_expire, R_Sprees
local srv_record, save_awards, awards_file
local msg_default, msg_command

-----------------------------------------------------------
-- Config                                                --
-----------------------------------------------------------
announce_revives = false -- set to true or false, "false" disables announcing of revives
                     -- usually set to false because it influences game play too much
                     -- this was just added for debugging
revive_color = "7"   -- color of announced revives
revive_pos   = "cpm" -- where to put the announced revive msgs, see comment below

spree_pos    = "chat" -- see http://wolfwiki.anime.net/index.php/SendServerCommand for valid locations
spree_color  = "8"   -- color of spree messages
spree_cfg    = "revivingspree.txt" -- all time stats are saved here..
record_cfg   = "rspree-records.txt" -- all time records, see 'srv_record'

date_fmt     = "%Y-%m-%d, %H:%M:%S" -- for map record dates, see strftime(3) ;->

multi_revive   = true -- set to true or false, "false" disables multi/monster revives
multi_announce = true -- set to true or false, "false" disables the msgs below
multi_sound    = true -- DON'T set to true to enable, no sounds yet... SET TO false IF YOU DON'T HAVE SOUNDS FOR THIS
        -- "sound/misc/multirevive.wav" / "sound/misc/monsterrevive.wav"
        -- are played if 'multi_sound = true' :o) --
multi_pos      = "b 8"
monster_pos    = "cp" -- b 32 == cp (this info is for harle :o))
-- the %s below will be replaced by the player name
multi_msg      = "^7!!!! ^1Multirevive ^7> ^7%s ^7< ^1Multirevive^7 !!!!"
monster_msg    = "^7OMG,^1 MONSTER REVIVE ^7>>> ^7%s ^7<<< ^1MONSTER REVIVE^7 !!!!"

-- mod selection harle rip off
gamename = et.trap_Cvar_Get("gamename")
if (gamename == "etpub" or gamename == "nq")  then
spree_pos    = "chat" -- see http://wolfwiki.anime.net/index.php/SendServerCommand for valid locations
multi_pos      = "chat"
monster_pos    = "chat" -- b 32 == cp (this info is for harle :o))
end
-- mod selection harle rip off

-- yes, very unlikely, but you can revive, die, get revived and do
-- another revive within 3 seconds....
-- hmm... probably it's worth a possible multi/monster revive if
-- you manage to do that, so let the admin decide if it's honoured
multi_without_death = false -- set to true to stop multi revives if medic dies

allow_tk_revive = true -- if true: a revive of a tk'd team mate does not
                       -- add a revive, but just sets the time of the last
                       -- revive. With this you can tk one, revive someone
                       -- else, then the tk'd and another one with max 3 secs
                       -- between each revive instead of max 3 seconds between
                       -- two not tk'd players
                       -- if false: time between reviving two not tk'd players
                       -- is used

rspree_cmd_enabled = true -- set to false to ignore next line's command
rspree_cmd = "!spree_record" -- same as etadmin_mod's killing spree record
record_cmd = "!top"
record_last_nick = true -- set to true to keep the last known nick a guid has,
                         --  ... instead of the one seen the first time
stats_cmd  = "!stats" -- same as etadmin_mod's !stats command
records_expire = 60*60*24*90  -- in seconds! 60*60*24*90 == 90 days

save_awards = true
awards_file = "awards.txt" -- same as kspree.lua's awards file,
                           -- greetings to bennz :-)
R_Sprees = { -- these numbers MUST be multiple of 5...!
     [5] = "is on a reviving spree",
    [10] = "really needs new syringes soon",
    [15] = "earned the bronze syringe",
    [20] = "earned the silver syringe",
    [25] = "earned the golden syringe",
    [30] = "is a god dressed in white",
    [35] = "just arrived from the 4077th M*A*S*H",
}

srv_record = true -- enable/show users with most multi/monster revives
msg_default = true -- print rspree messages to client if true
          -- clients can set their default with 'setu v_rsprees 1' (or 0)
msg_command = "rsprees" -- '\rsprees 1|0' to switch on / off the messages
-----------------------------------------------------------
-- END of Config
-----------------------------------------------------------

--
-- don't change anything below, unless you know what you're doing
--

local revive_sprees = {}
local max_spree     = 0
local max_id        = nil
local alltime_stats = {}
local multi         = {}
local map_record    = false
local srv_records   = {}

local endofmap      = false
local eomap_done    = false

local client_msg = {}

local teams = { [0]="Spectator", [1]="Axis", [2]="Allies", [3]="Unknown", }

local EV_GLOBAL_CLIENT_SOUND = 54

function sayClients(pos, msg)
    -- et.G_Printf("rspree.lua: sayClients('%s', '%s')\n", pos, msg)
    local message = string.format("%s \"%s^7\"", pos, msg)
    table.foreach(client_msg,
        function(id, msg_ok)
            if msg_ok then
                et.trap_SendServerCommand(id, message)
            end
        end
    )
    -- et.trap_SendServerCommand(-1, pos.." \""..msg.."^7\"\n")
end

function playClients(snd)
    local snd_id = et.G_SoundIndex(snd)
    if snd_id == nil then
        return
    end
    table.foreach(client_msg,
        function(id, msg_ok)
            if msg_ok then
                local t_ent = et.G_TempEntity(
                                et.gentity_get(id, "r.currentOrigin"),
                                        EV_GLOBAL_CLIENT_SOUND)
                et.gentity_set(t_ent, "s.teamNum", id)
                et.gentity_set(t_ent, "s.eventParm", snd_id)
                -- et.G_Sound(id, snd_id)
            end
        end
    )
end

-- printf wrapper for debugging
function et.G_Printf(...)
    et.G_Print(string.format(unpack(arg)))
end

-- called when game inits
function et_InitGame(levelTime, randomSeed, restart)
    local func_start = et.trap_Milliseconds()
    revive_sprees = {}
    max_spree     = 0
    max_id        = nil
    alltime_stats = {}
    multi         = {}
    map_record    = false
    endofmap      = false
    eomap_done    = false

    et.RegisterModname("rspree.lua"..version.." "..et.FindSelf())

    sv_maxclients = tonumber(et.trap_Cvar_Get("sv_maxclients"))
    local i = 0
    for i=0, sv_maxclients - 1 do
        resetSpree(i)
        resetMulti(i)
        client_msg[i] = false
    end
    et.G_Printf("rspree.lua: running on map '%s'\n", mapName())

    i = readStats(spree_cfg)
    et.G_Printf("rspree.lua: loaded %d alltime stats from %s\n", i, spree_cfg)

    if srv_record then
        i = readRecords(record_cfg)
        et.G_Printf("rspree.lua: loaded %d alltime records from %s\n",
                                    i, record_cfg)
    end

--    et.trap_SendConsoleCommand(et.EXEC_NOW,
--                  "sets RSpree_mod_version "..version)

    et.G_Printf("rspree.lua: startup: %d ms\n",
                  et.trap_Milliseconds() - func_start)
    et.G_Printf("Vetinari's rspree.lua version "..version.." activated...\n")
end

function mapName ()
    return(string.lower(et.trap_Cvar_Get("mapname")))
end

function getGuid (id)
    return(string.lower(et.Info_ValueForKey(
                    et.trap_GetUserinfo(id), "cl_guid")))
end

function teamName (t)
    if t < 0 or t > 3 then
        t = 3
    end
    return(teams[t])
end

function playerName(id)
    return(et.Info_ValueForKey(et.trap_GetUserinfo(id), "name"))
end

function findMaxSpree()
    local max = alltime_stats[mapName()]
    if max == nil then
        max = {}
    end
    return(max)
end

function readStats(file)
    local func_start = et.trap_Milliseconds()
    local fd         = nil
    local len        = -1
    local count      = 0
    fd,len = et.trap_FS_FOpenFile(file, et.FS_READ)
    if len == -1 then
        et.G_Printf("Failed to open %s ...", file)
        et.G_Printf("rspree.lua: readStats(): %d ms\n",
                    et.trap_Milliseconds() - func_start)
        return(0)
    end

    local str = et.trap_FS_Read(fd, len)
    et.trap_FS_FCloseFile(fd)
    local map, spree, time, nick

    for map, spree, time, nick in string.gfind(str,
                                "([^;#\n]+)%;(%d+)%;(%d+)%;([^%\n]+)") do
        -- et.G_Printf("'%s;%s;%s;%s'\n", map, spree, time, nick);
        alltime_stats[map] = {
                            tonumber(spree),
                            tonumber(time),
                            nick
                         }
        count = count + 1
    end
    et.G_Printf("rspree.lua: readStats(): %d ms\n",
                    et.trap_Milliseconds() - func_start)
    return(count)
end

function saveStats(file, list)
    local func_start = et.trap_Milliseconds()
    local fd, len = et.trap_FS_FOpenFile(file, et.FS_WRITE)
    if len == -1 then
        et.G_Printf("rspree.lua: failed to open %s", file)
        et.G_Printf("rspree.lua: saveStats(): %d ms\n",
                    et.trap_Milliseconds() - func_start)
        return(0)
    end
    local head = string.format("# %s, written %s\n", file, os.date())
    et.trap_FS_Write(head, string.len(head), fd)
    table.foreach(list,
        function (first, arr)
            local line = first .. ";".. table.concat(arr, ";").."\n"
            et.trap_FS_Write(line, string.len(line), fd)
            -- FIXME: check for errors (i.e. ENOSPACE or sth like that)?
        end
    ) -- end table.foreach()
    et.trap_FS_FCloseFile(fd)
    et.G_Printf("rspree.lua: saveStats(): %d ms\n",
                    et.trap_Milliseconds() - func_start)
end

function readRecords(file)
    local func_start = et.trap_Milliseconds()
    local fd         = nil
    local len        = -1
    local count      = 0
    fd,len = et.trap_FS_FOpenFile(file, et.FS_READ)
    if len == -1 then
        et.G_Printf("Failed to open %s ...", file)
        et.G_Printf("rspree.lua: readRecords(): %d ms\n",
                    et.trap_Milliseconds() - func_start)
        return(0)
    end

    local str = et.trap_FS_Read(fd, len)
    et.trap_FS_FCloseFile(fd)

    local guid, multi, monster, revive, nick, firstseen, lastseen
    local now      = tonumber(os.date("%s"))
    local exp_diff = now - records_expire
    for guid, multi, monster, revive, nick, firstseen, lastseen
        in string.gfind(str,
            "[^%#](%x+)%;(%d*)%;(%d*)%;(%d*)%;([^;]*)%;(%d*)%;([^%\n]*)") do

        lastseen = tonumber(lastseen)
        if (records_expire == 0) or (exp_diff < lastseen) then
            srv_records[guid] = {
                                    tonumber(multi),
                                    tonumber(monster),
                                    tonumber(revive),
                                    nick,
                                    tonumber(firstseen),
                                    lastseen
                                }
            count = count + 1
        end
    end
    et.G_Printf("rspree.lua: readRecords(): %d ms\n",
                    et.trap_Milliseconds() - func_start)
    return(count)
end

function et_Print(text)
    local junk1,junk2,medic,zombie = string.find(text,
                                            "^Medic_Revive:%s+(%d+)%s+(%d+)")
    if medic ~= nil and zombie ~= nil then
        medic  = tonumber(medic)
        zombie = tonumber(zombie)
        if announce_revives then
            sayClients(revive_pos,
                        string.format("%s ^%s was revived by ^7%s",
                        playerName(zombie), revive_color, playerName(medic)))
        end

        if et.gentity_get(zombie, "enemy") == medic then -- tk&revive
            if allow_tk_revive and multi[medic][2] > 0 then
                multi[medic][1] = et.trap_Milliseconds()
            end
        else -- not a tk&revive
            revive_sprees[medic] = revive_sprees[medic] + 1
            local guid = getGuid(medic)
            if srv_record then
                if type(srv_records[guid]) ~= "table" then
                    --  guid;    multi;monster;revive;nick;firstseen;lastseen
                    srv_records[guid] = { 0, 0, 0, playerName(medic),
                                                    tonumber(os.date("%s")), 0 }
                elseif table.getn(srv_records[guid]) ~= 6 then
                    --  guid;    multi;monster;revive;nick;firstseen;lastseen
                    srv_records[guid] = { 0, 0, 0, playerName(medic),
                                                    tonumber(os.date("%s")), 0 }
                end
                srv_records[guid][3] = srv_records[guid][3] + 1
                srv_records[guid][6] = tonumber(os.date("%s"))
                -- if guid is seen the first time, insert the nick ... or just
                -- set record_last_nick to true in config section to update
                -- every time
                if record_last_nick or (srv_records[guid][4] == nil) then
                    srv_records[guid][4] = playerName(medic)
                end
            end

            if revive_sprees[medic] > max_spree then
                max_spree = revive_sprees[medic]
                max_id    = medic
            end

            if multi_revive then
                checkMultiRevive(medic, guid)
            end

            checkSprees(medic)
        end
        return(nil)
    end -- END if medic ~= nil and zombie ~= nil then

    if endofmap and string.find(text, "^WeaponStats: ") == 1 then
        if not eomap_done then
            if max_id ~= nil then -- unlikely, but you never know ... :)
                local longest = ""
                local max     = findMaxSpree() -- max = { count, date, name }
                if table.getn(max) == 3 then
                    if map_record then
                        longest = " ^"..spree_color.."This is a New map record!"
                        saveStats(spree_cfg, alltime_stats)
                    else
                        longest = string.format(" ^7[record: %d by %s^7 @%s]",
                                    max[1], max[3], os.date(date_fmt, max[2]))
                    end
                end
                local msg = string.format("^7Longest reviving spree: "
                                    .."%s^7 with %d revives!%s",
                                    playerName(max_id), max_spree, longest)
                et.trap_SendConsoleCommand(et.EXEC_APPEND,
                                    "qsay \""..msg.."^7\"\n")
                -- sayClients("b 8", msg)
            end
            if srv_record then
                saveStats(record_cfg, srv_records)
            end
            eomap_done = true
        end
        return(nil)
    end -- END if endofmap and string.find(text, "^WeaponStats: ") == 1 then

    if text == "Exit: Timelimit hit.\n" or text == "Exit: Wolf EndRound.\n" then
        endofmap = true
        for i = 0, sv_maxclients - 1 do
            if revive_sprees[i] ~= nil and revive_sprees[i] > 0 then
                checkSpreeEnd(i, 1022, true)
            end
        end
        return(nil)
    end
end

function checkMultiRevive (id, guid)
    -- the multi/monster revive logic below was "stolen" from etadmin_mod.pl
    -- multi revive   = 3 revives in a row with max 3 seconds
    --                    between each revive
    -- monster revive = 5 revives in a row with max 3 seconds
    --                    between each revive
    local lvltime = et.trap_Milliseconds()
    if (lvltime - multi[id][1]) < 3000 then
        multi[id][2] = multi[id][2] + 1

        if multi[id][2] == 3 then
            local m_name = playerName(id)
            et.G_Printf("Multirevive: %d (%s)\n", id, m_name)
            if multi_announce then
                sayClients(multi_pos, string.format(multi_msg, m_name))
            end
            if multi_sound then
                playClients("sound/misc/multirevive.wav")
            end
            if srv_record then
                srv_records[guid][1] = srv_records[guid][1] + 1
            end

        elseif multi[id][2] == 5 then
            local m_name = playerName(id)
            et.G_Printf("Monsterrevive: %d (%s)\n", id, m_name)
            if multi_announce then
                sayClients(monster_pos, string.format(monster_msg, m_name))
            end
            if multi_sound then
                playClients("sound/misc/monsterrevive.wav")
            end
            if srv_record then
                srv_records[guid][2] = srv_records[guid][2] + 1
            end
            if save_awards then
                local fd,len = et.trap_FS_FOpenFile(awards_file, et.FS_APPEND)
                if len == -1 then
                    et.G_Printf("failed to save monsterrevive award for %s\n",
                                playerName(id))
                else
                    local msg = playerName(id).. " - Monsterrevive- "
                                              ..os.date().."\n"
                    et.trap_FS_Write(msg, string.len(msg), fd)
                    et.trap_FS_FCloseFile(fd)
                end
            end
        end
    else
        multi[id][2] = 1
    end
    multi[id][1] = lvltime
end

function et_Obituary(victim, killer, mod) -- mod = MeansOfDeath
    local v_teamid = et.gentity_get(victim, "sess.sessionTeam")
    local k_teamid = et.gentity_get(killer, "sess.sessionTeam")
    -- yes, very unlikely, but you can revive, die, get revived and do
    -- another revive within 3 secs....
    -- hmm... probably it's worth a possible multi/monster revive if
    -- you manage to do that, so let the admin decide if it's honoured
    if multi_without_death then
        resetMulti(victim)
    end

    if (victim == killer) then -- suicide
        checkSpreeEnd(victim, killer, false)
        resetSpree(victim)

    elseif (v_teamid == k_teamid) then -- team kill
        checkSpreeEnd(victim, killer, false)
        resetSpree(victim)

    else -- nomal kill
        if killer <= sv_maxclients then
            checkSpreeEnd(victim, killer, true)
        else
            checkSpreeEnd(victim, killer, false)
        end
        resetSpree(victim)
    end
end

function resetMulti(id)
    multi[id] = { [1]=0, [2]=0, } -- [1] => counter, [2] => last revive
end

function resetSpree(id)
    revive_sprees[id] = 0
end

function checkSprees(id)
    -- et.G_Printf("checkSprees %d\n", id)
    if revive_sprees[id] ~= 0 then
        if math.mod(revive_sprees[id], 5) == 0 then
            local spree = R_Sprees[revive_sprees[id]]
            if revive_sprees[id] > 35 then
                spree = R_Sprees[35]
            end
            if spree == nil then
                spree = "is on a reviving spree (FIXME, spree=nil)"
            end
            sayClients(spree_pos,
                        string.format("%s^%s %s (^7%d revives in a row^%s)",
                                      playerName(id), spree_color, spree,
                                      revive_sprees[id], spree_color))
        end
    end
end

function checkSpreeEnd(id, killer, normal_kill)
    if revive_sprees[id] > 0 then
        local m_name = playerName(id)
        if m_name == nil or m_name == "" then
            -- this only happens if a player leaves / disconnects
            -- while on a spree. Fill with something, an empty player
            -- name just looks weird ;-)
            m_name = "(disconnected)"
        end
        local k_name = ""
        if killer == 1022 then
            k_name = "End of round"
        elseif killer == 1023 then
            k_name = "unknown reasons"
        else
            k_name = playerName(killer)
        end
        local record = false
        local msg    = ""

        if max_id == id and revive_sprees[id] == max_spree then
            -- hmm... max_id can't be nil here... it's at least 1
            local max = findMaxSpree() -- max = { count, date, name }
            if table.getn(max) == 3 and max_spree > max[1] then
                -- insert max record on death...
                -- then a player gets the reward, if he disconnects before EOMap
                alltime_stats[mapName()] = { max_spree, os.date("%s"), m_name }
                map_record = true
                record     = true
            elseif table.getn(max) == 0 then -- no previous record for this map
                alltime_stats[mapName()] = { max_spree, os.date("%s"), m_name }
                map_record = true
                record     = true
            end
        end

        if revive_sprees[id] >= 5 then
            if normal_kill then -- i.e. no TK or suicide
                sayClients(spree_pos,
                    string.format("%s^%s's reviving spree ended (^7%d "
                                .."revives^%s), killed by ^7%s^%s!",
                                    m_name, spree_color, revive_sprees[id],
                                    spree_color, k_name, spree_color))
                if record then
                    sayClients(spree_pos, "^"..spree_color..
                                            "This is a new map record!^7")
                end

            else
                if record and killer <= sv_maxclients then
                    sayClients(spree_pos,
                        string.format("%s^%s's reviving spree ended "
                                    .."(^7%d revives^%s).",
                                        m_name, spree_color, revive_sprees[id],
                                        spree_color))
                    sayClients(spree_pos, "^"..spree_color
                                    .."This is a new map record!^7")
                end
            end
        end
    end
end

function et_ClientSpawn(id, revived)
	if revived ~= 1 then
		revive_sprees[id] = 0
	end
end

function et_ClientDisconnect(id)
    revive_sprees[id] = 0
    client_msg[id] = false
end

function et_ClientCommand(id, command)
    local arg0 = string.lower(et.trap_Argv(0))
    local arg1 = et.trap_Argv(1)
    if arg0 == "say" then
    	if et.gentity_get(id, "sess.muted") == 1 then return 1 end
        if rspree_cmd_enabled and arg1 == rspree_cmd then
            local map_msg = ""
            local map_max = findMaxSpree()
            if table.getn(map_max) ~= 3 then
                map_max = { 0, 0, nil }
            end
            if map_max[3] ~= nil then
                map_msg = string.format("^1map: ^7%s^1: ^7%s^1 (^7%d^1) @ %s",
                                        mapName(), map_max[3], map_max[1],
                                        os.date(date_fmt, map_max[2]))
            else
                map_msg = string.format("^1map: ^7%s^1: ^7no record", mapName())
            end

            local all_msg = ""
            local all_max = { 0, 0, nil }
            table.foreach(alltime_stats,
                          function (map, arr)
                                if arr[1] > all_max[1] then
                                    all_max = arr
                                end
                          end)
            if all_max[3] ~= nil then
                all_msg = string.format(" ^1[^7overall: %s^1 (^7%d^1) @ %s^1]",
                                    all_max[3], all_max[1], os.date(date_fmt,
                                                                    all_max[2]))
            end
            et.trap_SendConsoleCommand(et.EXEC_APPEND,
                        "qsay \"^1rspree_record: "..map_msg..all_msg.."^7\"\n")
            -- sayClients(spree_pos, msg)
            -- no! with sayClients() it would be printed b4 the !spree_record :)
        elseif srv_record and arg1 == record_cmd then
            local rec_msg = recordMessage()
            et.trap_SendConsoleCommand(et.EXEC_APPEND,
                        "qsay \"^1rspree_record: "..rec_msg.."^7\"\n")
        elseif srv_record and arg1 == stats_cmd then
            local stats_msg = statsMessage(id)
            et.trap_SendServerCommand( id, "b 8 \"^3statsme: ^7"..stats_msg.." ^7\"\n")
            --et.trap_SendConsoleCommand(et.EXEC_APPEND,
            --            "qsay \"^3stats: ^7"..stats_msg.."^7\"\n")
        end
    elseif arg0 == msg_command then
        if arg1 == "" then
            local status = "^8on^7"
            if client_msg[id] == false then
                status = "^8off^7"
            end
            et.trap_SendServerCommand(id,
                    string.format("b 8 \"^#(rsprees):^7 Messages are %s\"",
                            status))
        elseif tonumber(arg1) == 0 then
            setRSpreeMsg(id, false)
            et.trap_SendServerCommand(id,
                    "b 8 \"^#(rsprees):^7 Messages are now ^8off^7\"")
        else
            setRSpreeMsg(id, true)
            et.trap_SendServerCommand(id,
                    "b 8 \"^#(rsprees):^7 Messages are now ^8on^7\"")
        end
        return(1)
    end
    return(0)
end

function setRSpreeMsg(id, value)
    client_msg[id] = value
    if value then
        value = "1"
    else
        value = "0"
    end
    et.trap_SetUserinfo(id,
        et.Info_SetValueForKey(et.trap_GetUserinfo(id), "v_rsprees", value)
    )
end

function updateUInfoStatus(id)
    local rs = et.Info_ValueForKey(et.trap_GetUserinfo(id), "v_rsprees")
    if rs == "" then
        setRSpreeMsg(id, msg_default)
    elseif tonumber(rs) == 0 then
        client_msg[id] = false
    else
        client_msg[id] = true
    end
end


function et_ClientBegin(id)
    updateUInfoStatus(id)
end

function et_UserinfoChanged(id)
    updateUInfoStatus(id)
end


function statsMessage(id)
    local guid = getGuid(id)
    local name = playerName(id)
    if type(srv_records[guid]) ~= "table" then
        return("no reviving stats for "..name.."^7")
    else
        local done = 0
        local mo_rev = ""
        local mu_rev = ""
        local rev    = ""
        local msg    = name .. "^7 has "
        if srv_records[guid][2] ~= 0 then
            mo_rev = string.format("^8%d ^7monster revives", srv_records[guid][2])
        end
        if srv_records[guid][1] ~= 0 then
            mu_rev = string.format("^8%d ^7multi revives", srv_records[guid][1])
        end

        rev = string.format("revived a total of ^8%d ^7players", srv_records[guid][3])
        -- ouch, this is ugly ;>
        if srv_records[guid][2] == 0 and srv_records[guid][1] == 0 then
            msg = msg .. rev
        elseif srv_records[guid][2] ~= 0 and srv_records[guid][1] ~= 0 then
            msg = msg .. "made " .. mo_rev .. ", " .. mu_rev .. " and " ..rev
        else
            if srv_records[guid][2] ~= 0 then
                msg = msg .. "made " .. mo_rev .. " and " .. rev
            else -- srv_records[guid][1] ~= 0
                msg = msg .. "made " .. mu_rev .. " and " .. rev
            end
        end

        return(msg .. " since "..os.date(date_fmt, srv_records[guid][5]))
--        return(string.format("%s^7 has made %d monster revives, "
--                           .."%d multi revives and revived a total of %d "
--                           .."players since %s",
--                            name, srv_records[guid][2], srv_records[guid][1],
--                            srv_records[guid][3],
--                            os.date(date_fmt, srv_records[guid][5])))
    end
end

function recordMessage ()
    local func_start = et.trap_Milliseconds()

    local rec_arr     = {}
    local multi_rec   = { 0, nil }
    local monster_rec = { 0, nil }
    local revive_rec  = { 0, nil }
    local oldest      = 2147483647 -- 2^31 - 1

    table.foreach(srv_records,
        function (guid, arr)
            if arr[2] > monster_rec[1] then
                monster_rec = { arr[2], arr[4] }
            end

            if arr[1] > multi_rec[1] then
                multi_rec = { arr[1], arr[4] }
            end

            if arr[3] > revive_rec[1] then
                revive_rec = { arr[3], arr[4] }
            end

            if arr[5] < oldest then
                oldest = arr[5]
            end
        end)

    if monster_rec[2] ~= nil then
        table.insert(rec_arr,
                     string.format("%s ^8(^7%d monster revives^8)^7",
                                   monster_rec[2], monster_rec[1]))
    end

    if multi_rec[2] ~= nil then
        table.insert(rec_arr,
                     string.format("%s ^8(^7%d multi revives^8)^7",
                                   multi_rec[2], multi_rec[1]))
    end

    if revive_rec[2] ~= nil then
        table.insert(rec_arr,
                     string.format("^7%s ^8(^7%d revives^8)^7",
                                   revive_rec[2], revive_rec[1]))
    end

    et.G_Printf("rspree.lua: recordMessage(): %d ms\n",
                    et.trap_Milliseconds() - func_start)
    if table.getn(rec_arr) ~= 0 then
        return("^7Top revivers: ".. table.concat(rec_arr, ", "))
    else
        return("^7no records found :(")
    end
end

function et_ConsoleCommand()
    local cmd = et.trap_Argv(0)
    local i = 0
    if cmd == "rsprees" then
        et.G_Printf("rsprees: --------------------\n")
        for i=0, sv_maxclients do

            if revive_sprees[i] ~= nil and revive_sprees[i] ~= 0 then
                et.G_Printf("^7rsprees: %d %s^7 (%s)^7\n",
                            revive_sprees[i],
                            playerName(i),
                            teamName(tonumber(et.gentity_get(i,
                                                         "sess.sessionTeam"))))
            end
        end
        et.G_Printf("^7rsprees: --------------------\n")
        if max_id ~= nil then
            et.G_Printf("^7Max: %s^7 with %d\n", playerName(max_id), max_spree)
        end
        return(1)
    elseif cmd == "rspreesall" then
        et.G_Printf("^7Alltime reviving sprees:\n")
        table.foreach(alltime_stats,
            function (map, arr)
                et.G_Printf("rspreesall: %s: %s^7 with %d revives @%s\n",
                            map, arr[3], arr[1], os.date(date_fmt, arr[2]))
            end)
        et.G_Printf("^7Alltime reviving sprees END\n")
        return(1)
    elseif cmd == "rspreerecords" then
        et.G_Printf("^1rspree_records: %s\n", recordMessage())
        return(1)
    elseif cmd == "rspreedel" then
    	srv_records	= {}
      saveStats(record_cfg, srv_records)
    	et.G_Printf("^7All rspree-records has been deleted.\n")
        return(1)
    elseif cmd == "rspree_reset" then
    	alltime_stats	= {}
    	saveStats(spree_cfg, alltime_stats)
    	et.G_Printf("^7All sprees has been deleted.\n")
        return(1)        
    end

    if et.trap_Argv(0) == "pb_sv_kick" then
		if et.trap_Argc() >= 2 then
			local cno = tonumber(et.trap_Argv(1))
			if cno then
				cno = cno - 1
				et_ClientDisconnect(cno)
			end
		end
		return 1
	end
    return(0)
end
-- vim: ts=4 sw=4 expandtab syn=lua
