
--[[
  Created by DarkRoku12. Github: github.com/DarkRoku12
  For Citizen1000. 
  Date: 2017.
]]

--[[
  "Set track name to loaded sample or VST":

I want a script that can automatically name my tracks to either the name of the sample loaded in the sampler on the tracks, 
or if there is no sample loaded, then the name of the next online VST instrument. 

I load a VSTi sampler ("ReaSamplomatic5000") on every track in REAPER. 
       *When it has no sample loaded it displays the name: "VSTi: ReaSamplOmatic5000 (Cockos)". 
       *If it has a sample loaded: it changes it's name to whatever the sample is called. 

I want the script to check if it's name is different than "VSTi: ReaSamplOmatic5000 (Cockos)", and if it is, 
then change the name of the selected track to that name. 

If it's name is "VSTi: ReaSamplOmatic5000 (Cockos)" then I want it to:
  *find the next VSTi plugin that is online and change the name of the track to the name of the VSTi and its preset. 
   (I load several VSTi plugins after the sampler on every track, but they are kept in an "offline" state so that they 
   are quick to load and don't use CPU.) If one of them is online, I want the script to change the name of the track to that VST and it's preset name.
  
  *If neither of these things are true (sampler name is default and no online VSTi after it) then it should name the track to the 

  name of the first "media item" (i.e. a .wav file) that is on track. If there is no media file, then do nothing.

Also: the first VSTi instrument I load is before ReaSamplomatic (which could cause problems) and is called "Cthulhu" or "Arp" and should be ignored, I never want the tracks to be named "Cthulhu"

So, basically:

-check if FX number 5, "ReaSamplomatic"'s name is set to it's default or the name of a sample
-if it's name is a sample, then change the name of the track that it's on to the sample
-if it's name is default, then move on to check if there is a VSTi FX after it that is online
-if it is, then change the name of the track to the name of that online VST and preset
-if neither of those things, then change the name of the track to the name of the first media item that is on it

There's a script already that changes the name of the track to the first online VST and it's preset name. I attached so you can use it.
]]


package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. '?.lua;' .. package.path ;
-- package.config:sub(1,1) -- returns: Default is '\' for Windows and '/' for all other systems.

local ipairs = ipairs ;
local reaper = reaper ;

local getInfoFromFxs = require "Scripts.getInfoFromFxs" ;

-- Only for debug purpouse.
local function print( ... )
   local t = { ... }
   for i = 1 , #t do 
      reaper.ShowConsoleMsg( tostring( t[i] ) .. "\t" ) ;
   end 
   reaper.ShowConsoleMsg( "\n" ) ;
end 

local defaultName = "ReaSamplOmatic5000" 

local ReaSamplOmatic5000 = "ReaSamplOmatic5000" ;

local function pfind( str , prefix )
   return str:sub( 1 , 4 ):find( prefix )
end

local must_skip_vsti = { ReaSamplOmatic5000 , "Cthulhu" , "Arp" }

local function mustSkip( str )

   for idx , name in ipairs( must_skip_vsti ) do 
      if str:find( name ) then 
         return true ;
      end 
   end 
   
   return false ;
end 

--[[Change the name of a Track. ]]
local function setTrackName( track , name )
   reaper.GetSetMediaTrackInfo_String( track , "P_NAME" , name:gsub( "%b()" , "" ):gsub( "VSTi[:]?[%s]?" , "" ) , true )
end 

local function setTrackNameToMedia( track )

   local media = reaper.GetTrackMediaItem( track , 0 ) --> 1st media of the selected track. 

   if not media then return end 

   local mediaItem = reaper.GetMediaItemTake( media , 0 ) --> Get the first media item.

   local _ , mediaName = reaper.GetSetMediaItemTakeInfo_String( mediaItem , "P_NAME" , "" , false ) 

   if not mediaName or #mediaName < 1 then -- Security checks.
      mediaName = "No name" ;
   end 

   setTrackName( track , mediaName )
end 

for t = 0 , reaper.CountSelectedTracks( 0 ) - 1 do --> Loop for every 'selected' Track. 

   local track = reaper.GetSelectedTrack( 0 , t )

   local FXsInfo = getInfoFromFxs( track ) 

   local _ , trackName = reaper.GetTrackName( track , "" ) 
  
  -- The name is none or the name is "ReaSamplOmatic5000" ? Yes => Custom name, skip it, No => Change it.
   if trackName:find( "Track [%d]+" ) or trackName:find( defaultName ) then 

      local name_was_set = false ;
      
      -- Try to find "ReaSamplOmatic5000" and look if has a Track loaded on it.
      for idx , FX_Info in ipairs( FXsInfo ) do 
         
         if FX_Info.name:find( ReaSamplOmatic5000 ) then --> Found ReaSamplOmatic5000?
           
            local _ , name = reaper.TrackFX_GetFXName( track , idx - 1 , "" ) ; --> Get the name on ReaSamplOmatic5000.
            
            -- If the name is not the default, use it. (Usually means a Track was loaded on it).
            if not name:find( ReaSamplOmatic5000 ) then 
               name_was_set = true ;
               setTrackName( track , name ) ;
            end 

         end 

      end 

      -- Try the next FX that is online, skiping some of them like: Arp, Cthulhu, ReaSamplOmatic5000, etc...
      if not name_was_set then 

         for i = 0 , reaper.TrackFX_GetCount( track ) - 1 do --> Loop for every FX in the Track. [ loop #TRACK_FX ]

            local FX_Info = FXsInfo[ i + 1 ] ;

            if FX_Info.isOnline then --> Only 'online' FXs are valid.
               
                local FX_DefaultName = FX_Info.name ;

                local isVSTi = FX_DefaultName:find( "VSTi" ) --> Only FXs that are VSTi are valid.

                if isVSTi then --> Non-VSTi FX must be skipped.

                    if not mustSkip( FX_DefaultName ) then -- Skip VSTi that are no desired.
                       local _ , FX_CurrentName = reaper.TrackFX_GetFXName( track , i , "" ) ;
                       name_was_set = true ;
                       setTrackName( track , FX_CurrentName ) ;
                       break ; --> Exit the loop #TRACK_FX.
                    end 

                end 

            end

         end

      end 
     
      -- If all before failed, try to set the Track name to the first Media Item.
      if not name_was_set then 
         setTrackNameToMedia( track ) ;
      end 

   end 

end

