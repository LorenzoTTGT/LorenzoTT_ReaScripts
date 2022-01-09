--[[
ReaScript name: LorenzoTT_Remove Time Between Regions
Version: 1.0
Author: Lorenzo Targhetta
]]

function erase_Time_Between_Regions()
	dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
  local number_of_all_regions,_ = ultraschall.GetAllRegions()
      for r = 1, (number_of_all_regions -1)
      do 
      local _, allregionsarray = ultraschall.GetAllRegions()
        local timeSelStart = allregionsarray[r][1] 
        local timeSelEnd = allregionsarray[r+1][0]
        if (math.floor(timeSelStart) ~=  math.floor(timeSelEnd)) then
        _, _ = reaper.GetSet_LoopTimeRange(true, false, timeSelStart, timeSelEnd, false)
        reaper.Main_OnCommand(40201, 0)
        end
      end
  end
	

erase_Time_Between_Regions()

