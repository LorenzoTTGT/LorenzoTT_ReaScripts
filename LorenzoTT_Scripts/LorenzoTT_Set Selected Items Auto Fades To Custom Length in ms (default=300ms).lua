--[[
ReaScript name: LorenzoTT_Set Selected Items Auto Fades To Custom Length in ms (default=300ms)
Version: 1.0
Author: LorenzoTT
]]
    local newAutoFadesLength = 300 --change the ms Auto Fades length here!
    local function no_undo()reaper.defer(function()end)end;
    local selItemsCount = reaper.CountSelectedMediaItems(0);
    if selItemsCount == 0 then no_undo() return end;
    newAutoFadesLength = newAutoFadesLength/1000;
    for i = 1,selItemsCount do;
        local selectedItem = reaper.GetSelectedMediaItem(0,i-1);
        local itemLength = reaper.GetMediaItemInfo_Value(selectedItem,"D_LENGTH");
        local fadeIn = reaper.GetMediaItemInfo_Value(selectedItem,"D_FADEINLEN");
        local fadeOut = reaper.GetMediaItemInfo_Value(selectedItem,"D_FADEOUTLEN");
        if itemLength >= (newAutoFadesLength * 2) then;
            reaper.SetMediaItemInfo_Value(selectedItem,"D_FADEINLEN",newAutoFadesLength);
            reaper.SetMediaItemInfo_Value(selectedItem,"D_FADEOUTLEN",newAutoFadesLength);
            if not Undo then;
            reaper.Undo_BeginBlock();reaper.PreventUIRefresh(1); 
            Undo = true; 
            end;
        end;
        reaper.UpdateItemInProject(selectedItem);
    end;
    if Undo then;
        reaper.Undo_EndBlock("Set fades to newAutoFadesLength",-1);
        reaper.PreventUIRefresh(-1);
    else;
        no_undo();
    end;

    reaper.UpdateArrange();
