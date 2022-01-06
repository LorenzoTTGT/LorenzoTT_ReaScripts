--[[
ReaScript name: Delete Project Markers By Name (or Name Inititals)
Version: 1.0
Author: Lorenzo Targhetta
Date: 06/01/2022
]]


function lorenzoTT_DeleteMarkersByName(NameToDelete)
    dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
    
    local nameLen = #NameToDelete
    local mrkrsAllNb, allmarkersarray = ultraschall.GetAllMarkers()
    
      for i_mrkr = 1, mrkrsAllNb do
      
        mrkrsAllNb2, allmarkersarray2 = ultraschall.GetAllMarkers()
       
        if i_mrkr > mrkrsAllNb2
                      then 
                        break
        end
        
        local mrkr_i_name = allmarkersarray2[i_mrkr][1]
        local mrkr_i_index = allmarkersarray2[i_mrkr][2]
        
          
        if i_mrkr > 0
            
            then
           
              if (string.sub(allmarkersarray2[i_mrkr][1], 1, nameLen) == NameToDelete)
                then
                  _ =  reaper.DeleteProjectMarkerByIndex(nil,mrkr_i_index)
                  checknext = 1
            
                else
                  checknext = 0
                  keepmarker = true
              end

        end
        
        if checknext == 1
            then
                   for i_mrkr2 = i_mrkr, mrkrsAllNb2 do
                      if i_mrkr2 == mrkrsAllNb2
                        then
                          break
                      end
                      if (string.sub(allmarkersarray2[i_mrkr2+1][1], 1, nameLen) ~= NameToDelete)
                        then 
                        --reaper.ShowConsoleMsg(mrkrsAllNb)
                          break
                      end
                      if (string.sub(allmarkersarray2[i_mrkr2][1], 1, nameLen) == NameToDelete)
                        then
                        reaper.ShowConsoleMsg(allmarkersarray2[i_mrkr][1])
                          _ =  reaper.DeleteProjectMarkerByIndex(nil,allmarkersarray2[i_mrkr][2])
                        else
                        keepmarker = true
                      end
                    end
        
        end      
    end
      return
end
   
      
--examples
local scriptname = "Delete Project Markers By Name (or Name Inititals)"
local _, NameToDelete = reaper.GetUserInputs(scriptname, 1, "Name to Find (case sensitive)", "verse" )
reaper.Undo_BeginBlock()
lorenzoTT_DeleteMarkersByName(NameToDelete)
reaper.Undo_EndBlock(scriptname, -1)


