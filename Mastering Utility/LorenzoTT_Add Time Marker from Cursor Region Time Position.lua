--[[
ReaScript name: LorenzoTT_Add Time Marker from Cursor Region Time Position
Version: 1.0.2
Author: Lorenzo Targhetta
]]

function addTimeMarkerFromRegionTimePos()
	play_state = reaper.GetPlayState()
	if play_state == 0 
		then 
		cursPos = reaper.GetCursorPosition() 
	else 
		cursPos = reaper.GetPlayPosition()
	end

	local marker_idx, region_idx = reaper.GetLastMarkerAndCurRegion(0, cursPos)
	local offset = reaper.GetProjectTimeOffset( proj, false )
	local _, _, region_start, region_end, region_name, markrgnindexnumber, region_color = reaper.EnumProjectMarkers3(0, region_idx)
	local buf = play_pos - region_start - offset
	local cursPosHHMMSS = reaper.format_timestr(buf,"...")

	reaper.AddProjectMarker(0,false,cursPos,0,cursPosHHMMSS,-1)
end

addTimeMarkerFromRegionTimePos()