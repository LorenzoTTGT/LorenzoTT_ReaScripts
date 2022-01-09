--[[
ReaScript name: LorenzoTT_Project Sample Rate from Highest Item Sample Rate
Version: 1.0
Author: Lorenzo Targhetta
@changelog
  initial release
]]

function LorenzoTT_GetHighestItemSR()
  reaper.SelectAllMediaItems(0, true)
  local count_all_items = reaper.CountSelectedMediaItems(0)
  reaper.SelectAllMediaItems(0, true)
  local allitems_SR = {}

    for item_i = 0, count_all_items-1
      do
        item = reaper.GetMediaItem(0,item_i)
        take = reaper.GetMediaItemTake(item, 0 )
        source = reaper.GetMediaItemTake_Source(take)
        samplerate = reaper.GetMediaSourceSampleRate(source)
        table.insert(allitems_SR, samplerate)
    end


  highestItemSR = math.max(table.unpack(allitems_SR))
  reaper.GetSetProjectInfo(0, "PROJECT_SRATE_USE", 1, true )
  reaper.GetSetProjectInfo(0, "PROJECT_SRATE", highestItemSR, true )
end

--action
LorenzoTT_GetHighestItemSR()
reaper.Audio_Quit()
reaper.Audio_Init()
reaper.UpdateTimeline()



