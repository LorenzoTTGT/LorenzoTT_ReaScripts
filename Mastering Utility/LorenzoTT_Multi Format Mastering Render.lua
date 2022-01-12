--[[
ReaScript name: LorenzoTT_Multi Format Mastering Render
Version: 1.0.19
Author: Lorenzo Targhetta
@changelog
    JPG auto w & h
@provides 
    ../LorenzoTT_Libs/LorenzoTT_GetImageSize.lua 
    ../LorenzoTT_Libs/LorenzoTT_WRITE_PDF_TO_DISK.lua
    ../LorenzoTT_Libs//LorenzoTT_spk77_Save table to file and load table from file_functions.lua
]]

-- Lokasenna's GUI Builder

local lib_path =reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()


GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Label.lua")()


-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end

GUI.name = "Multi Format Renders"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 520, 450
GUI.anchor, GUI.corner = "mouse", "C"



--My Script----------------------------------------------------

--include external API
dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
dofile(reaper.GetResourcePath().."/Scripts/LorenzoTT_Reascripts/LorenzoTT_Libs/LorenzoTT_WRITE_PDF_TO_DISK.lua")
dofile(reaper.GetResourcePath().."/Scripts/LorenzoTT_Reascripts/LorenzoTT_Libs/LorenzoTT_GetImageSize.lua")
dofile(reaper.GetResourcePath().."/Scripts/LorenzoTT_Reascripts/LorenzoTT_Libs/LorenzoTT_spk77_Save table to file and load table from file_functions.lua")


--Variable Definitions
local _, projectName = reaper.GetSetProjectInfo_String(nil, "PROJECT_NAME", "no", 0)
--/ local FileNameWCPattern = "$region$track" /--
local presetFilepath = reaper.GetResourcePath().."/Scripts/LorenzoTT_Reascripts/LorenzoTT_Presets/(DONT OPEN!)_LorenzoTT_ALLPRESETS.txt"
local presetFilepathDIR = reaper.GetResourcePath().."/Scripts/LorenzoTT_Reascripts/LorenzoTT_Presets"
local _, AllRegionsAttr = ultraschall.GetAllRegions()
imageDIR = "no logo"
local allRegNmbr, allRegArr = ultraschall.GetAllRegions()
local all_markers_count, _ = ultraschall.CountMarkersAndRegions()

--Poroject filepath
local _, projectName = reaper.GetSetProjectInfo_String(nil, "PROJECT_NAME", "no", 0)
local projectFilePath=""
proj, projectFilePath=reaper.EnumProjects(-1, projectFilePath)
projectFilePathNoName = projectFilePath:gsub(projectName, "")

--RenderStrings
local toWAV24 = ultraschall.CreateRenderCFG_WAV(2, 2 , 3, 0, false)
local toWAV16 = ultraschall.CreateRenderCFG_WAV(1, 2 , 3, 0, false)
local toMP3320CBR = ultraschall.CreateRenderCFG_MP3CBR(16, 0, false, false)
local toMP3320VBR = ultraschall.CreateRenderCFG_MP3VBR(10, 0, false, false)
local toDDPrenderString = ultraschall.CreateRenderCFG_DDP()


--PRESET FUNC-------------------------- 
function SaveMultiExportPresets(fn, img, rdir, logo_H)
    presets = 
    {
    presets_MultiExp =
        {
        FileNamePattern = fn,
        JPG_URL_DIR = img,
        RenderDIR = rdir,
        stored_logoHeight = logo_H
        },
    }
    table.save(presets, presetFilepath) -- save "presets" table
end

--case insensitive func
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


-- Erase time between regions---------
function erase_Time_Between_Regions()
    local number_of_all_regions,_ = ultraschall.GetAllRegions()
    for r = 1, (number_of_all_regions -1)
        do 
        local _, allregionsarray = ultraschall.GetAllRegions()
        local timeSelStart = allregionsarray[r][1] 
        local timeSelEnd = allregionsarray[r+1][0]
        if (math.floor(timeSelStart) ~=  math.floor(timeSelEnd)) 
            then
            _, _ = reaper.GetSet_LoopTimeRange(true, false, timeSelStart, timeSelEnd, false)
            reaper.Main_OnCommand(40201, 0)
        end
    end
end
  
--decimal rounding function
function round(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end

RenderTable = ultraschall.GetRenderTable_Project()
                                              
function dump(o)
    if type(o) == 'table' 
        then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' 
                then 
                k = '"'..k..'"'
            end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

--Markers Functions
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
      

--GUI STUFF-------------------------- 
function fillImageSourceDir()
    is_logo_img, imageDIR = reaper.JS_Dialog_BrowseForOpenFiles("select JPG image", REAPERFolder, "YOURLOGO.jpg",".jpg", false)
    GUI.Val("Logo Image Source", imageDIR)
end

function fillFolderDest()
     _, NewOutputFilepath = reaper.JS_Dialog_BrowseForFolder("Render Destination Folder", projectFilePathNoName )
    GUI.Val("Renders Destination", NewOutputFilepath)
    projectFilePathNoName = NewOutputFilepath
end

function setProjAuth()
    local prAuth = GUI.Val("Project Artist")
     _, prAuth2 = reaper.GetSetProjectInfo_String(nil, "PROJECT_AUTHOR", prAuth, 1)
end

function setProjTitle()
    local prTitle = GUI.Val("Project Title")
    _, prTitle2 = reaper.GetSetProjectInfo_String(nil, "PROJECT_TITLE", prTitle, 1)
end

reaper.Undo_BeginBlock()

local function gorenderst()
    local _, projectName = reaper.GetSetProjectInfo_String(nil, "PROJECT_NAME", "no", 0)
    local projectFilePath=""
    proj, projectFilePath=reaper.EnumProjects(-1, projectFilePath)
    projectFilePathNoName = projectFilePath:gsub(projectName, "")
    local REAPERFolder = reaper.GetResourcePath()
    reaper.GetSetProjectInfo(0, "PROJECT_SRATE_USE", 1, true )
    local projectSR = reaper.GetSetProjectInfo(nil, "PROJECT_SRATE", 0, false )  
    local projectSR_INT = math.floor(projectSR)
    local projectSR_short = string.sub(tostring(projectSR_INT), 1, 2)
    local prTitle = GUI.Val("Project Title")
    local prAuth = GUI.Val("Project Artist")
    _, prTitle2 = reaper.GetSetProjectInfo_String(nil, "PROJECT_TITLE", prTitle, 1)
    _, prAuth2 = reaper.GetSetProjectInfo_String(nil, "PROJECT_AUTHOR", prAuth, 1)
    projectFilePathNoName = GUI.Val("Renders Destination")
    OutputFilepath = projectFilePathNoName .. "/" .. prAuth .." - ".. prTitle .. " - MASTERED" .. "/" .. prAuth .. " - " .. prTitle
    PQSheet_Filepath = projectFilePathNoName .. "/" .. prAuth .." - ".. prTitle .. " - CD PQ-Sheet" .. ".pdf"
    OutputFilepathWAV4424 = OutputFilepath .. " - " .. "WAV_4424"
    OutputFilepathWAV4416 = OutputFilepath .. " - " .. "WAV_4416"
    OutputFilepathWAV4824 = OutputFilepath .. " - " .. "WAV_4824"
    OutputFilepathWAV4816 = OutputFilepath .. " - " .. "WAV_4816"
    OutputFilepathWAVProjSR24 = OutputFilepath .. " - " .. "WAV_" ..  projectSR_short .. "24"
    OutputFilepathWAVProjSR16 = OutputFilepath .. " - " .. "WAV_" ..  projectSR_short .. "16"
    OutputFilepathMP3320CBR = OutputFilepath .. " - " .. "MP3_320_CBR"
    OutputFilepathMP3320CVBR = OutputFilepath .. " - " .. "MP3_320_VBR"
    OutputFilepathDDP = OutputFilepath .. " - DDP IMAGE"
    OutputFilepathVinylSides = OutputFilepath .. " - VINYL SIDES"
    VinilSideA_name =  prAuth .." - ".. prTitle .. " - VINYL SIDE A"
    VinilSideB_name =  prAuth .." - ".. prTitle .. " - VINYL SIDE B"
    local FileNameWCPattern = GUI.Val("File Name Pattern $") 
    local sel_WAVformat = GUI.Val("WAV Renders") 
    local sel_RenderDest = GUI.Val("Renders Destination")
    local sel_DDP_Render = GUI.Val("DDP Render")
    local sel_Logo_H = GUI.Val("Logo Height")
    local sel_PQsheet = GUI.Val("PQ Sheet")
    local sel_MP3format = GUI.Val("MP3 Renders")
    local sel_VinylSides= GUI.Val("VINYL SIDES")
    local number_of_all_regions, allregionsarray = ultraschall.GetAllRegionsBetween(nil, nil, nil)
    
    --RenderTAbles
    local OutputWAV4424 = ultraschall.CreateNewRenderTable(8, 3, 0, 0, 18, 1000, OutputFilepathWAV4424, FileNameWCPattern, 44100,
                                                        2, 0, true, 9, false, false, 12, toWAV24, false, false, false, false,
                                                        0, true, false, "", false, false, true, false, false, 
                                                        3, false, 24)
    
    local OutputWAV4416 = ultraschall.CreateNewRenderTable(8, 3, 0, 0, 18, 1000, OutputFilepathWAV4416,FileNameWCPattern, 44100,
                                                        2, 0, true, 9, false, false, 12, toWAV16, false, false, false, false,
                                                        0, true, false, "", false, false, true, false, false, 
                                                        3, false, 24)
                                                        
    local OutputWAV4824 = ultraschall.CreateNewRenderTable(8, 3, 0, 0, 18, 1000, OutputFilepathWAV4824,FileNameWCPattern, 48000,
                                                        2, 0, true, 9, false, false, 12, toWAV24, false, false, false, false,
                                                        0, true, false, "", false, false, true, false, false, 
                                                        3, false, 24)
    
    local OutputWAV4816 = ultraschall.CreateNewRenderTable(8, 3, 0, 0, 18, 1000, OutputFilepathWAV4816, FileNameWCPattern, 48000,
                                                        2, 0, true, 9, false, false, 12, toWAV16, false, false, false, false,
                                                        0, true, false, "", false, false, true, false, false, 
                                                        3, false, 24)
                                                        
    local OutputWAVProjSR24 = ultraschall.CreateNewRenderTable(8, 3, 0, 0, 18, 1000, OutputFilepathWAVProjSR24,FileNameWCPattern, projectSR_INT,
                                                        2, 0, true, 9, false, false, 12, toWAV24, false, false, false, false,
                                                        0, true, false, "", false, false, true, false, false, 
                                                        3, false, 24)
                                                        
    local OutputWAVProjSR16 = ultraschall.CreateNewRenderTable(8, 3, 0, 0, 18, 1000, OutputFilepathWAVProjSR16,FileNameWCPattern, projectSR_INT,
                                                        2, 0, true, 9, false, false, 12, toWAV16, false, false, false, false,
                                                        0, true, false, "", false, false, true, false, false, 
                                                        3, false, 24)
    
    local OutputMP3320CBR = ultraschall.CreateNewRenderTable(8, 3, 0, 0, 18, 1000, OutputFilepathMP3320CBR,FileNameWCPattern, projectSR_INT,
                                                        2, 0, true, 9, false, false, 12, toMP3320CBR, false, false, false, false,
                                                        0, true, false, "", false, false, true, false, false, 
                                                        3, false, 24)
                                                        
    local OutputMP3320VBR = ultraschall.CreateNewRenderTable(8, 3, 0, 0, 18, 1000, OutputFilepathMP3320VBR,FileNameWCPattern, projectSR_INT,
                                                        2, 0, true, 9, false, false, 12, toMP3320VBR, false, false, false, false,
                                                        0, true, false, "", false, false, true, false, false, 
                                                        3, false, 24)
    
    local OutputDDP = ultraschall.CreateNewRenderTable(nil, 2, nil, nil, nil, nil, OutputFilepathDDP, "IMAGE", 44100, 2, 0, nil,
                                                        9, nil, nil, nil, "IHBkZA==", false, nil, nil, nil, nil, nil, nil, nil, nil, 
                                                        nil, nil, nil, nil, nil, nil, nil, nil, nil, nil )
                                                        
    local OutputVinylSideA = ultraschall.CreateNewRenderTable(3, 2, nil, nil, nil, nil, OutputFilepathVinylSides, VinilSideA_name, projectSR_INT,
                                                           2, 0, true, 9, false, false, 3, toWAV24, false, false, false, false,
                                                           0, true, false, "", false, false, true, false, false, 
                                                           3, false, 24)
   
    local OutputVinylSideB = ultraschall.CreateNewRenderTable(3, 2, nil, nil, nil, nil, OutputFilepathVinylSides, VinilSideB_name, projectSR_INT,
                                                             2, 0, true, 9, false, false, 3, toWAV24, false, false, false, false,
                                                             0, true, false, "", false, false, true, false, false, 
                                                             3, false, 24)
          

    if (sel_WAVformat[1] == true) 
        then 
        _,_,_ = ultraschall.RenderProject_RenderTable(nil, OutputWAV4416, false, true, false)
       
    end

    if (sel_WAVformat[2] == true) 
        then 
        _,_,_ = ultraschall.RenderProject_RenderTable(nil, OutputWAV4424, false, true, false)
       
    end

    if (sel_WAVformat[3] == true) 
        then 
        _,_,_ = ultraschall.RenderProject_RenderTable(nil, OutputWAV4816, false, true, false) 
       
    end

    if (sel_WAVformat[4] == true) 
        then 
        _,_,_ = ultraschall.RenderProject_RenderTable(nil, OutputWAV4824, false, true, false)
        
    end

    if (sel_WAVformat[5] == true) 
        then 
        _,_,_ = ultraschall.RenderProject_RenderTable(nil, OutputWAVProjSR16, false, true, false)
       
    end

    if (sel_WAVformat[6] == true) 
        then 
        _,_,_ = ultraschall.RenderProject_RenderTable(nil, OutputWAVProjSR24, false, true, false)
       
    end

    if (sel_MP3format[1] == true) 
        then 
        _,_,_ = ultraschall.RenderProject_RenderTable(nil, OutputMP3320CBR, false, true, false)
      
    end

    if (sel_MP3format[2] == true) 
        then 
        _,_,_ = ultraschall.RenderProject_RenderTable(nil, OutputMP3320VBR, false, true, false)
        
    end

    if sel_DDP_Render[1] == true
        then 
        lorenzoTT_DeleteMarkersByName("#")
        lorenzoTT_DeleteMarkersByName("@")
        lorenzoTT_DeleteMarkersByName("!")
        deleteallregions = reaper.NamedCommandLookup("_SWSMARKERLIST10")
        regionsFromItems = reaper.NamedCommandLookup("_SWS_REGIONSFROMITEMS")
        reaper.Main_OnCommand(deleteallregions, 0)
        reaper.Main_OnCommand(40182, 0)
        reaper.Main_OnCommand(regionsFromItems, 0)
   
        local nnRG_yesAgain, nnRG_ARR_YA = ultraschall.GetAllRegions()
        local nb_Allmrkrs_V, mrkrs_ARR_V = ultraschall.GetAllMarkers()
        for mrkr_i_V = 1, nb_Allmrkrs_V
            do
            local mrkrName_V = mrkrs_ARR_V[mrkr_i_V][1]
            local mrkName_V_Inititals = string.sub(mrkrName_V, 1, 5)
            local sideB = "sideB"

            if  sideB:match(case_insensitive_pattern(mrkName_V_Inititals))
                then 
                SideBstartAfter1 = mrkrs_ARR_V[mrkr_i_V][0]
                SideB1_true = 0
            else
                noSideB = 1
            end
        end
            
        if SideB1_true == 0
            then 
            local nnRG_V, nnRG_ARR_V = ultraschall.GetAllRegions()
            SideA_start = nnRG_ARR_V[1][0]
            SideB_end = nnRG_ARR_V[nnRG_V][1]
            for mrkr_i_V_2 = 1, nnRG_V 
                do 
                local region_i_start = nnRG_ARR_V[mrkr_i_V_2][0]
                local region_i_end = nnRG_ARR_V[mrkr_i_V_2][1]
                if region_i_start  > SideBstartAfter1
                    then 
                    SideB_start = region_i_start
                    break
                end
                     
                  
            end
            distance_to_sideB_Start = (SideB_start - SideBstartAfter1)
            mrkrMovedBY = SideBstartAfter1 + distance_to_sideB_Start
            _ = ultraschall.MoveMarkersBy(SideBstartAfter1-1, SideBstartAfter1+1, distance_to_sideB_Start+0.00001, false)
        end
      
        erase_Time_Between_Regions()
      
        local nnRG, nnRG_ARR = ultraschall.GetAllRegions()
      
        for i_rndTrack = 1, nnRG
            do 
            local mrkrsNumb, allREGmarkersarray = ultraschall.GetAllMarkersBetween(math.floor(nnRG_ARR[i_rndTrack][0]), math.floor(nnRG_ARR[i_rndTrack][1]))
            local TrackSngWR = ""
            local TrackArtistname = ""
            local TrackISRC = ""
            for marker_1 = 1, mrkrsNumb
                do 
                local markcount_i_name = allREGmarkersarray[marker_1][1]
                local markcount_i_name = tostring(markcount_i_name)
                local artistMrkr = "artist"
                local isrcMrkr = "isrc"
                local sngWrMrkr = "sngWr"

                --if markcount_i_name DELETE #MARKER -----
                if artistMrkr:match(case_insensitive_pattern(string.sub(markcount_i_name, 1, 6)))      
                    then 
                    TrackArtistname = string.sub(markcount_i_name, 8)          
                end
                if isrcMrkr:match(case_insensitive_pattern(string.sub(markcount_i_name, 1, 4)))
                    then 
                    TrackISRC = string.sub(markcount_i_name, 6)
                end
                if sngWrMrkr:match(case_insensitive_pattern(string.sub(markcount_i_name, 1, 5)))
                    then 
                    TrackSngWR = string.sub(markcount_i_name, 7)
                end
                        
            end

                 
            local i_trackTitle = nnRG_ARR[i_rndTrack][2]
            local i_trackTitle = i_trackTitle:gsub(".mp3", "")
            local i_trackTitle = i_trackTitle:gsub(".wav", "")
            local i_trackTitle = i_trackTitle:gsub(".flac", "")
            DDP_TrackIndex = "#"..i_trackTitle.."|PERFORMER="..TrackArtistname.. "|ISRC=".. TrackISRC.. "|SONGWRITER=" .. TrackSngWR
            reaper.AddProjectMarker(nil, false, nnRG_ARR[i_rndTrack][0],0, DDP_TrackIndex , nnRG_ARR[i_rndTrack][4])
                  
        end
          
        DDP_Genre = " "
        UPC_nb = " "
        DDP_Album_Index0 = "@".. prTitle2.."|PERFORMER="..prAuth2.."|UPC="..UPC_nb.."|GENRE="..DDP_Genre.."|LANGUAGE=English"
        reaper.AddProjectMarker(nil, false, nnRG_ARR[nnRG][1],0, DDP_Album_Index0 , nnRG+1)
        if (nnRG_ARR[1][0]) == 0 
            then
            _, _ = reaper.GetSet_LoopTimeRange(true, false, round((nnRG_ARR[1][0]),3), round((nnRG_ARR[1][0]),3)+2, false)
            reaper.Main_OnCommand(40200, 0)
        elseif (nnRG_ARR[1][0]) > 0 
            then
            _, _ = reaper.GetSet_LoopTimeRange(true, false, 0, (nnRG_ARR[1][0]), false)
            reaper.Main_OnCommand(40201, 0)
            _, _ = reaper.GetSet_LoopTimeRange(true, false, 0 , 2, false)
            reaper.Main_OnCommand(40200, 0)
        end
        reaper.AddProjectMarker(nil, false,0,0, "!" , 0)
        local nnRG, nnRG_ARR = ultraschall.GetAllRegions()
        _, _ = reaper.GetSet_LoopTimeRange(true, false, 0,nnRG_ARR[nnRG][1], false)
        _,_,_ = ultraschall.RenderProject_RenderTable(nil, OutputDDP, false, true, false)  
    end
  
    if sel_DDP_Render[2] == true
        then 
        lorenzoTT_DeleteMarkersByName("#")
        lorenzoTT_DeleteMarkersByName("@")
        lorenzoTT_DeleteMarkersByName("!")
        local nnRG, nnRG_ARR = ultraschall.GetAllRegions()
        for i_rndTrack = 1, nnRG
            do
            local mrkrsNumb, allREGmarkersarray = ultraschall.GetAllMarkersBetween(round(nnRG_ARR[i_rndTrack][0],2), round(nnRG_ARR[i_rndTrack][1],2))
            local TrackSngWR = ""
            local TrackArtistname = ""
            local TrackISRC = ""
            for marker_1 = 1, mrkrsNumb
                do 
                local markcount_i_name = allREGmarkersarray[marker_1][1]
                local markcount_i_name = tostring(markcount_i_name)
                local artistMrkr = "artist"
                local isrcMrkr = "isrc"
                local sngWrMrkr = "sngWr"
                --if markcount_i_name DELETE #MARKER -----
                if artistMrkr:match(case_insensitive_pattern(string.sub(markcount_i_name, 1, 6)))
                    then    
                    TrackArtistname = string.sub(markcount_i_name, 8)
                end
                            
                if isrcMrkr:match(case_insensitive_pattern(string.sub(markcount_i_name, 1, 4)))
                    then 
                    TrackISRC = string.sub(markcount_i_name, 6)
                end
                             
                if sngWrMrkr:match(case_insensitive_pattern(string.sub(markcount_i_name, 1, 5)))
                    then 
                    TrackSngWR = string.sub(markcount_i_name, 7)
                end
                             
            end
            local i_trackTitle = nnRG_ARR[i_rndTrack][2]
            local i_trackTitle = i_trackTitle:gsub(".mp3", "")
            local i_trackTitle = i_trackTitle:gsub(".wav", "")
            local i_trackTitle = i_trackTitle:gsub(".flac", "")
            local DDP_TrackIndex = "#"..i_trackTitle.."|PERFORMER="..TrackArtistname.. "|ISRC=".. TrackISRC.. "|SONGWRITER=" .. TrackSngWR
            reaper.AddProjectMarker(nil, false, nnRG_ARR[i_rndTrack][0]+0.1,0, DDP_TrackIndex , nnRG_ARR[i_rndTrack][4])
                  
        end
        --add Album Index Marker
        local DDP_Genre = " "
        local UPC_nb = " "
        local DDP_Album_Index0 = "@".. prTitle2.."|PERFORMER="..prAuth2.."|UPC="..UPC_nb.."|GENRE="..DDP_Genre.."|LANGUAGE=English"
        reaper.AddProjectMarker(nil, false, nnRG_ARR[nnRG][1],0, DDP_Album_Index0 , nnRG+1)
        --move all project 2s later
        if (nnRG_ARR[1][0]) == 0 
            then
            _, _ = reaper.GetSet_LoopTimeRange(true, false, round((nnRG_ARR[1][0]),3), round((nnRG_ARR[1][0]),3)+2, false)
            reaper.Main_OnCommand(40200, 0)
        elseif (nnRG_ARR[1][0]) > 0 
            then
            _, _ = reaper.GetSet_LoopTimeRange(true, false, 0, (nnRG_ARR[1][0]), false)
            reaper.Main_OnCommand(40201, 0)
            _, _ = reaper.GetSet_LoopTimeRange(true, false, 0 , 2, false)
            reaper.Main_OnCommand(40200, 0)
        end
        --add index0 Marker
        reaper.AddProjectMarker(nil, false,0,0, "!" , 0)
        --Time Select form 0 to end Of last Region for DDP
        local nnRG, nnRG_ARR = ultraschall.GetAllRegions()
        _, _ = reaper.GetSet_LoopTimeRange(true, false, 0, round((nnRG_ARR[nnRG][1]),3), false)
        --Render DDP
        _,_,_ = ultraschall.RenderProject_RenderTable(nil, OutputDDP, false, true, false)
    end

    if sel_VinylSides == true
        then
        --select Sides Size to Render
        local nb_Allmrkrs_V, mrkrs_ARR_V = ultraschall.GetAllMarkers()
        for mrkr_i_V = 1, nb_Allmrkrs_V
            do
            local mrkrName_V = mrkrs_ARR_V[mrkr_i_V][1]
            local mrkName_V_Inititals = string.sub(mrkrName_V, 1, 5)
            local sideB = "sideB"
            if  sideB:match(case_insensitive_pattern(mrkName_V_Inititals))
                then 
                SideBstartAfter = mrkrs_ARR_V[mrkr_i_V][0]
                SideB1_true = 0
            else
                noSideB = 1
            end
        end
      
        local nnRG_V, nnRG_ARR_V = ultraschall.GetAllRegions()
        SideA_start = nnRG_ARR_V[1][0]
        SideB_end = nnRG_ARR_V[nnRG_V][1]
        for mrkr_i_V_2 = 1, nnRG_V 
            do 
            local region_i_start = nnRG_ARR_V[mrkr_i_V_2][0]
            local region_i_end = nnRG_ARR_V[mrkr_i_V_2][1]
            if region_i_end <= SideBstartAfter
                then 
                SideA_end = region_i_end   
            elseif (region_i_end  > SideBstartAfter) or (region_i_start  > SideBstartAfter)
                then  
                SideB_start = region_i_start
                break
            end
        end
         
        --Select SideA
        _, _ = reaper.GetSet_LoopTimeRange(true, false, SideA_start, SideA_end, false)
        --Render SideA
        _,_,_ = ultraschall.RenderProject_RenderTable(nil, OutputVinylSideA, false, true, false)
        --Select SideB
        _, _ = reaper.GetSet_LoopTimeRange(true, false, SideB_start, SideB_end, false)
        --Render SideB
        _,_,_ = ultraschall.RenderProject_RenderTable(nil, OutputVinylSideB, false, true, false)   
    end
        
    if (sel_PQsheet[1] == true) 
        then 
        --WRITE PDF TO DISK HERE---
        p = PDF.new_LorenzoTT()
        helv = p:new_font{ name = "Helvetica" }
        times = p:new_font{ name = "Times-Roman" }
        sel_Image_Size_Factor = GUI.Val("Logo Height")
        sel_Body_Offset_Factor = 690 - (sel_Image_Size_Factor)
        interlineFactor = 30
        page2true = 0
        local sel_ImageSource = GUI.Val("Logo Image Source")
        sel_Image_w, sel_Image_h = GetImageWidthHeight(sel_ImageSource)
        page = p:new_page(1,1,sel_Image_w,sel_Image_h)
        page2 = p:new_page(2,2) 
        -- Select Image File or NOT
        if GUI.Val("Logo Image Source") == "no logo"
            then  
            fileToStreamBIN = "NO LOGO"
        else  
            fileToStream = io.open(tostring(sel_ImageSource), "rb")
            fileToStreamBIN = fileToStream:read("*all")
            sel_Image_ratio = sel_Image_w / sel_Image_h
            sel_Image_h_scaled = sel_Image_Size_Factor * sel_Image_ratio
            sel_Image_scaledXpos = 293 - (sel_Image_h_scaled / 2)
            sel_Image_scaledYpos = 800 - (sel_Image_Size_Factor + 20)      
        end

        page:image_stream(fileToStreamBIN)


        page:setrgbcolor("stroke", 0, 0, 0)
        page:moveto(30, sel_Body_Offset_Factor + 45)
        page:lineto(230, sel_Body_Offset_Factor + 45)
        page:linewidth(3)
        page:stroke()
        page:save()
        
        page:setrgbcolor("stroke", 0, 0, 0)
        page:moveto(30, sel_Body_Offset_Factor - 40)
        page:lineto(570, sel_Body_Offset_Factor - 40)
        page:stroke()
        page:save()

        page:begin_text()
        page:set_font(helv, 16)
        page:set_text_pos(30,sel_Body_Offset_Factor + 50)
        page:show("PQ SHEET/CD TRACKLIST")
        page:end_text()

        page:begin_text()
        page:set_font(helv, 14)
        page:set_text_pos(30,sel_Body_Offset_Factor + 20)
        page:show("ARTIST:")
        page:end_text()
        
        page:begin_text()
        page:set_font(helv, 14)
        page:set_text_pos(100,sel_Body_Offset_Factor + 20)
        page:show(prAuth2)
        page:end_text()
        
        
        page:begin_text()
        page:set_font(helv, 14)
        page:set_text_pos(30,sel_Body_Offset_Factor)
        page:show("TITLE:")
        page:end_text()
        
        page:begin_text()
        page:set_font(helv, 14)
        page:set_text_pos(100,sel_Body_Offset_Factor)
        page:show(prTitle2)
        page:end_text()
        
        page:begin_text()
        page:set_font(helv, 14)
        page:set_text_pos(30,sel_Body_Offset_Factor - 30)
        page:show("#Index             CD Time          Duration           Track")
        page:end_text()
        
        local i_regsLenAmount = 0
        local artistmrkrdetc = {}
        
        local mrkrsNumb, allREGmarkersarray = ultraschall.GetAllMarkersBetween(nil, nil)
        
        for marker_1 = 1, mrkrsNumb
            do 
            markcount_i_name = allREGmarkersarray[marker_1][1]
            markcount_i_name = tostring(markcount_i_name)
            if (string.sub(markcount_i_name, 1, 6) == "Artist") or (string.sub(markcount_i_name, 1, 6) == "artist")
                then 
                table.insert(artistmrkrdetc, 1)
            else 
                table.insert(artistmrkrdetc, 0)
            end
        end

        artistTitleMode = table.concat(artistmrkrdetc, " " )
        is_artistMrkrs = artistTitleMode:find("1")
          
        for i_rndTrack = 1, allRegNmbr
            do 
            i_regLen = allRegArr[i_rndTrack][1] - allRegArr[i_rndTrack][0]
            i_regsLenAmount = i_regsLenAmount + i_regLen
            i_regCDTime = i_regsLenAmount - i_regLen
            i_regCDTime = reaper.format_timestr(i_regCDTime, "")
            i_regLen = reaper.format_timestr(i_regLen, "")
            i_trackTitle = allRegArr[i_rndTrack][2]
            i_trackTitle = i_trackTitle:gsub(".mp3", "")
            i_trackTitle = i_trackTitle:gsub(".wav", "")
            i_trackTitle = i_trackTitle:gsub(".flac", "")
            mrkrsNumb, allREGmarkersarray = ultraschall.GetAllMarkersBetween(allRegArr[i_rndTrack][0],allRegArr[i_rndTrack][1] )
            TrackArtistname = "nomarker"
            
            for marker_1 = 1, mrkrsNumb
                do 
                markcount_i_name = allREGmarkersarray[marker_1][1]
                markcount_i_name = tostring(markcount_i_name)
                
                if (string.sub(markcount_i_name, 1, 6) == "Artist") or (string.sub(markcount_i_name, 1, 6) == "artist")
                    then 
                    TrackArtistname = markcount_i_name:gsub("Artist=", "")
                    TrackArtistname = TrackArtistname:gsub("artist=", "")
               
                else 
                    TrackArtistname = " "
                  
                end
            end
            
          
    -- YES Artist Markers first track line (ARTIST)FORMAT:----------
            if is_artistMrkrs ~= nil
                then
                sel_Body_Offset_Factor = 710 - (sel_Image_Size_Factor)
                interlineFactor = 40
                if (string.len(i_regCDTime) == 8) and (string.len(i_regLen) == 8)
                    then
                    IndexedRenderedTrack =  allRegArr[i_rndTrack][4] .. "                      " .. i_regCDTime .. "          " .. i_regLen .. "           "  ..  "Artist: " .. TrackArtistname
                elseif  (string.len(i_regCDTime) == 8) and (string.len(i_regLen) == 9)
                    then
                    IndexedRenderedTrack =  allRegArr[i_rndTrack][4] .. "                      " .. i_regCDTime .. "        " .. i_regLen .. "           "  .. "Artist:  " .. TrackArtistname
                elseif  (string.len(i_regCDTime) == 9)  and (string.len(i_regLen) == 8) and ((string.len(tostring(allRegArr[i_rndTrack][4]))) == 1)
                    then  
                    IndexedRenderedTrack =  allRegArr[i_rndTrack][4] .. "                    " .. i_regCDTime .. "          " .. i_regLen .. "           "  .. "Artist: " .. TrackArtistname
                elseif  (string.len(i_regCDTime) == 9) and (string.len(i_regLen) == 9) and ((string.len(tostring(allRegArr[i_rndTrack][4]))) == 1)
                    then
                    IndexedRenderedTrack =  allRegArr[i_rndTrack][4] .. "                    " .. i_regCDTime .. "        " .. i_regLen .. "           "  .."Artist: " .. TrackArtistname
                elseif  (string.len(i_regCDTime) == 9) and (string.len(i_regLen) == 8) and ((string.len(tostring(allRegArr[i_rndTrack][4]))) == 2)
                    then
                    IndexedRenderedTrack =  allRegArr[i_rndTrack][4] .. "                  " .. i_regCDTime .. "          " .. i_regLen .. "           "  .."Artist: " .. TrackArtistname
                elseif  (string.len(i_regCDTime) == 9) and (string.len(i_regLen) == 9) and ((string.len(tostring(allRegArr[i_rndTrack][4]))) == 2)
                    then
                    IndexedRenderedTrack =  allRegArr[i_rndTrack][4] .. "                " .. i_regCDTime .. "        " .. i_regLen .. "           "  .."Artist: " .. TrackArtistname
                elseif  (string.len(i_regCDTime) == 11) and (string.len(i_regLen) == 9) and ((string.len(tostring(allRegArr[i_rndTrack][4]))) == 2)
                    then
                    IndexedRenderedTrack =  allRegArr[i_rndTrack][4] .. "                " .. i_regCDTime .. "        " .. i_regLen .. "           "  .."Artist: " .. TrackArtistname
                elseif  (string.len(i_regCDTime) == 11) and (string.len(i_regLen) == 8) and ((string.len(tostring(allRegArr[i_rndTrack][4]))) == 2)
                    then
                    IndexedRenderedTrack =  allRegArr[i_rndTrack][4] .. "               " .. i_regCDTime .. "          " .. i_regLen .. "           "  .."Artist: " .. TrackArtistname   
                end
              
            end
            
     
    -- NO Artist Markers first & only track line FORMAT:-----

            if  is_artistMrkrs == nil
                then
                sel_Body_Offset_Factor = 690 - (sel_Image_Size_Factor)
                interlineFactor = 30
                interLineSpace = sel_Body_Offset_Factor - ((i_rndTrack + 1) * interlineFactor)
                if  (i_rndTrack < allRegNmbr) and (interLineSpace > 50) 
                    then
                    page:setrgbcolor("stroke", 0, 0, 0)
                    page:moveto(30, interLineSpace - 8)
                    page:lineto(570, interLineSpace  - 8)
                    page:linewidth(1)
                    page:stroke()
                    previous_i_interline = i_rndTrack
                     
                elseif (i_rndTrack < allRegNmbr) and (interLineSpace < 50) 
                    then
                    interLineSpace = sel_Body_Offset_Factor - (((i_rndTrack + 1) - previous_i_interline) * interlineFactorTitle)
                    page2:setrgbcolor("stroke", 0, 0, 0)
                    page2:moveto(30, interLineSpace - 8)
                    page2:lineto(570, interLineSpace  - 8)
                    page2:linewidth(1)
                    page2:stroke()
                    page2true = 1
                end          
                 
                
                if (string.len(i_regCDTime) == 8) and (string.len(i_regLen) == 8)
                    then
                    IndexedRenderedTrack =  allRegArr[i_rndTrack][4] .. "                      " .. i_regCDTime .. "          " .. i_regLen  .. "           "  .. i_trackTitle
                elseif  (string.len(i_regCDTime) == 8) and (string.len(i_regLen) == 9)
                    then
                    IndexedRenderedTrack =  allRegArr[i_rndTrack][4] .. "                      " .. i_regCDTime .. "        " .. i_regLen .. "           "  .. i_trackTitle
                elseif  (string.len(i_regCDTime) == 9)  and (string.len(i_regLen) == 8) and ((string.len(tostring(allRegArr[i_rndTrack][4]))) == 1)
                    then  
                    IndexedRenderedTrack =  allRegArr[i_rndTrack][4] .. "                    " .. i_regCDTime .. "          " .. i_regLen .. "           "  .. i_trackTitle
                elseif  (string.len(i_regCDTime) == 9) and (string.len(i_regLen) == 8) and ((string.len(tostring(allRegArr[i_rndTrack][4]))) == 2)
                    then  
                    IndexedRenderedTrack =  allRegArr[i_rndTrack][4] .. "                  " .. i_regCDTime .. "          " .. i_regLen .. "           "  .. i_trackTitle
                elseif  (string.len(i_regCDTime) == 9) and (string.len(i_regLen) == 9)
                    then
                    IndexedRenderedTrack =  allRegArr[i_rndTrack][4] .. "                    " .. i_regCDTime .. "        " .. i_regLen .. "           "  .. i_trackTitle
                elseif  (string.len(i_regCDTime) == 11) and (string.len(i_regLen) == 9) and ((string.len(tostring(allRegArr[i_rndTrack][4]))) == 2)
                    then
                    IndexedRenderedTrack =  allRegArr[i_rndTrack][4] .. "              " .. i_regCDTime .. "        " .. i_regLen .. "           "  .. i_trackTitle
                elseif  (string.len(i_regCDTime) == 11) and (string.len(i_regLen) == 8) and ((string.len(tostring(allRegArr[i_rndTrack][4]))) == 2)
                    then
                    IndexedRenderedTrack =  allRegArr[i_rndTrack][4] .. "               " .. i_regCDTime .. "          " .. i_regLen .. "           "  .. i_trackTitle
                end
            end
            
            -- DRAW Common First Line:-----
            interLineSpace = sel_Body_Offset_Factor - ((i_rndTrack + 1) * interlineFactor)
            if interLineSpace > 50
                then
                page:begin_text()
                page:set_font(helv, 14)
                page:set_text_pos(30, interLineSpace)
                page:show(IndexedRenderedTrack)
                page:end_text()
                previous_i_rndTrack_and_artist = i_rndTrack
            elseif interLineSpace < 50
                then
                interLineSpace = 800 - (((i_rndTrack + 1) - previous_i_rndTrack_and_artist) * interlineFactorTitle)
                page2:begin_text()
                page2:set_font(helv, 14)
                page2:set_text_pos(30, interLineSpace)
                page2:show(IndexedRenderedTrack)
                page2:end_text()
                page2true = 1
            end
            
            -- YES Artist Markers second track line (TITLE):-----
            if is_artistMrkrs ~= nil
                then  
            
            -- DRAW spearation LINE:-----

            interLineSpace = sel_Body_Offset_Factor - ((i_rndTrack + 1) * interlineFactor)
            sel_Body_Offset_Factor = 690 - (sel_Image_Size_Factor)
            interlineFactorTitle = 40
                        
            if (i_rndTrack < allRegNmbr) and (interLineSpace > 50)  
                then
                page:setrgbcolor("stroke", 0, 0, 0)
                page:moveto(30, interLineSpace - 25)
                page:lineto(570, interLineSpace  - 25)
                page:linewidth(1)
                page:stroke()
                page:save()
                previous_i_rndTitleLine = i_rndTrack
                            
            elseif (i_rndTrack < allRegNmbr) and (interLineSpace < 50)
                then
                interLineSpace = 780 - (((i_rndTrack + 1) - previous_i_rndTitleLine) * interlineFactorTitle)
                page2:setrgbcolor("stroke", 0, 0, 0)
                page2:moveto(30, interLineSpace - 5)
                page2:lineto(570, interLineSpace - 5)
                page2:linewidth(1)
                page2:stroke()
                page2:save()
                page2true = 1
            end
            -- YES Artist Markers second track line (TITLE)FORMAT:-----
            if (string.len(i_regCDTime) == 8) and (string.len(i_regLen) == 8)
                then
                IndexedRenderedTitle =  " " .. "                      " .. "        " .. "          " .. "        " .. "               "  ..  "Title:   " .. i_trackTitle
            elseif  (string.len(i_regCDTime) == 8) and (string.len(i_regLen) == 9)
                then
                IndexedRenderedTitle =  " " .. "                      " .. "        " .. "        " .. "         " .. "                "  .. "Title:   " .. i_trackTitle
            elseif  (string.len(i_regCDTime) == 9)  and (string.len(i_regLen) == 8)
                then  
                IndexedRenderedTitle =  " " .. "                    " .. "         " .. "          " .. "        " .. "                "  .. "Title:   " .. i_trackTitle
            elseif  (string.len(i_regCDTime) == 9) and (string.len(i_regLen) == 9)
                then
                IndexedRenderedTitle =  " " .. "                    " .. "         " .. "        " .. "         " .. "               "  .."Title:   " .. i_trackTitle
            elseif  (string.len(i_regCDTime) == 11) and (string.len(i_regLen) == 9)
                then
                IndexedRenderedTitle =  " " .. "                    " .. "         " .. "        " .. "         " .. "               "  .."Title:   " .. i_trackTitle
            elseif  (string.len(i_regCDTime) == 11) and (string.len(i_regLen) == 8)
                then
                IndexedRenderedTitle =  " " .. "                      " .. "         " .. "        " .. "         " .. "               "  .."Title:   " .. i_trackTitle
            end
        end
            
-- DRAW second track line (TITLE):-----
          
        if  is_artistMrkrs ~= nil
            then
            interLineSpace = sel_Body_Offset_Factor - ((i_rndTrack + 1) * interlineFactorTitle)
            if interLineSpace > 50
                then
                page:begin_text()
                page:set_font(helv, 14)
                page:set_text_pos(66, interLineSpace)
                page:show(IndexedRenderedTitle)
                page:end_text()
                previous_i_rndTrackTitle = i_rndTrack
            else
                interLineSpace = 780- (((i_rndTrack + 1) - previous_i_rndTrackTitle) * interlineFactorTitle)
                page2:begin_text()
                page2:set_font(helv, 14)
                page2:set_text_pos(66, interLineSpace) 
                page2:show(IndexedRenderedTitle)
                page2:end_text()
            end
        end
                          
           
             
        interlineFactorTitle = 40
        interLineSpace = sel_Body_Offset_Factor - ((i_rndTrack + 1) * interlineFactorTitle)
            
        if  (i_rndTrack == allRegNmbr) and (interLineSpace > 50 ) 
            then
            interLineSpace = sel_Body_Offset_Factor - ((i_rndTrack + 1) * interlineFactor)
            page:setrgbcolor("stroke", 0, 0, 0)
            page:moveto(30, interLineSpace - 10)
            page:lineto(570, interLineSpace - 10)
            page:linewidth(3)
            page:stroke()
            page:save()
            totalTime = i_regsLenAmount
            totalTime = reaper.format_timestr(totalTime, "")
            lastLineSpace = sel_Body_Offset_Factor - ((allRegNmbr + 2) * interlineFactor)
            page:begin_text()
            page:set_font(helv, 14)
            page:set_text_pos(30,lastLineSpace)
            page:show("Total Time     " ..  totalTime)
            page:end_text()
        end
             
        if  (i_rndTrack == allRegNmbr) and (interLineSpace < 50) 
            then
            if previous_i_interline ~= nil 
                then previous_i_Endline = previous_i_interline
            else 
                previous_i_Endline = previous_i_rndTitleLine
            end
            interLineSpace = 780 - (((i_rndTrack + 1) - previous_i_Endline) * interlineFactorTitle)
            page2:setrgbcolor("stroke", 0, 0, 0)
            page2:moveto(30, interLineSpace - 10)
            page2:lineto(570, interLineSpace - 10)
            page2:linewidth(3)
            page2:stroke()
            page2:save()
            totalTime = i_regsLenAmount
            totalTime = reaper.format_timestr(totalTime, "")
            lastLineSpace = 780 - (((i_rndTrack + 2) - previous_i_Endline) * interlineFactorTitle)
            page2:begin_text()
            page2:set_font(helv, 14)
            page2:set_text_pos(30,lastLineSpace)
            page2:show("Total Time     " ..  totalTime)
            page2:end_text()
            end
        end
        

        page:begin_text()
        page:set_font(times, 12)

        page:end_text()

        page:restore()
        

        page:save()
        
        page:ImageCm(sel_Image_h_scaled, sel_Image_Size_Factor , sel_Image_scaledXpos, sel_Image_scaledYpos)
        page:ImageDo()
        page:restore() 

        if page2true == 0
            then
            page:begin_text()
            page:set_font(helv, 14)
            page:set_text_pos(280, 20)
            page:show("page 1/1")
            page:end_text()
            page:save()
            page:add()
        elseif page2true == 1
            then
            page:begin_text()
            page:set_font(helv, 14)
            page:set_text_pos(280, 20)
            page:show("page 1/2")
            page:end_text()
            page:save()
            page:add()
            page2:begin_text()
            page2:set_font(helv, 14)
            page2:set_text_pos(280, 20)
            page2:show("page 2/2")
            page2:end_text()
            page2:save()
            page2:add()
        end
        p:write(PQSheet_Filepath)
        
    end
        
    if not reaper.file_exists(presetFilepath) 
        then
        os.execute("mkdir " .."\"" .. presetFilepathDIR .. "\"")
        local file = io.open(presetFilepath, "w")
        io.close(file)
    end 

    -- save presets
    SaveMultiExportPresets(FileNameWCPattern,sel_ImageSource,sel_RenderDest,sel_Logo_H) 
 
end
    
reaper.Undo_EndBlock("LorenzoTT_Multi Format Mastering Render", -1)

GUI.New("WAV Renders", "Checklist", {
    z = 11,
    x = 10,
    y = 220,
    w = 200,
    h = 165,
    caption = "WAV Renders",
    optarray = {"WAV 4416", "WAV 4424", "WAV 4816", "WAV 4824", "WAV ($ProjectSampleRate)16", "WAV ($ProjectSampleRate)24"},
    dir = "v",
    pad = 4,
    font_a = 2,
    font_b = 3,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = true,
    shadow = true,
    swap = nil,
    opt_size = 20
})


GUI.New("Browse Folder Destination", "Button", {
    z = 11,
    x = 425,
    y = 170,
    w = 70,
    h = 20,
    caption = "Browse",
    font = 3,
    col_txt = "black",
    col_fill = "white",
    func = fillFolderDest
})

GUI.New("Browse Image Source", "Button", {
    z = 11,
    x = 425,
    y = 47,
    w = 70,
    h = 20,
    caption = "Browse",
    font = 3,
    col_txt = "black",
    col_fill = "white",
    func = fillImageSourceDir
})

GUI.New("Set ProjArtist", "Button", {
    z = 11,
    x = 425,
    y = 110,
    w = 70,
    h = 20,
    caption = "Set",
    font = 3,
    col_txt = "black",
    col_fill = "white",
    func = setProjAuth
})

GUI.New("Set ProjTitle", "Button", {
    z = 11,
    x = 425,
    y = 140,
    w = 70,
    h = 20,
    caption = "Set",
    font = 3,
    col_txt = "black",
    col_fill = "white",
    func = setProjTitle
})


GUI.New("MP3 Renders", "Checklist", {
    z = 11,
    x = 240,
    y = 220,
    w = 120,
    h = 70,
    caption = "MP3 Renders",
    optarray = {"MP3 320 CBR", "MP3 320 VBR"},
    dir = "v",
    pad = 4,
    font_a = 2,
    font_b = 3,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = true,
    shadow = true,
    swap = nil,
    opt_size = 20
})

GUI.New("VINYL SIDES", "Checklist", {
    z = 11,
    x = 240,
    y = 310,
    w = 120,
    h = 50,
    caption = "Vinyl Sides",
    optarray = {"A + B"},
    dir = "v",
    pad = 4,
    font_a = 2,
    font_b = 3,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = true,
    shadow = true,
    swap = nil,
    opt_size = 20
})

GUI.New("DDP Render", "Checklist", {
    z = 11,
    x = 388,
    y = 222,
    w = 110,
    h = 70,
    caption = "DDP Render",
    optarray = {"DDP Auto", "DDP Edit"},
    dir = "v",
    pad = 4,
    font_a = 2,
    font_b = 3,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = true,
    shadow = true,
    swap = nil,
    opt_size = 20
})

GUI.New("PQ Sheet", "Checklist", {
    z = 11,
    x = 388,
    y = 310,
    w = 110,
    h = 70,
    caption = "PQ Sheet",
    optarray = {"CD .pdf", "VINYL .pdf"},
    dir = "v",
    pad = 4,
    font_a = 2,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = true,
    shadow = true,
    swap = nil,
    opt_size = 20
})

GUI.New("File Name Pattern $", "Textbox", {
    z = 11,
    x = 128,
    y = 16,
    w = 370,
    h = 20,
    caption = "File Name Pattern $ : ",
    cap_pos = "left",
    font_a = 3,
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("Logo Image Source", "Textbox", {
    z = 11,
    x = 128,
    y = 48,
    w = 294,
    h = 20,
    caption = "PQ-Sheet Logo : ",
    cap_pos = "left",
    font_a = 3,
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("Renders Destination", "Textbox", {
    z = 11,
    x = 168,
    y = 170,
    w = 254,
    h = 20,
    caption = "Renders Destination Folder : ",
    cap_pos = "left",
    font_a = 3,
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("Logo Height", "Textbox", {
    z = 11,
    x = 128,
    y = 80,
    w = 40,
    h = 20,
    caption = "Logo Height : ",
    cap_pos = "left",
    font_a = 3,
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("Optional PQ-Sheet Text", "Textbox", {
    z = 11,
    x = 260,
    y = 80,
    w = 236,
    h = 20,
    caption = "opt. PQ Text : ",
    cap_pos = "left",
    font_a = 3,
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("Project Artist", "Textbox", {
    z = 11,
    x = 128,
    y = 110,
    w = 295,
    h = 20,
    caption = " Project Artist  : ",
    cap_pos = "left",
    font_a = 3,
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("Project Title", "Textbox", {
    z = 11,
    x = 128,
    y = 140,
    w = 295,
    h = 20,
    caption = " Project Title  : ",
    cap_pos = "left",
    font_a = 3,
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("lorenzoTT sign", "Label", {
    z = 11,
    x = 1,
    y = 432,
    caption = "“Script made by Lorenzo Targhetta using Lokasenna GUI and Ultraschall API“                                   ",
    shadow = false,
    font = 3,
    color = "black",
    bg = "txt"
})

GUI.New("Render Selected Formats", "Button", {
    z = 11,
    x = 240,
    y = 390,
    w = 260,
    h = 24,
    caption = "Render Selected Formats",
    font = 2,
    col_txt = "black",
    col_fill = "white",
    func = gorenderst
})

-- INTIAL PRESETS VALUES


if not reaper.file_exists(presetFilepath)
    then 
    GUI.Val("File Name Pattern $", "$region$track")
    GUI.Val("Logo Image Source", "no logo")
    GUI.Val("Renders Destination", projectFilePathNoName)
    GUI.Val("Logo Height", 150)
else
    presets_MultiExp = table.load(presetFilepath).presets_MultiExp
    GUI.Val("File Name Pattern $", presets_MultiExp.FileNamePattern)
    GUI.Val("Logo Image Source", presets_MultiExp.JPG_URL_DIR)
    GUI.Val("Renders Destination", presets_MultiExp.RenderDIR)
    GUI.Val("Logo Height", presets_MultiExp.stored_logoHeight)
end

if GUI.Val("Logo Image Source") == "no logo"
    then GUI.Val("Logo Height", 0)
end

local _, projectTitle = reaper.GetSetProjectInfo_String(nil, "PROJECT_TITLE", "no", 0)
local _, projectAUTH = reaper.GetSetProjectInfo_String(nil, "PROJECT_AUTHOR", "no", 0)
GUI.Val("Project Title", projectTitle)
GUI.Val("Project Artist", projectAUTH)


GUI.Init()
GUI.Main()