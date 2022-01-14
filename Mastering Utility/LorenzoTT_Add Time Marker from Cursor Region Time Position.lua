--[[
ReaScript name: LorenzoTT_Add Time Marker from Cursor Region Time Position
Version: 1.0.1
Author: Lorenzo Targhetta
]]

function addTimeMarkerFromRegionTimePos()
	local play_pos = reaper.GetCursorPosition() 
	local marker_idx, region_idx = reaper.GetLastMarkerAndCurRegion(0, play_pos)
	local offset = reaper.GetProjectTimeOffset( proj, false )
	local _, _, region_start, region_end, region_name, markrgnindexnumber, region_color = reaper.EnumProjectMarkers3(0, region_idx)
	local cursPosSecs = reaper.GetCursorPosition()
	local buf = play_pos - region_start - offset
	local cursPosHHMMSS = reaper.format_timestr(buf,"...")
	reaper.AddProjectMarker(0,false,buf,0,cursPosHHMMSS,-1)
end

addTimeMarkerFromRegionTimePos()
