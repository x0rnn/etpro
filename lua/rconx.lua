--  0.1 17/02/2006
--  0.2 added slap and renameplayer
--  0.3 take partial names as input instead of slotnumber and optimize for use with
--    adminmod
--    dont forget the friggin helpfiles!
--  0.5 added playsound.lua by RoadKillPuppy and adapted to optionally display a text along with the sound
--      cleanup
-- 0.51 added clientcommand trap to stop regular votes being called- use shuffleteamsxp_norestart instead
-- 0.52 added origin change to make slap more realistic
--    changed the slap to g_damage
--  0.6 added a practise mode and server cvars to control things
--  1.0 11/03/2006
--    final cleanup and release
--  1.1 Bugfix for slap where carried objectives vanish along with player when gibbed
--
--      All these cvars are optional, they dont need to be set
--      ***********************************************server cvars*************************************************
--      *                                                                                                          *
--    * set l_shufflenr 1   ****  0= no action(leave it to server cfg(both enabled or disabled)              *
--    *               1= disable shuffle but keep shufflenr                                      *
--    *               2= disable shufflenr but keep shuffle                                      *
--      *                                                                                                          *
--    * set l_slaptype 1  ****  0 or anything but 1 = slap takes off percentage of current hp              *
--    *               1= slap takes off hp                                                       *
--      *                                                                                                          *
--    * set l_practise 0    ****    1= from the moment this is set everybody spawns with loads of hp and ammo  *
--      *                                                                                                          *
--    * set l_slapsound "/sound/fun/slap.wav"                                                                  *
--    *                                                      *
--    * set l_beaconmsg "kill me, im easy"   ****   set this to a line u want the punished player to spam      *
--    *                       or leave it empty for no spammage              *
--    *                                                                                                        *
--    * set l_soundloc "b 8" **** where to display the text that goes with the playsound functions       *
--    *               check http://wolfwiki.anime.net/index.php/SendServerCommand                *
--    *               for a list of locations                                            *
--    *                                                      *
--      ************************************************************************************************************
--
--
--
--
--      please note that this is not a finished project
--      any suggestions (f)or improvements are welcome
--      feel free to use this code as i figure everything in here is only there because of the other posts on wolfwiki
--      loads of credit to all of em
--      -[FuN]Connor-



-- global varlist
cadminVersion = "1.1"
slot = 0
ltimer = "0"
mact = "0"
miner = nil
slappee = nil
mtimer = "0"
shufflenr = "0"
oldname = ""
newname = ""
--defaults
minterval = "3000"  --a nice default interval for the beaconsounds to be played
msound = "/sound/world/alarm_01.wav"       --a nice standard sound for nice standard servers
ssound =  "/sound/player/land_hurt.wav"
slaptype = "0"
practise = "0"
soundloc = "b 8"

-- called when game inits     --register mod and grab cvars of there are any
function et_InitGame( levelTime, randomSeed, restart )
    et.RegisterModname( "RConX" .. cadminVersion .. " " .. et.FindSelf() )
    et.G_Print( "[FuN]Connor's rcon eXtensions version " ..  cadminVersion .. " activated...\n" )
    if "" ~= et.trap_Cvar_Get( "l_shufflenr" ) then 
    shufflenr = et.trap_Cvar_Get( "l_shufflenr" )
  end
  if "" ~= et.trap_Cvar_Get( "l_slaptype" ) then 
    slaptype = et.trap_Cvar_Get( "l_slaptype" )
  end
  if "" ~= et.trap_Cvar_Get( "l_practise" ) then 
    practise = et.trap_Cvar_Get( "l_practise" )
  end
  if "" ~= et.trap_Cvar_Get( "l_slapsound" ) then 
    ssound = et.trap_Cvar_Get( "l_slapsound" )
  end
  if "" ~= et.trap_Cvar_Get( "l_soundloc" ) then 
    soundloc = et.trap_Cvar_Get( "l_soundloc" )
  end
end



-- help functions
function PlaySoundloopenvHelp()
    et.G_Print("soundbeacon plays a sound -path_to_sound- that you can hear in the proximity of the player with slot -playerslot-\n");
    et.G_Print("for -seconds- every -interval- milliseconds\n");
    et.G_Print("usage: soundbeacon [interval] [path_to_sound.wav] -seconds- -partial name- \n");
end

function slapHelp()
    et.G_Print("slap hits a player over the head knocking off x percentage of healthpoints or gibbing him when no percentage is given\n");
    et.G_Print("set l_slaptype in server cfg to 1 to enable straight hp slap:\n");
    et.G_Print("    slap hits a player over the head knocking off x healthpoints or gibbing him when no amount of hp is given\n");
    et.G_Print("usage: slap [healthpoints/percentage] -partial name- \n");
end

function renameHelp()
  et.G_Print("renameplayer does what it says\n");
    et.G_Print("usage: renameplayer [-partial name- or id] [new name]\n");
  et.G_Print("the last rename is stored until map restart so use renameplayer -new name- to revert to the original\n");
end

function PlaySoundHelp()
        et.G_Print("playsound -1 plays a sound that everybody on the server can hear\n");
        et.G_Print("usage: playsound -1 path_to_sound.wav [\"text to display in chat\"]\n");
end

function PlaySoundEnvHelp()
        et.G_Print("playsound_env plays a sound that you can hear in the proximity of the player with slot -playerslot-\n");
        et.G_Print("usage: playsound_env playerslot path_to_sound.wav [\"text to display in chat\"]\n");
end

function PractiseHelp()
        et.G_Print("practise toggles practise mode, all players will spawn with health 5000 and loads of ammo until next map or maprestart\n");
        et.G_Print("unless you set l_practise in server cfg it will deactivate next map or restart\n");
        et.G_Print("usage: practise\n");
end

function inSlot( PartName )
  local x=0
  local j=1
  local size=tonumber(et.trap_Cvar_Get("sv_maxclients"))     --get the serversize
  local matches = {}
  while (x<size) do
    found = string.find(string.lower(et.Q_CleanStr( et.Info_ValueForKey( et.trap_GetUserinfo( x ), "name" ) )),string.lower(PartName))
    if(found~=nil) then
        matches[j]=x
        j=j+1
    end
    x=x+1
  end
  if (table.getn(matches)~=nil) then
    x=1
    while (x<=table.getn(matches)) do
        matchingSlot = matches[x] 
      x=x+1
    end
    if table.getn(matches) == 0 then
      et.G_Print("You had no matches to that name.\n")
      matchingSlot = nil
    else
      if table.getn(matches) >= 2 then
        et.G_Print("Partial playername got more than 1 match\n")
        matchingSlot = nil
      end
    end
  end
  return matchingSlot
end

-- every server frame
function et_RunFrame( levelTime )
    
  if miner ~= nil then
    if mact == "1" then
            phealth = et.gentity_get(miner, "health")
        if phealth > 0 then
              minterval = minterval + 1  --sloppy but i m too lazy to learn and use the format function
              minterval = minterval - 1
              if math.mod( levelTime, minterval ) == 0 then
                    if "" ~= et.trap_Cvar_Get( "l_beaconmsg" ) then 
            if math.mod( levelTime, minterval * 4) == 0 then --dont spam too often(oh well...)
              et.G_Say( miner, et.SAY_ALL, et.trap_Cvar_Get( "l_beaconmsg" ) )
            end
          end
            mtimer = mtimer - 1
            mtimer = mtimer + 1
              if mtimer >= 0 then
                mtimer = mtimer - 3
                soundindex = et.G_SoundIndex( msound )
                et.G_Sound( miner , soundindex )
              else
                mact = "0"   --deactivate timer
                miner = nil
                msound = "/sound/world/alarm_01.wav"
              end
            end
          end
    end
  end
end

-- react on new console command
function et_ConsoleCommand()

    if et.trap_Argv(0) == "soundbeacon" then
      msound = "/sound/world/alarm_01.wav"
      miner = nil
            if et.trap_Argc() ~= 5  then
        if et.trap_Argc() ~= 4 then
                    if et.trap_Argc() ~= 3 then
                      PlaySoundloopenvHelp()
                    else
            if nil ~= inSlot(et.trap_Argv(2)) then -- can we find the guy
              mact = "1" --activate the timer
                      miner = inSlot(et.trap_Argv(2))  --set cliendid
              mtimer = et.trap_Argv(1) --set timer
              et.trap_SendServerCommand(-1, "cpm \"^6Server^7: " .. et.Info_ValueForKey(et.trap_GetUserinfo(miner), "name") .. " has been punished \"\n")
                          --using default sound and interval
            end
          end
        else
            if nil ~= inSlot(et.trap_Argv(3)) then    -- can we find the guy
            mact = "1" --activate the timer
                    miner = inSlot(et.trap_Argv(3))  --set cliendid
            mtimer = et.trap_Argv(2) --set timer
            msound = et.trap_Argv(1) --set sound
            et.trap_SendServerCommand(-1, "cpm \"^6Server^7: " .. et.Info_ValueForKey(et.trap_GetUserinfo(miner), "name") .. " has been punished \"\n")
            --using default interval
          end
            end
      else
                if nil ~= inSlot(et.trap_Argv(4)) then   -- can we find the guy
          mact = "1" --activate the timer
                  miner = inSlot(et.trap_Argv(4))  --set cliendid
          mtimer = et.trap_Argv(3) --set timer
          msound = et.trap_Argv(2) --set sound
          minterval = et.trap_Argv(1) --set interval
          et.trap_SendServerCommand(-1, "cpm \"^6Server^7: " .. et.Info_ValueForKey(et.trap_GetUserinfo(miner), "name") .. " has been punished \"\n")
        end
      end
          return 1
        end

        if et.trap_Argv(0) == "slap" then
       	if et.trap_Argc() ~= 3 then
      		if et.trap_Argc() ~= 2 then
         		slapHelp()
      		 else
     				if string.len(et.trap_Argv(1)) < 3 then
    					local cno = tonumber(et.trap_Argv(1))
   					 if cno then
  						if et.gentity_get(cno, "pers.connected") == 2 then
 						  	et.G_Damage( cno, 80, 1022, 667, 8, 34 )
           					et.trap_SendServerCommand(-1, "cpm \"^6Server^7: " .. et.Info_ValueForKey(et.trap_GetUserinfo(cno) , "name") .. " has been gibbed \"\n")
                 			  soundindex = et.G_SoundIndex( "/sound/player/gib.wav" )
              				 et.G_Sound( cno , soundindex )
						  else
							 et.G_Print("You had no matches to that id.\n") 
						  end
						else
							et.G_Print("You had no matches to that id.\n")
						end
					else
            	       if nil ~= inSlot(et.trap_Argv(1)) then
          				 et.G_Damage( inSlot(et.trap_Argv(1)), 80, 1022, 667, 8, 34 )
          				et.trap_SendServerCommand(-1, "cpm \"^6Server^7: " .. et.Info_ValueForKey(et.trap_GetUserinfo(inSlot(et.trap_Argv(1))), "name") .. " has been gibbed \"\n")
            	         soundindex = et.G_SoundIndex( "/sound/player/gib.wav" )
           	  		et.G_Sound( inSlot(et.trap_Argv(1)) , soundindex )
       				end
      			 end
    			end
       	else
      		if string.len(et.trap_Argv(2)) < 3 then
    		 	local cno = tonumber(et.trap_Argv(2))
   			  if cno then
  			  	if et.gentity_get(cno, "pers.connected") == 2 then
 				  	phealth = et.gentity_get(cno, "health")
             			amount = et.trap_Argv(1)
            			amount = amount - 1
                		amount = amount + 1
               		 if slaptype == "1" then
           				if phealth < amount then
                           	et.G_Damage( cno, 80, 1022, 667, 8, 34 )
             					et.trap_SendServerCommand(-1, "cpm \"^6Server^7: " .. et.Info_ValueForKey(et.trap_GetUserinfo(cno), "name") .. " has been gibbed \"\n")
                        		soundindex = et.G_SoundIndex( "/sound/player/gib.wav" )
                 				et.G_Sound( cno , soundindex )
          				 else
           					plyr = cno      --he ll survive
            					soundindex = et.G_SoundIndex( ssound ) 
                         	  o=et.gentity_get(cno, "origin")
                         	  o[3] = o[3] + 50
                           	et.gentity_set(plyr, "origin", o)
             					et.G_Damage( plyr, 80, 1022, amount, 8, 32 )
                        		et.trap_SendServerCommand(-1, "cpm \"^6Server^7: " .. et.Info_ValueForKey(et.trap_GetUserinfo(cno), "name") .. " has been slapped \"\n")
              					et.G_Sound( plyr , soundindex )
           				end
      			 	else
                			perc = (amount * phealth) / 100
           				plyr = cno      --he ll survive
          				soundindex = et.G_SoundIndex( ssound ) 
                   		 o=et.gentity_get(cno, "origin")
                  		  o[3] = o[3] + 50
                  		  et.gentity_set(plyr, "origin", o)
           				et.G_Damage( plyr, 80, 1022, perc, 8, 32 )
                    	 et.trap_SendServerCommand(-1, "cpm \"^6Server^7: " .. et.Info_ValueForKey(et.trap_GetUserinfo(cno), "name") .. " has been slapped \"\n")
             			et.G_Sound( plyr , soundindex )
        		  	end
					else
						et.G_Print("You had no matches to that id.\n") 
					end
				  else
					  et.G_Print("You had no matches to that id.\n")
				  end
			else 
        		if nil ~= inSlot(et.trap_Argv(2)) then
      				phealth = et.gentity_get(inSlot(et.trap_Argv(2)), "health")
        	    	amount = et.trap_Argv(1)
       	     	amount = amount - 1
       	         amount = amount + 1
        	        if slaptype == "1" then
           			if phealth < amount then
                            et.G_Damage( inSlot(et.trap_Argv(2)), 80, 1022, 667, 8, 34 )
             				et.trap_SendServerCommand(-1, "cpm \"^6Server^7: " .. et.Info_ValueForKey(et.trap_GetUserinfo(inSlot(et.trap_Argv(2))), "name") .. " has been gibbed \"\n")
                        	 soundindex = et.G_SoundIndex( "/sound/player/gib.wav" )
                 			et.G_Sound( inSlot(et.trap_Argv(2)) , soundindex )
          			 else
           				plyr = inSlot(et.trap_Argv(2))      --he ll survive
            				soundindex = et.G_SoundIndex( ssound ) 
                            o=et.gentity_get(inSlot(et.trap_Argv(2)), "origin")
                            o[3] = o[3] + 50
                            et.gentity_set(plyr, "origin", o)
             				et.G_Damage( plyr, 80, 1022, amount, 8, 32 )
                        	 et.trap_SendServerCommand(-1, "cpm \"^6Server^7: " .. et.Info_ValueForKey(et.trap_GetUserinfo(inSlot(et.trap_Argv(2))), "name") .. " has been slapped \"\n")
              				et.G_Sound( plyr , soundindex )
           			end
      			   else
               		perc = (amount * phealth) / 100
          			 plyr = inSlot(et.trap_Argv(2))      --he ll survive
         			 soundindex = et.G_SoundIndex( ssound ) 
           	         o=et.gentity_get(inSlot(et.trap_Argv(2)), "origin")
          	          o[3] = o[3] + 50
       	             et.gentity_set(plyr, "origin", o)
       	   			et.G_Damage( plyr, 80, 1022, perc, 8, 32 )
         	            et.trap_SendServerCommand(-1, "cpm \"^6Server^7: " .. et.Info_ValueForKey(et.trap_GetUserinfo(inSlot(et.trap_Argv(2))), "name") .. " has been slapped \"\n")
         	   		et.G_Sound( plyr , soundindex )
       	 		end
       		end
         	end
         end
         return 1
      end

	if et.trap_Argv(0) == "megaslap" then
		if et.trap_Argc() == 2 then
			if string.len(et.trap_Argv(1)) < 3 then
    		 	local cno = tonumber(et.trap_Argv(1))
   			  if cno then
  			  	if et.gentity_get(cno, "pers.connected") == 2 then
 						plyr = cno		--he ll survive
						soundindex = et.G_SoundIndex( ssound ) 
						o=et.gentity_get(cno, "origin")
						o[3] = o[3] + 200
						et.gentity_set(plyr, "origin", o)
						et.G_Damage( plyr, 80, 1022, 0, 8, 32 )
						et.trap_SendServerCommand(-1, "cpm \"^6Server^7: " .. et.Info_ValueForKey(et.trap_GetUserinfo(cno), "name") .. " has been megaslapped \"\n")
						et.G_Sound( plyr , soundindex )
					  else
						 et.G_Print("You had no matches to that id.\n") 
					  end
				else
					et.G_Print("You had no matches to that id.\n")
				end 
			else
				if nil ~= inSlot(et.trap_Argv(1)) then
					plyr = inSlot(et.trap_Argv(1))		--he ll survive
					soundindex = et.G_SoundIndex( ssound ) 
					o=et.gentity_get(inSlot(et.trap_Argv(1)), "origin")
					o[3] = o[3] + 200
					et.gentity_set(plyr, "origin", o)
					et.G_Damage( plyr, 80, 1022, 0, 8, 32 )
					et.trap_SendServerCommand(-1, "cpm \"^6Server^7: " .. et.Info_ValueForKey(et.trap_GetUserinfo(inSlot(et.trap_Argv(1))), "name") .. " has been megaslapped \"\n")
					et.G_Sound( plyr , soundindex )
				end
			end
		end
		return 1
	end

        if et.trap_Argv(0) == "renameplayer" then
   		if et.trap_Argc() ~= 3 then
      		if et.trap_Argc() ~= 2 then
     			renameHelp() 
           	else
       		    if et.trap_Argv(1) == et.Q_CleanStr(newname) then
        		     local userinfo = et.trap_GetUserinfo( inSlot(et.Q_CleanStr(newname)) )
       		      local PlayerName = et.Q_CleanStr( et.Info_ValueForKey( userinfo, "name" ) )
              
      		       userinfo = et.Info_SetValueForKey( userinfo, "name", oldname )
    		         et.trap_SetUserinfo( inSlot(et.Q_CleanStr(newname)), userinfo )
    		         et.trap_SendConsoleCommand(et.EXEC_APPEND, "mute " .. "\"" .. PlayerName .. "\"" .. "\n" ) 
    		         PlayerName = et.Q_CleanStr( et.Info_ValueForKey( userinfo, "name" ) )
      		       et.trap_SendConsoleCommand(et.EXEC_APPEND, "unmute " .. "\"" .. PlayerName .. "\"" .. "\n" )
      		       oldname = ""
      		       newname = ""
       		    end
     	    end
          else
         	if string.len(et.trap_Argv(1)) < 3 then
    			local cno = tonumber(et.trap_Argv(1))
   			 if cno then
  			 	if et.gentity_get(cno, "pers.connected") == 2 then
 						local userinfo = et.trap_GetUserinfo( cno )
          			 local PlayerName = et.Q_CleanStr( et.Info_ValueForKey( userinfo, "name" ) )
          			 oldname = et.Info_ValueForKey( userinfo, "name" )
        			   newname = et.trap_Argv(2)
          			 userinfo = et.Info_SetValueForKey( userinfo, "name", et.trap_Argv(2) )
         			  et.trap_SetUserinfo( cno, userinfo )
           			et.trap_SendConsoleCommand(et.EXEC_APPEND, "mute " .. "\"" .. PlayerName .. "\"" .. "\n" ) 
           			PlayerName = et.Q_CleanStr( et.Info_ValueForKey( userinfo, "name" ) )
           			et.trap_SendConsoleCommand(et.EXEC_APPEND, "unmute " .. "\"" .. PlayerName .. "\"" .. "\n" )
       		     else
						et.G_Print("You had no matches to that id.\n") 
					 end
				else
					et.G_Print("You had no matches to that id.\n")
				end
            else
         	  local userinfo = et.trap_GetUserinfo( inSlot(et.trap_Argv(1)) )
         	  local PlayerName = et.Q_CleanStr( et.Info_ValueForKey( userinfo, "name" ) )
          	 oldname = et.Info_ValueForKey( userinfo, "name" )
           	newname = et.trap_Argv(2)
          	 userinfo = et.Info_SetValueForKey( userinfo, "name", et.trap_Argv(2) )
          	 et.trap_SetUserinfo( inSlot(et.trap_Argv(1)), userinfo )
          	 et.trap_SendConsoleCommand(et.EXEC_APPEND, "mute " .. "\"" .. PlayerName .. "\"" .. "\n" ) 
           	PlayerName = et.Q_CleanStr( et.Info_ValueForKey( userinfo, "name" ) )
          	 et.trap_SendConsoleCommand(et.EXEC_APPEND, "unmute " .. "\"" .. PlayerName .. "\"" .. "\n" )
            end
          end
          return 1
        end

        if et.trap_Argv(0) == "playsound" then
        --et.G_Print("#####0")

            if et.trap_Argc() == 2  then --to display a text along with the sound
              --et.G_Print(string.format("ARG: %s\n", et.trap_Argv(1)))
              et.G_globalSound(et.trap_Argv(1))
            elseif et.trap_Argc() > 2 then
            --et.G_Print("#####2")
              et.trap_SendServerCommand(-1, soundloc .. " \"" .. et.ConcatArgs(2) .. "\"\n")
              et.G_globalSound(et.trap_Argv(1))                 
            end
            return 1
        end
        


        if et.trap_Argv(0) == "playsound_env" then
            if et.trap_Argc() ~= 4 then  --to display a text along with the sound
        if et.trap_Argc() ~= 3 then
                    PlaySoundEnvHelp()
                else
                    soundindex = et.G_SoundIndex( et.trap_Argv(2) )
                    et.G_Sound( et.trap_Argv(1) , soundindex )
                end
      else
                et.trap_SendServerCommand(-1, soundloc .. " \"" .. et.trap_Argv(3) .. "\"\n")
        soundindex = et.G_SoundIndex( et.trap_Argv(2) )
                et.G_Sound( et.trap_Argv(1) , soundindex )
      end
            return 1
        end

        if et.trap_Argv(0) == "practise" then
            PractiseHelp()
          if practise == "0" then
            practise = "1"
            et.trap_SendServerCommand(-1, "cp \"^6Server^7: " .. "Practise mode ^1enabled \"\n")
          else
            practise = "0"
            et.trap_SendServerCommand(-1, "cp \"^6Server^7: " .. "Practise mode ^1disabled \"\n")
      end
          if "" ~= et.trap_Cvar_Get( "l_practise" ) then 
        et.trap_Cvar_Set( "l_practise", practise )
      end
      return 1
    end
        return 0
end

function et_ClientCommand( clientNum, cmd )
    if et.trap_Argv( 0 ) == "callvote" then
    if et.trap_Argv( 1 ) == "shuffleteamsxp" then
      if shufflenr == "1" then
        et.trap_SendServerCommand( clientNum, "cpm\"Please use ^1\callvote shuffleteamsxp_norestart^7 in the future\n\"" ) -- announcement area
        return 1
      end
    end
    if et.trap_Argv( 1 ) == "shuffleteamsxp_norestart" then
      if shufflenr == "2" then
        et.trap_SendServerCommand( clientNum, "cpm\"Please use ^1\callvote shuffleteamsxp^7 in the future\n\"" ) -- announcement area
        return 1
      end
    end
  end
  return 0
end

function et_ClientSpawn(cno,rvd) --set hp and ammo on every spawn for practise
  if practise == "1" then
        et.gentity_set(cno, "health", 5000)
    for i=0,(63),1 do
      et.gentity_set(cno,"ps.ammoclip",i,800)
      et.gentity_set(cno,"ps.ammo",i,200)
    end
    return 1
  end
return 0
end
