--[[
ReaScript name: LorenzoTT_Cursor Time Position To Marker
Version: 1.0
Author: LorenzoTT
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
]]

local cursPosSecs = reaper.GetCursorPosition()
local cursPosHHMMSS = reaper.format_timestr(cursPosSecs,"...")

reaper.AddProjectMarker(0,false,cursPosSecs,0,cursPosHHMMSS,-1)


