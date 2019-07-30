--
-- kspree.lua
--
-- $Id: kspree.lua 174 2007-02-28 19:17:56Z bennz $
-- $Date: 2007-02-28 20:17:56 +0100 (Mi, 28 Feb 2007) $
-- $Revision: 174 $
--
version = "1.0.4"

-- kspree.lua logic "stolen" from Vetinari's rspree.lua, who "stole" from etadmin_mod.pl and so on
-- CONSOLE COMMANDS : ksprees, kspeesall, kspreerecords
-- added: new readRecords() function
-- added: First Blood + Last Blood
-- added: Greatshot option, display last killers name v56
-- added: Sorry option, display last TKed's name v45
-- added: spree announcement can be disabled
-- FIXME: recordMessage() does not work everytime -- FIXED !!!
-- FIXME: use wait_table[id] ~= nil --FIXED mmmhhh :/ ???
--
-- If you run etadmin_mod, change the following lines in "etadmin.cfg"
--      spree_detector          = 0
--      longest_spree_display     = 0 
--      persistent_spree_record     = 0
--      persistent_map_spree_record   = 0
--      first_blood           = 0
--      multikill_detector        = 0
--      monsterkill_detector      = 0
--      last_blood            = 0
--
-------------------------------------------------------------------------------------
-------------------------------CONFIG START------------------------------------------

-- ######## announce_hp
announce_hp = true
announce_hp_pos = "b 32"      -- console only 64
-- ######## announce_hp_pos => http://wolfwiki.anime.net/index.php/SendServerCommand


kspree_cfg    = "killingspree.txt"
record_cfg   = "kspree-records.txt"

date_fmt     = "%Y-%m-%d, %H:%M:%S"

kmultitk_announce = true      -- announce multi TK
kmulti_announce   = true      -- announce multi/mega/ultra....kill
kspree_announce   = true      -- announce sprees

kmulti_sound      = true      -- multi-sounds
kspree_sound    = true      -- spree-sounds

first_blood     = true      -- display First Blood
last_blood      = true      -- display Last Blood

kmulti_pos        = "b 8"     -- multi + megakill - position 8
kmonster_pos      = "b 32"    -- ultra + monster + ludicrous + holy shit - position
kmultitk_pos    = "b 32"    -- multi TK - position
kspree_pos        = "b 8"     -- killing spree position 8
kspree_color      = "8"     -- killing spree color

-- mod selection harle rip off
gamename = et.trap_Cvar_Get("gamename")
if (gamename == "etpub" or gamename == "nq")  then
kspree_pos    = "chat" -- see http://wolfwiki.anime.net/index.php/SendServerCommand for valid locations
kmulti_pos      = "chat"
kmonster_pos    = "chat" -- b 32 == cp (this info is for harle :o))
announce_hp = false
announce_hp_pos = "chat"      -- console only
end
-- mod selection harle rip off

kmulti_msg        = "^7!!!! ^1Multi kill ^7> ^7%s ^7< ^1Multi kill^7 !!!!"
kmega_msg   = "^7!!!! ^1Mega kill ^7> ^7%s ^7< ^1Mega kill^7 !!!!"
kultra_msg        = "^7!!! ^1ULTRA KILL ^7> ^7%s ^7< ^1ULTRA KILL^7 !!!"
kmonster_msg      = "^7!!! ^1MONSTER KILL ^7>>> ^7%s ^7<<< ^1MONSTER KILL^7 !!!"
kludicrous_msg    = "^7OMG,^1LUDICROUS KILL ^7>>> ^7%s ^7<<< ^1LUDICROUS KILL^7"
kholyshit_msg   = "^1H O L Y  S H I T ^7>>> ^7%s ^7<<< ^1H O L Y  S H I T^7"
kmultitk_msg    = "^7!!! ^1Multi Teamkill ^7> ^7%s ^7< ^1Multi Teamkill^7 !!!"

firstbloodsound   = "sound/misc/firstblood.wav"
multisound    = "sound/misc/multikill.wav"
megasound   = "sound/misc/megakill.wav"
ultrasound    = "sound/misc/ultrakill.wav"
monstersound    = "sound/misc/monsterkill.wav"
ludicroussound    = "sound/misc/ludicrouskill.wav"
holyshitsound     = "sound/misc/holyshit.wav"
multitksound    = "sound/misc/teamkiller.wav"
killingspreesound = "sound/misc/killingspree.wav"
rampagesound    = "sound/misc/rampage.wav"
dominatingsound   = "sound/misc/dominating.wav"
godlikesound    = "sound/misc/godlike.wav"
unstoppablesound  = "sound/misc/unstoppable.wav"
wickedsicksound   = "sound/misc/wickedsick.wav"
pottersound     = "sound/misc/potter.wav"

killingspree_private  = false    -- send killingspree message + sound to client only, if set to true
                  -- (You are on a killing spree), all other messages are global messages, like rampage and so on

kspree_cmd_enabled  = true      -- set to false to ignore the "kspree_cmd"
kspree_cmd      = "!spree_record"

record_cmd      = "!top"  -- command to print players with most multi,mega,ultra... kills
stats_cmd       = "!statspub"   -- same as etadmin_mod's "!stats", prints personal killing records (i.e. multi,mega,ultra... kills)
statsme_cmd     = "!stats"  -- shows ur personal killing stats (private)

srv_record      = true      -- set to true, if u want to save killing stats
record_last_nick  = true      -- set to true to keep the last known nick a guid has
records_expire    = 60*60*24*90   -- in seconds! 60*60*24*5 == 5 days

allow_spree_sk    = true      -- allow new killing spree record, even if he killed himself

great_shot      = true      -- name of ur killer will be added if u vsay "GreatShot" within "great_shot_time" ms
great_shot_time   = 5000      -- 5000 = 5 seconds = Five SECONDS
great_shot_repeat   = false     -- set to true, name will be added everytime u vsay Greatshot within "great_shot_time" ms

sorry       = true      -- name of ur last tk will be added if u vsay_team "Sorry" within "sorry_time" ms
sorry_time      = 9000      -- 9000 = 9 seconds = Nine SECONDS
sorry_repeat    = false     -- set to true, name will be added everytime u vsay_team "sorry" within "sorry_time" ms

save_awards = true          -- save Ludicrouskill + Holy Shit + Multi TK in textfile "awards_file"
awards_file = "awards.txt"

msg_command = "ksprees"       -- '\ksprees 1|0' to switch on / off the messages and sounds
                  -- clients can set their default with 'setu b_ksprees 1' (or 0)
msg_default = true          -- print kspree messages to client if true

K_Sprees = {            -- adjust them to ur needs
     [5] = "is on a killing spree",
    [10] = "is on a rampage!",
    [15] = "is dominating!",
    [20] = "is unstoppable!!",
    [25] = "is godlike!!!",
    [30] = "is wicked sick!!!!",
    [35] = "is real POTTER!!!!!",
}

-------------------------------CONFIG END -------------------------------------------
-------------------------------------------------------------------------------------

et.MAX_WEAPONS = 50
EV_GLOBAL_CLIENT_SOUND = 54
killing_sprees = {}
kmax_spree     = 0
kmax_id        = nil
alltime_stats = {}
kmulti         = {}
kmultitk    = {}
wait_table  = {}
kmap_record    = false
srv_records = {}
kendofmap      = false
keomap_done    = false
gamestate   = -1
last_b    = ""
last_killer = {}
last_tk = {}
client_msg = {}

kteams = { [0]="Spectator", [1]="Axis", [2]="Allies", [3]="Unknown", }

function et_InitGame(levelTime, randomSeed, restart)

    local func_start = et.trap_Milliseconds()
    et.RegisterModname("kspree.lua "..version.." "..et.FindSelf())
    sv_maxclients = tonumber(et.trap_Cvar_Get("sv_maxclients"))

    local i = 0
    for i=0, sv_maxclients-1 do
        killing_sprees[i] = 0
        kmulti[i] = { [1]=0, [2]=0, }
        client_msg[i] = false
        if kmultitk_announce then
          kmultitk[i]   = { [1]=0, [2]=0, }
        end
    end

    i = readStats(kspree_cfg)
    et.G_Printf("kspree.lua: loaded %d alltime stats from %s\n", i, kspree_cfg)

    if srv_record then
        i = readRecords(record_cfg)
        et.G_Printf("kspree.lua: loaded %d alltime records from %s\n", i, record_cfg)
    end

--    et.trap_SendConsoleCommand(et.EXEC_NOW,"sets KSpree_version "..version)
    et.G_Printf("bennz's kspree.lua version "..version.." activated...\n")
  et.G_Printf("kspree.lua: startup: %d ms\n", et.trap_Milliseconds() - func_start)
end

function sayClients(pos, msg)
    --et.G_Printf("kspree.lua: sayClients('%s', '%s')\n", pos, msg)
    --et.trap_SendServerCommand(-1, pos.." \""..msg.."^7\"\n")
    local message = string.format("%s \"%s^7\"", pos, msg)
    table.foreach(client_msg,
    function(id, msg_ok)
            if msg_ok then
                et.trap_SendServerCommand(id, message)
            end
        end
    )
end

function soundClients(which_sound)
    table.foreach(client_msg,
    function(id, msg_ok)
            if msg_ok then
                et.G_ClientSound(id, which_sound)
            end
        end
    )
end

-- printf wrapper for debugging
function et.G_Printf(...)
    et.G_Print(string.format(unpack(arg)))
end

et.G_LogPrintf = function(...)
    et.G_LogPrint(string.format(unpack(arg)))
end

function et.G_ClientSound(clientnum, soundfile)
    local tempentity = et.G_TempEntity(et.gentity_get(clientnum, "r.currentOrigin"), EV_GLOBAL_CLIENT_SOUND)
    et.gentity_set(tempentity, "s.teamNum", clientnum)
    et.gentity_set(tempentity, "s.eventParm", et.G_SoundIndex(soundfile))
end

function mapName ()
    return(string.lower(et.trap_Cvar_Get("mapname")))
end

function teamName (t)
    if t < 0 or t > 3 then
        t = 3
    end
    return(kteams[t])
end

function getGuid (id)
    return(string.lower(et.Info_ValueForKey(et.trap_GetUserinfo(id), "cl_guid")))
end

function playerName(id)
    return(et.Info_ValueForKey(et.trap_GetUserinfo(id), "name"))
end

function findMaxKSpree()
    local max = alltime_stats[mapName()]
    if max == nil then
        max = {}
    end
    return(max)
end

function saveStats(file, list)
    local fd, len = et.trap_FS_FOpenFile(file, et.FS_WRITE)
    if len == -1 then
        et.G_Printf("kspree.lua: failed to open %s", file)
        return(0)
    end
    local head = string.format("# %s, written %s\n", file, os.date())
    et.trap_FS_Write(head, string.len(head), fd)
    table.foreach(list,
        function (first, arr)
            local line = first .. ";".. table.concat(arr, ";").."\n"
            et.trap_FS_Write(line, string.len(line), fd)
        end
    )
    et.trap_FS_FCloseFile(fd)
end

function readStats(file)
    local fd,len = et.trap_FS_FOpenFile( file, et.FS_READ )
    local count      = 0
    if len == -1 then
        et.G_Printf("kspree.lua: no killingspree.txt\n")
        return(0)
    end
    local filestr = et.trap_FS_Read( fd, len )
    et.trap_FS_FCloseFile( fd )
    local map, frags, zwiebel, naim
    for map, frags, zwiebel, naim in string.gfind(filestr,"[^%#]([%_%w]*)%;(%d*)%;(%d*)%;([^%\n]*)") do
        alltime_stats[map] = {
            tonumber(frags),
            tonumber(zwiebel),
            naim
        }
        count = count + 1
    end

    return(count)
end

function readRecords(file)
    local func_start = et.trap_Milliseconds()
    local fd,len = et.trap_FS_FOpenFile( file, et.FS_READ )
    local count      = 0

    if len == -1 then
        et.G_Printf("kspree.lua: no Spree Records \n")
        et.G_Printf("rspree.lua: readRecords(): %d ms\n", et.trap_Milliseconds() - func_start)
        return(0)
    end

    local guid,multi,mega,ultra,monster,ludic,kills,name,first,last
    local now = tonumber(os.date("%s"))
    local exp_diff = now - records_expire
    local filestr = et.trap_FS_Read( fd, len )
    et.trap_FS_FCloseFile( fd )
    for guid,multi,mega,ultra,monster,ludic,kills,name,first,last in string.gfind(filestr,
        "[^%#](%x+)%;(%d*)%;(%d*)%;(%d*)%;(%d*)%;(%d*)%;(%d*)%;([^;]*)%;(%d*)%;([^%\n]*)") do
        local seen = tonumber(last)
        if (records_expire == 0) or (exp_diff < seen) then
            srv_records[guid] = {
                tonumber(multi),
                tonumber(mega),
                tonumber(ultra),
                tonumber(monster),
                tonumber(ludic),
                tonumber(kills),
                name,
                tonumber(first),
                seen
            }
            count = count + 1
        end
    end


    et.G_Printf("kspree.lua: readRecords(): %d ms\n", et.trap_Milliseconds() - func_start)
    return(count)
end


function et_Print(text)

    if kendofmap and string.find(text, "^WeaponStats: ") == 1 then

        if not keomap_done then
            if kmax_id ~= nil then
                local re_name = playerName(kmax_id)
                if re_name == "" then
                    re_name = "^0MIA" -- missing in action
                end
                local longest = ""
                local max     = findMaxKSpree()
                if table.getn(max) == 3 then
                    if kmap_record then
                        longest = " ^"..kspree_color.."This is a New map record!"
                        saveStats(kspree_cfg, alltime_stats)
                    else
                        longest = string.format(" ^7[record: %d by %s^7 @%s]",
                                                    max[1], max[3], os.date(date_fmt, max[2]))
                    end
                end
                local msg = string.format("^7Longest killing spree: %s^7 with %d kills!%s",
                                            re_name, kmax_spree, longest)
                if kspree_announce then
                    et.trap_SendConsoleCommand(et.EXEC_APPEND, "qsay \""..msg.."^7\"\n")
                end
            end
            if srv_record then
                saveStats(record_cfg, srv_records)
            end
            keomap_done = true
        end
        return(nil)
    end

    if text == "Exit: Timelimit hit.\n" or text == "Exit: Wolf EndRound.\n" then
        kendofmap = true
        for i = 0, sv_maxclients-1 do
            if killing_sprees[i] > 0 then
                checkKSpreeEnd(i, 1022, true)
            end
        end
        if last_b ~= "" and last_blood then
            msg = string.format("^7And the final kill of this round goes to: %s ^7!", last_b )
            et.trap_SendConsoleCommand(et.EXEC_APPEND, "qsay \""..msg.."^7\"\n")
        end
        return(nil)
    end
end

function checkMultiKill (id)
    local lvltime = et.trap_Milliseconds()
    local guid = getGuid(id)
    if (lvltime - kmulti[id][1]) < 3000 then
        kmulti[id][2] = kmulti[id][2] + 1

        if kmulti[id][2] == 3 then
            wait_table[id] = {lvltime, 1}
        elseif kmulti[id][2] == 4 then
            wait_table[id] = {lvltime, 2}
        elseif kmulti[id][2] == 5 then
            wait_table[id] = {lvltime, 3}
        elseif kmulti[id][2] == 6 then
            wait_table[id] = {lvltime, 4}
        elseif kmulti[id][2] == 7 then
            wait_table[id] = {lvltime, 5}
            if save_awards then add_qwnage(id, 1) end
        elseif kmulti[id][2] == 8 then
            wait_table[id] = {lvltime, 6}
            if save_awards then add_qwnage(id, 2) end
        end
    else
        kmulti[id][2] = 1
    end
    kmulti[id][1] = lvltime
end

function checkMultiTk(id)
    local lvltime = et.trap_Milliseconds()

    if (lvltime - kmultitk[id][1]) < 3000 then
        kmultitk[id][2] = kmultitk[id][2] + 1
        if kmultitk[id][2] == 3 then
            sayClients(kmultitk_pos, string.format(kmultitk_msg, playerName(id)))
            et.G_globalSound(multitksound)
            if save_awards then
                add_qwnage(id, 3)
            end
            -- send to irc-bot
            --et.G_LogPrintf("say: Mony: !admin2monitor %s 00,01has made a Multi TK.02,15 Everyone has agreed that Speed0 is to blame!!!\n",
            --playerName(id)
            --)
        end
    else
        kmultitk[id][2] = 1
    end

    kmultitk[id][1] = lvltime
end

function et_Obituary(victim, killer, mod)
    if gamestate == 0 then
        local v_teamid = et.gentity_get(victim, "sess.sessionTeam")
        local k_teamid = et.gentity_get(killer, "sess.sessionTeam")
        local weapon = et.gentity_get(victim, "s.weapon")
        if (victim == killer) then -- suicide

            if mod == 37 then
                if not allow_spree_sk then
                    local max = findMaxKSpree()
                    if table.getn(max) == 3 then
                        if killing_sprees[victim] > max[1] and kspree_announce then
                            sayClients(kspree_pos, string.format("^%sWhat a pity! ^7%s^%s killed himself. This would have been a new ^qspree record ^%s!",
                            kspree_color, playerName(victim), kspree_color, kspree_color))
                        end
                    end
                else
                    checkKSpreeEnd(victim, killer, false)
                end
            end

            killing_sprees[victim] = 0

        elseif (v_teamid == k_teamid) then -- team kill

            if kmultitk_announce then
                checkMultiTk(killer)
            end

            if sorry then
                last_tk[killer] = {playerName(victim) , et.trap_Milliseconds()}
            end

            checkKSpreeEnd(victim, killer, false)
            killing_sprees[victim] = 0

        else -- nomal kill
            if killer ~= 1022 and killer ~= 1023 then -- no world / unknown kills

                killing_sprees[killer] = killing_sprees[killer] + 1
                local guid = getGuid(killer)

                if srv_record and guid ~= "" then
                    -- guid;multi;mega;ultra;monster;ludicrous;revive;nick;firstseen;lastseen
                    if type(srv_records[guid]) ~= "table" then
                        srv_records[guid] = { 0, 0, 0, 0, 0, 0, playerName(killer), tonumber(os.date("%s")), 0 }
                    elseif table.getn(srv_records[guid]) ~= 9 then
                        srv_records[guid] = { 0, 0, 0, 0, 0, 0, playerName(killer), tonumber(os.date("%s")), 0 }
                    end
                    srv_records[guid][6] = srv_records[guid][6] + 1
                    srv_records[guid][9] = tonumber(os.date("%s"))
                    if record_last_nick or (srv_records[guid][7] == nil) then
                        srv_records[guid][7] = playerName(killer)
                    end
                end

                if killing_sprees[killer] > kmax_spree then
                    kmax_spree = killing_sprees[killer]
                    kmax_id    = killer
                end

                if great_shot then
                  last_killer[victim] = { playerName(killer), et.trap_Milliseconds() }
                end

                if first_blood then
                    sayClients(kmonster_pos, string.format("%s ^1drew first BLOOD ^7!", playerName(killer) ))
                    --et.G_globalSound(firstbloodsound)
                    soundClients(firstbloodsound)
                    first_blood = false
                end

                if last_blood then
                    last_b = playerName(killer)
                end

                checkMultiKill(killer)

                if kspree_announce then
                  checkKSprees(killer)
                end

                checkKSpreeEnd(victim, killer, true)

                -- announce_hp
                if announce_hp then
                  local killerhp = et.gentity_get(killer, "health")
                  if killerhp < 0 then
                    et.trap_SendServerCommand(victim, string.format(announce_hp_pos .. " \"^zAnnounce HP: " .. playerName(killer) ..  " ^zwas dead.\n"))
                  else
                    et.trap_SendServerCommand(victim, string.format(announce_hp_pos .. " \"^zAnnounce HP: " .. playerName(killer) ..  " ^zhad ^1" .. killerhp .. " ^zHP left.\n"))
                  end
                end
            else
                checkKSpreeEnd(victim, killer, false)
            end
            killing_sprees[victim] = 0
        end
    end -- gamestate
end

function checkKSpreeEnd(id, killer, normal_kill)
    if killing_sprees[id] > 0 then
        local m_name = playerName(id)
        if m_name == "" then
            m_name = "^0MIA" -- missing in action
        end
        local k_name = ""
        if killer == 1022 then
            k_name = "End of Round"
        elseif killer == 1023 then
            k_name = "unknown reasons"
        else
            k_name = playerName(killer)
        end
        local krecord = false
        local msg    = ""

        if kmax_id == id and killing_sprees[id] == kmax_spree then
            local max = findMaxKSpree()
            if table.getn(max) == 3 and kmax_spree > max[1] then
                alltime_stats[mapName()] = { kmax_spree, os.date("%s"), m_name }
                kmap_record = true
                krecord     = true
            elseif table.getn(max) == 0 then
                alltime_stats[mapName()] = { kmax_spree, os.date("%s"), m_name }
                kmap_record = true
                krecord     = true
            end
        end

        if killing_sprees[id] >= 5 and kspree_announce then
            if normal_kill then -- i.e. no TK or suicide
                sayClients(kspree_pos, string.format("%s^%s's killing spree ended (^7%d kills^%s), killed by ^7%s^%s!",
                    m_name, kspree_color, killing_sprees[id], kspree_color, k_name, kspree_color))
                if krecord then
                    sayClients(kspree_pos, "^"..kspree_color.."This is a new map record!^7")
                end

            else
                if krecord and killer <= sv_maxclients then
                    sayClients(kspree_pos, string.format("%s^%s's killing spree ended (^7%d kills^%s).",
                                                        m_name, kspree_color, killing_sprees[id], kspree_color))
                    sayClients(kspree_pos, "^"..kspree_color.."This is a new map record !^7")
                end
            end
        end
    end
end

function checkKSprees(id)
    if killing_sprees[id] ~= 0 then
        if math.mod(killing_sprees[id], 5) == 0 then
            local spree_id = killing_sprees[id]
            local spree = K_Sprees[killing_sprees[id]]
            if killing_sprees[id] > 35 then
                spree = K_Sprees[35]
            end
            if spree == nil then
                spree = "is on a Killing spree"
                et.G_Printf("kspree: Killing spree = nil\n")
            end

            if spree_id == 5 then
                if killingspree_private and client_msg[id] then
                    local craap = string.format("%s^%s: You are on a killing spree! (^75 kills in a row^%s)",
                    playerName(id), kspree_color, kspree_color)
                    et.trap_SendServerCommand( id, "b 8 \" "..craap.." \"\n")
                    --et.G_Sound( id ,  et.G_SoundIndex("sound/misc/killingspree.wav"))
                    et.G_ClientSound(id, killingspreesound)
                else
                    sayClients(kspree_pos, string.format("%s^%s %s (^7%d kills in a row^%s)",
                    playerName(id), kspree_color, spree, killing_sprees[id], kspree_color))
                    if kspree_sound then
                    soundClients(killingspreesound)
                    --et.G_globalSound(killingspreesound)
                    end
                end
            else
                sayClients(kspree_pos, string.format("%s^%s %s (^7%d kills in a row^%s)",
                    playerName(id), kspree_color, spree, killing_sprees[id], kspree_color))
                if spree_id == 10 and kspree_sound then
                    --et.G_globalSound(rampagesound)
                    soundClients(rampagesound)

                elseif spree_id == 15 and kspree_sound then
                    --et.G_globalSound(dominatingsound)
                    soundClients(dominatingsound)

                elseif spree_id == 20 and kspree_sound then
                    --et.G_globalSound(unstoppablesound)
                    soundClients(unstoppablesound)

                elseif spree_id == 25 and kspree_sound then
                    --et.G_globalSound(godlikesound)
                    soundClients(godlikesound)

                elseif spree_id == 30 and kspree_sound then
                    --et.G_globalSound(wickedsicksound)
                    soundClients(wickedsicksound)

                elseif spree_id == 35 and kspree_sound then
                    --et.G_globalSound(pottersound)
                    soundClients(pottersound)
                end
            end --spree_id == 5
        end
    end
end

function et_RunFrame(levelTime)
    if math.mod(levelTime, 500) ~= 0 then return end

    local ltm = et.trap_Milliseconds()
    gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
    if gamestate == 0 then
        -- wait before display multi/mega/monster/ludicrous-kill AND display highest
        -- wait_table[id] = {lvltime, 2}
        table.foreach(wait_table,
            function(id, arr)
            local guid = getGuid(id)
            local m_name = playerName(id)
            local startpause = tonumber(arr[1])
            local whichkill = arr[2]

            if whichkill == 1 and (startpause + 3100) < ltm then
                if kmulti_announce then
                    sayClients(kmulti_pos, string.format(kmulti_msg, m_name))
                    if kmulti_sound then
                        --et.G_globalSound(multisound)
                        soundClients(multisound)
                    end
                end
                if srv_record and guid ~= "" then
                    srv_records[guid][1] = srv_records[guid][1] + 1
                end
                wait_table[id] = nil
            end

            if whichkill == 2 and (startpause + 3100) < ltm then
                if kmulti_announce then
                    sayClients(kmulti_pos, string.format(kmega_msg, m_name))
                    if kmulti_sound then
                        --et.G_globalSound(megasound)
                        soundClients(megasound)
                    end
                end
                if srv_record and guid ~= "" then
                    srv_records[guid][2] = srv_records[guid][2] + 1
                end
                wait_table[id] = nil
            end

            if whichkill == 3 and (startpause + 3100) < ltm then
                if kmulti_announce then
                    sayClients(kmonster_pos, string.format(kultra_msg, m_name))
                    if kmulti_sound then
                        --et.G_globalSound(ultrasound)
                        soundClients(ultrasound)
                    end
                end
                if srv_record and guid ~= "" then
                    srv_records[guid][3] = srv_records[guid][3] + 1
                end
                wait_table[id] = nil
            end

            if whichkill == 4 and (startpause + 3100) < ltm then
                if kmulti_announce then
                    sayClients(kmonster_pos, string.format(kmonster_msg, m_name))
                    if kmulti_sound then
                        --et.G_globalSound(monstersound)
                        soundClients(monstersound)
                    end
                end
                if srv_record and guid ~= "" then
                    srv_records[guid][4] = srv_records[guid][4] + 1
                end
                wait_table[id] = nil
            end

            if whichkill == 5 and (startpause + 3100) < ltm then
                if kmulti_announce then
                    sayClients(kmonster_pos, string.format(kludicrous_msg, m_name))
                    if kmulti_sound then
                    --et.G_globalSound(ludicroussound)
                    soundClients(ludicroussound)
                    end
                end
                if srv_record and guid ~= "" then
                    srv_records[guid][5] = srv_records[guid][5] + 1
                end
                wait_table[id] = nil
            end

            if whichkill == 6 and (startpause + 900) < ltm then
                if kmulti_announce then
                    sayClients(kmonster_pos, string.format(kholyshit_msg, m_name))
                    if kmulti_sound then
                        --et.G_globalSound(holyshitsound)
                        soundClients(holyshitsound)
                    end
                end
                wait_table[id] = nil
            end
        end) --end table.foreach
    end -- gamestate
end

function et_ClientBegin(id)
    updateUInfoStatus(id)
end

function et_ClientDisconnect(id)
    killing_sprees[id] = 0
    client_msg[id] = false
    if great_shot and last_killer[id] ~= nil then
        last_killer[id] = nil
    end
    if sorry and last_tk[id] ~= nil then
        last_tk[id] = nil
    end
    if wait_table[id] ~= nil then
        wait_table[id] = nil
    end
end

function et_ClientCommand(id, command)

    if et.trap_Argv(0) == "say" then
        if et.gentity_get(id, "sess.muted") == 1 then return 1 end

        if kspree_cmd_enabled and et.trap_Argv(1) == kspree_cmd then
            local map_msg = ""
            local map_max = findMaxKSpree()
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
                    all_max[3], all_max[1], os.date(date_fmt, all_max[2]))
            end
            et.trap_SendConsoleCommand(et.EXEC_APPEND, "qsay \"^1kspree_record: "..map_msg..all_msg.."^7\"\n")
        elseif et.trap_Argv(1) == record_cmd and srv_record then
            local rec_msg     = recordMessage()
            et.trap_SendConsoleCommand(et.EXEC_APPEND, "qsay \"^1kspree_record: "..rec_msg.."^7\"\n")
        elseif et.trap_Argv(1) == stats_cmd and srv_record then
            local stats_msg = statsMessage(id)
            et.trap_SendConsoleCommand(et.EXEC_APPEND, "qsay \"^3stats: ^7"..stats_msg.."^7\"\n")
        elseif et.trap_Argv(1) == statsme_cmd and srv_record then
            local statsme_msg = statsMessage(id)
            et.trap_SendServerCommand( id, "b 8 \"^3statsme: ^7"..statsme_msg.." ^7\"\n")
            return(1)
        end -- end elseif...
    end -- et.trap_Argv(0) == "say"

    if et.trap_Argv(0) == msg_command then
        if et.trap_Argv(1) == "" then
            local status = "^8on^7"
            if client_msg[id] == false then
                status = "^8off^7"
            end
            et.trap_SendServerCommand(id,
                    string.format("b 8 \"^#(ksprees):^7 Messages are %s\"",
                            status))
        elseif tonumber(et.trap_Argv(1)) == 0 then
            setKSpreeMsg(id, false)
            et.trap_SendServerCommand(id,
                    "b 8 \"^#(ksprees):^7 Messages are now ^8off^7\"")
        else
            setKSpreeMsg(id, true)
            et.trap_SendServerCommand(id,
                    "b 8 \"^#(ksprees):^7 Messages are now ^8on^7\"")
        end
        return(1)
    end

    if et.trap_Argv(0) == "vsay" then
        if not great_shot then return end

        local vsaystring = ParseString(et.trap_Argv(1))
        if string.lower(vsaystring[1]) == "greatshot" and last_killer[id] ~= nil and table.getn(vsaystring) < 2 then
            if (et.trap_Milliseconds() - tonumber(last_killer[id][2])) < great_shot_time then
                local vsaymessage = "Great shot, ^7"..last_killer[id][1].."^r!"
                et.trap_SendServerCommand(-1, "vchat 0 "..id.." 50 GreatShot "..math.random(1, 2).." \""..vsaymessage.."\"")
                if not great_shot_repeat then
                  last_killer[id] = nil
                end
                return(1)
            else
                return(0)
            end

        end -- end lower
    end -- vsay

    if et.trap_Argv(0) == "vsay_team" then
        if not sorry then return end

        local vsaystring = ParseString(et.trap_Argv(1))
        if string.lower(vsaystring[1]) == "sorry" and last_tk[id] ~= nil and table.getn(vsaystring) < 2 then
            if (et.trap_Milliseconds() - tonumber(last_tk[id][2])) < sorry_time then
                local vsaymessage = "^5Sorry, ^7"..last_tk[id][1].."^5!"
                local ppos = et.gentity_get(id,"r.currentOrigin")
                local TKer_team = et.gentity_get(id, "sess.sessionTeam")
                local cmd = string.format("vtchat 0 %d 50 Sorry %d %d %d %d \"%s\"", id, ppos[1], ppos[2], ppos[3], math.random(1,3), vsaymessage)
                for t=0, sv_maxclients-1, 1 do
                    if et.gentity_get(t, "sess.sessionTeam") == TKer_team then
                    et.trap_SendServerCommand(t, cmd)
                    end
                end
                if not sorry_repeat then
                  last_tk[id] = nil
                end

                return(1)
            else
                return(0)
            end
        end -- end lower
    end -- vsay_team

    return(0)
end

function setKSpreeMsg(id, value)
    client_msg[id] = value
    if value then
        value = "1"
    else
        value = "0"
    end
    et.trap_SetUserinfo(id,
        et.Info_SetValueForKey(et.trap_GetUserinfo(id), "b_ksprees", value)
    )
end

function updateUInfoStatus(id)
    local rs = et.Info_ValueForKey(et.trap_GetUserinfo(id), "b_ksprees")
    if rs == "" then
        setKSpreeMsg(id, msg_default)
    elseif tonumber(rs) == 0 then
        client_msg[id] = false
    else
        client_msg[id] = true
    end
end

function ParseString(inputString)
    local i = 1
    local t = {}
    for w in string.gfind(inputString, "([^%s]+)%s*") do
        t[i]=w
        i=i+1
    end
    return t
end

function statsMessage(id)
    local guid = getGuid(id)
    local stats_arr = {}
    local name = playerName(id)
    if type(srv_records[guid]) ~= "table" then
        return("no killing stats for "..name.."^7")
    else
        local i = 1
        for i=1, 5 do
            if srv_records[guid][i] > 0 then
                local whatkill = ""
                if i == 1 then whatkill = "Multikills,"
                    elseif i == 2 then whatkill = "Megakills,"
                    elseif i == 3 then whatkill = "Ultrakills,"
                    elseif i == 4 then whatkill = "Monsterkills,"
                    elseif i == 5 then whatkill = "Ludicrouskills"
                end
                table.insert(stats_arr, string.format("^8%d ^7%s", srv_records[guid][i], whatkill))
            end
        end
        local whathedid = ""
        if table.getn(stats_arr) ~= 0 then
            table.insert(stats_arr, 1, string.format("^7 has made:"))
            table.insert(stats_arr, string.format("^7and"))
            whathedid = table.concat(stats_arr, " ")
        end

        return(string.format("%s^7%s killed a total of ^8%d ^7players since %s",
                            name, whathedid ,srv_records[guid][6],
                            os.date(date_fmt, srv_records[guid][8])))
    end
end

function recordMessage ()
    local rec_arr     = {}
    local multi_rec   = { 0, nil }
    local mega_rec   = { 0, nil }
    local ultra_rec   = { 0, nil }
    local monster_rec = { 0, nil }
    local ludicrous_rec   = { 0, nil }
    local kill_rec  = { 0, nil }

    --multikill
    table.foreach(srv_records,
        function (guid, arr)
            if arr[1] > multi_rec[1] then
                multi_rec = { arr[1], arr[7] }
            end
            if arr[2] > mega_rec[1] then
                mega_rec = { arr[2], arr[7] }
            end
            if arr[3] > ultra_rec[1] then
                ultra_rec = { arr[3], arr[7] }
            end
            if arr[4] > monster_rec[1] then
                monster_rec = { arr[4], arr[7] }
            end
            if arr[5] > ludicrous_rec[1] then
                ludicrous_rec = { arr[5], arr[7] }
            end
            if arr[6] > kill_rec[1] then
                kill_rec = { arr[6], arr[7] }
            end

        end)

    if multi_rec[2] ~= nil then
        table.insert(rec_arr,
                     string.format("^7%s ^8(^7%d Multikills^8)^7",
                                   multi_rec[2], multi_rec[1]))
    end

    if mega_rec[2] ~= nil then
        table.insert(rec_arr,
                     string.format("^7%s ^8(^7%d Megakills^8)^7",
                                   mega_rec[2], mega_rec[1]))
    end

    if ultra_rec[2] ~= nil then
        table.insert(rec_arr,
                     string.format("^7%s ^8(^7%d Ultrakills^8)^7",
                                   ultra_rec[2], ultra_rec[1]))
    end

    if monster_rec[2] ~= nil then
        table.insert(rec_arr,
                     string.format("^7%s ^8(^7%d Monsterkills^8)^7",
                                   monster_rec[2], monster_rec[1]))
    end

    if ludicrous_rec[2] ~= nil then
        table.insert(rec_arr,
                     string.format("^7%s ^8(^7%d Ludicrouskills^8)^7",
                                   ludicrous_rec[2], ludicrous_rec[1]))
    end

    if kill_rec[2] ~= nil then
        table.insert(rec_arr,
                     string.format("^7%s ^8(^7%d kills^8)^7",
                                  kill_rec[2], kill_rec[1]))
    end

    if table.getn(rec_arr) ~= 0 then
        local oldest = 2147483647 -- 2^31 - 1
        table.foreach(srv_records,
            function(guid, arr)
                if arr[8] < oldest then
                    oldest = arr[8]
                end
            end)
        return("^7Top killers: "..table.concat(rec_arr, ", "))
    else
        return("^7no records found :(")
    end
end

function add_qwnage(id, woot)
    local fdqwnage,len = et.trap_FS_FOpenFile( "awards.txt", et.FS_APPEND )
    if len == -1 then
        et.G_Printf("kspree.lua: failed to save awards for %s\n", playerName(id))
    else
        if woot == 1 then
            qwnage = playerName(id).. " - Ludicrous Kill - "..os.date().."\n"
        elseif woot == 2 then
            qwnage = playerName(id).. " - Holy Shit - "..os.date().."\n"
        elseif woot == 3 then
            qwnage = playerName(id).. " - Multi TK - "..os.date().."\n"
        end
        et.trap_FS_Write( qwnage, string.len(qwnage) ,fdqwnage )
        et.trap_FS_FCloseFile( fdqwnage )
    end
    return(1)
end

function et_ConsoleCommand()
    local cmd = et.trap_Argv(0)
    local i = 0
    if cmd == "ksprees" then
        et.G_Printf("ksprees: --------------------\n")
        for i=0, sv_maxclients-1 do

            if killing_sprees[i] ~= nil and killing_sprees[i] ~= 0 then
                et.G_Printf("^7ksprees: %d %s^7 (%s)^7\n",
                            killing_sprees[i],
                            playerName(i),
                            teamName(tonumber(et.gentity_get(i, "sess.sessionTeam"))))
            end
        end
        et.G_Printf("^7ksprees: --------------------\n")
        if kmax_id ~= nil then
            et.G_Printf("^7Max: %s^7 with %d\n", playerName(kmax_id), kmax_spree)
        end
        return(1)
    elseif cmd == "kspreesall" then
        et.G_Printf("^7Alltime killing sprees:\n")
        table.foreach(alltime_stats,
            function (map, arr)
            et.G_Printf("kspreesall: %s: %s^7 with %d kills @%s\n", map, arr[3], arr[1], os.date(date_fmt, arr[2]))
            end
        )
        et.G_Printf("^7Alltime killing sprees END\n")
        return(1)
    elseif cmd == "kspreerecords" then
        et.G_Printf("^1kspree_records: %s\n", recordMessage())
        return(1)
    elseif cmd == "kspreedel" then
        srv_records = {}
        saveStats(record_cfg, srv_records)
        et.G_Printf("^7All kspree-records has been deleted.\n")
        return(1)
    elseif cmd == "kspree_reset" then
        alltime_stats = {}
        saveStats(kspree_cfg, alltime_stats)
        et.G_Printf("^7All sprees has been deleted.\n")
        return(1)
    end
    return(0)
end
