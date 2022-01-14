--[[
ReaScript name: LorenzoTT_Add Time Marker from Cursor Project Time Position
Version: 1.0.3
Author: Lorenzo Targhetta
]]

local offset = reaper.GetProjectTimeOffset( proj, false )
local cursPosSecs = reaper.GetCursorPosition()
local cursPosSecsOffs = cursPosSecs - offset
local cursPosHHMMSS = reaper.format_timestr(cursPosSecsOffs,"...")

reaper.AddProjectMarker(0,false,cursPosSecs,0,cursPosHHMMSS,-1)


