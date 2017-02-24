
--[[
  Created by DarkRoku12. Github: github.com/DarkRoku12
  For Citizen1000. 
  Date: 2017.
]]

--[[
1-removes "time selection" if there is one
2-else: close any floating FX or tool windows. Note: #2
3-else: close the MIDI editor
4-else: remove "loop points"
5-else: close all "dockers" (this should close any docked FX, toolbars or scripts)
6-else: do nothing

Note #2:
FX, 
toolbars and scripts can either be "floating" (free floating) 
or "docked" (attached to the main window." 
This should close all floating VST/FX windows, floating toolbars and floating scripts. 
]]

local reaper = reaper ;

local sendCommand = reaper.Main_OnCommand ;

-- Only for debug purpouse.
local function print( ... )
   local t = { ... }
   for i = 1 , #t do 
      reaper.ShowConsoleMsg( tostring( t[i] ) .. "\t" ) ;
   end 
   reaper.ShowConsoleMsg( "\n" ) ;
end 

local function isOpen( id )
   return reaper.GetToggleCommandState( id ) == 1 ;
end 

local escape = 
{

function() -- #1 -- Time selection.
   local startTime , endTime = reaper.GetSet_LoopTimeRange( false , false , 0 , 0 , false )
   if startTime ~= endTime then
      reaper.GetSet_LoopTimeRange( true , false , 0 , 0 , true )
      return true
   end
end , 

function() -- #2 -- Close floating windows.
     
    local anyOpen = false ;

    local commands = 
    { 
       41084 , -- Toolbar: Show/hide Toolbar Docker
       41297 , -- Toolbar: Show/hide toolbar at top of main window 
    }

    for _ , cmdID in ipairs( commands ) do 
       if isOpen( cmdID ) then 
           anyOpen = true ;
          sendCommand( cmdID , 0 )
       end 
    end 

   for ti = 0 , reaper.CountTracks() - 1 do
   
      local track = reaper.GetTrack( 0 , ti )
   
      local fx_count = reaper.TrackFX_GetCount( track )
      
      for fxi = 0 , fx_count - 1 do
         if reaper.TrackFX_GetOpen( track , fxi ) and reaper.TrackFX_GetFloatingWindow( track , fxi ) then  
            reaper.TrackFX_SetOpen( track , fxi , false )
            anyOpen = true ;
         end 
      end

   end

   return anyOpen ;
end , 

function() -- #3 -- Close midi editor
   if reaper.MIDIEditor_GetActive() then
      sendCommand( 40716 , 0 ) 
      return true 
   end
end , 

function() -- #4 -- Remove loop points.
   local startTime , endTime = reaper.GetSet_LoopTimeRange( false , true , 0 , 0 , false )
   if startTime ~= endTime then
      sendCommand( 40624 , 0 ) ;
      return true
   end
end ,

function() -- #5 -- Remove all dockers.
   if isOpen( 40279 ) then 
      sendCommand( 40279 , 0 )
      return true ;
   end 
end ,

}

for num , functions in ipairs( escape ) do 
   if functions() then 
      break ;
   end 
end 

