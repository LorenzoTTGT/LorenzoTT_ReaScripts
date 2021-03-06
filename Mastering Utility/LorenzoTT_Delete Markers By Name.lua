--[[
ReaScript name: LorenzoTT_Delete Project Markers By Name (or Name Inititals)
Version: 1.0.3
Author: Lorenzo Targhetta
Date: 09/01/2022
]]

function case_insensitive_pattern(pattern)

  -- find an optional '%' (group 1) followed by any character (group 2)
  local p = pattern:gsub("(%%?)(.)", function(percent, letter)

    if percent ~= "" or not letter:match("%a") then
      -- if the '%' matched, or `letter` is not a letter, return "as is"
      return percent .. letter
    else
      -- else, return a case-insensitive character class of the matched letter
      return string.format("[%s%s]", letter:lower(), letter:upper())
    end

  end)

  return p
end



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
    local mrkr_i_Initials = string.sub(allmarkersarray2[i_mrkr][1], 1, nameLen)
    
        
        if i_mrkr > 0
            
            then
           
              if NameToDelete:match(case_insensitive_pattern(mrkr_i_Initials))
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
                  mrkr_Next_i_Initials = string.sub(allmarkersarray2[i_mrkr2+1][1], 1, nameLen)
                  rkr_Updt_i_name = string.sub(allmarkersarray2[i_mrkr2][1], 1, nameLen) 
                  if NameToDelete:match(case_insensitive_pattern(mrkr_Next_i_Initials))
                    then 
                      
                  end
                  if NameToDelete:match(case_insensitive_pattern(mrkr_Updt_i_name))
                    then
                      _ =  reaper.DeleteProjectMarkerByIndex(nil,allmarkersarray2[i_mrkr][2])
                    else
                        keepmarker = true
                  end
                
              end
        
        end      
    end
end
   
      
--action
local scriptname = "Delete Project Markers By Name (or Name Inititals)"
local _, NameToDelete = reaper.GetUserInputs(scriptname, 1, "Name to Find (case sensitive)", "verse" )
reaper.Undo_BeginBlock()
lorenzoTT_DeleteMarkersByName(NameToDelete)
reaper.Undo_EndBlock(scriptname, -1)

