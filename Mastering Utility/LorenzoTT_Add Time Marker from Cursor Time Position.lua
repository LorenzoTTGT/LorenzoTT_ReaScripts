--[[
ReaScript name: LorenzoTT_Add Time Marker from Cursor Time Position
Version: 1.0.1
Author: Lorenzo Targhetta
]]

local cursPosSecs = reaper.GetCursorPosition()
local cursPosHHMMSS = reaper.format_timestr(cursPosSecs,"...")

reaper.AddProjectMarker(0,false,cursPosSecs,0,cursPosHHMMSS,-1)


