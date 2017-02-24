
--[[
  Created by DarkRoku12. Github: github.com/DarkRoku12
  For Citizen1000. 
  Date: 2017.
]]

local reaper = reaper ;

-- enable string:at( from , to ) -- Returns the selected characters in that range.
getmetatable( "" ).__index.at = function( self , from , to )
   return string.char( self:byte( from , to ) )
end 

local extract = {} 

--[[
<VST "VSTi: ReaSamplOmatic5000 (Cockos)" reasamplomatic.dll 0 "" 1920167789
Will return: "VSTi: ReaSamplOmatic5000 (Cockos)"

<JS: 4-Band EQ ""
Will return: "JS: 4-Band EQ "
]]

function extract.name( str ) -- Get the real name.
   local name = str:match( [[%b""]] ) 

   if not name or #name < 3 then 
      name = str:match( "<.-[\n]" )
      name = name:at( 2 , #name - 1 )
   end 

   return name or "No name" ; 
end 

--[[
  BYPASS 1 1 0 --> This line show us the status of the FX.
  
  0 means YES, 1 means NO.
  
  The first number tell us if the track is checked (toogle selected FX bypass)
  The second number tell us if the track is online (toogle selected FX offline)
  The third number i don't know.

  So BYPASS 1 1 0 means: The track is not checked and offlile.
  So BYPASS 0 1 0 means: The track is checked but offline.
  So BYPASS 0 0 0 means: The track is checked and online.
]]

function extract.status( str )

   local status = str:match( "BYPASS.-<" ) ; 

   local isActive = status:at( 8 ) == "0" ; -- The track is checked ?
   
   local isOnline = status:at( 10 ) == "0" ; -- The track is online ?
   
   return isOnline , isActive ;
end 

local function getInfoFromFxs( track )
   
   local _ , dump = reaper.GetTrackStateChunk( track , '' ) ;

   local t = {}

   local idx = 0 ;

   for VSTi in dump:gmatch( "BYPASS.-WAK" ) do 
       
       idx = idx + 1 ;

       local isOnline , isActive = extract.status( VSTi ) 
       
       t[ idx ] = 
       {
          name = extract.name( VSTi ) , -- Original name of the FX.
          isOnline = isOnline , 
          isActive = isActive ,
       }
       
   end 

   return t ; 
end 

return getInfoFromFxs ;



