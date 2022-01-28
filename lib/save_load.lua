local save_load = {}
local sc = sequencer_controller
local folder_path = norns.state.data .. "splnkr_data/" 
local pset_folder_path  = folder_path .. ".psets/"

function save_load.save_splnkr_data(file_name)
  if file_name then
    if os.rename(folder_path, folder_path) == nil then
      os.execute("mkdir " .. folder_path)
      os.execute("mkdir " .. pset_folder_path)
      os.execute("touch" .. pset_folder_path)
    end
    local pset_path = pset_folder_path .. file_name
    params:write(pset_path)

    local save_path = folder_path .. file_name  ..".spl"
    
    -- save sequence data
    local sequence_data = sequencer_controller.sequins_outputs_table
    
    -- save recorded sample data
    local rec_sample = {}
    rec_sample.loaded_file           = fn.deep_copy(sample_player.loaded_file)
    rec_sample.cutters               = fn.deep_copy(sample_player.cutters)
    rec_sample.cut_type              = fn.deep_copy(sample_player.cut_type)
    rec_sample.play_modes            = fn.deep_copy(sample_player.play_modes)
    rec_sample.length                = fn.deep_copy(sample_player.length)
    rec_sample.voice_rates           = fn.deep_copy(sample_player.voice_rates)
    rec_sample.cutter_assignments    = fn.deep_copy(sample_player.cutter_assignments)
    
    -- save live sample data
    local live_sample = {}
    live_sample.cutters              = fn.deep_copy(spl.cutters)
    live_sample.cut_type             = fn.deep_copy(spl.cut_type)
    live_sample.play_modes           = fn.deep_copy(spl.play_modes)
    live_sample.length               = fn.deep_copy(spl.length)
    live_sample.voice_rates          = fn.deep_copy(spl.voice_rates)
    live_sample.live_voices          = fn.deep_copy(spl.live_voices)
    live_sample.cutter_assignments   = fn.deep_copy(spl.cutter_assignments)
    
    local save_object = {}
    save_object.sequence_data        = sequence_data
    save_object.rec_sample           = rec_sample
    save_object.live_sample          = live_sample
    tab.save(save_object, save_path)
    print("saved!")
  else
    print("save cancel")
  end
end

function save_load.remove_splnkr_data(path)
   if string.find(path, 'splnkr') ~= nil then
    local data = tab.load(path)
    if data ~= nil then
      print("sequence found to remove", path)
      os.execute("rm -rf "..path)

      local start,finish = string.find(path,folder_path)

      local data_filename = string.sub(path,finish+1)
      local start2,finish2 = string.find(data_filename,".spl")
      local pset_filename = string.sub(path,finish+1,finish+start2-1)
      local pset_path = pset_folder_path .. pset_filename
      print("pset path found",pset_path)
      os.execute("rm -rf "..pset_path)  
    else
      print("no data")
    end
  end
end

function save_load.load_splnkr_data(path)
  splnkr_data = tab.load(path)
  if splnkr_data ~= nil then
    print("splnkr data found", path)
    local start,finish = string.find(path,folder_path)

    local data_filename = string.sub(path,finish+1)
    local start2,finish2 = string.find(data_filename,".spl")
    local pset_filename = string.sub(path,finish+1,finish+start2-1)
    local pset_path = pset_folder_path .. pset_filename
    print("pset path found",pset_path)
    -- load pset
    params:read(pset_path)

    -- load sequence data
    -- if sc.sequins_outputs_table then
      local sequence_data = splnkr_data.sequence_data

      for i=5,1,-1 do
        sc.sequins_outputs_table[i] = {}
        if sequence_data[i] then
          if grid_mode ~= "sequencer" then 
            grid_mode="sequencer" 
          end
          grid_sequencer.activate_grid_key_at(i,1)
          sc.reset_sequinset_value_heirarcy(i)
          if i~=1 then
            grid_sequencer.activate_grid_key_at(i,1)
          end
          sc.sequins_outputs_table[i] = fn.deep_copy(sequence_data[i])
        end
      end
      print("sequence is now loaded")
          
    -- end

    -- load recorded sample data
    sample_player.loaded_file = splnkr_data.rec_sample.loaded_file
    if sample_player.loaded_file then
      sample_player.load_file(sample_player.loaded_file, save_load.load_splnkr_data_finish, fn.deep_copy(splnkr_data))
    end
 else
    print("no data")
  end
end

function save_load.load_splnkr_data_finish(splnkr_data)
  clock.sleep(1)
  sample_player.waveform_loaded = true
  sample_player.cut_detector = CutDetector:new()
  sample_player.cut_detector.set_bright_start()
  sample_player.update()
  sample_player.autogenerate_cutters(#splnkr_data.rec_sample.cutters,splnkr_data.rec_sample.cut_type)
    
  local rec_cutters = splnkr_data.rec_sample.cutters
  
  for i=1,#rec_cutters,1 do
    for k,v in pairs(rec_cutters[i]) do 
      sample_player.cutters[i][k] = v
    end
  end
  
  sample_player.cutter_assignments = splnkr_data.rec_sample.cutter_assignments

  local rec_play_modes = splnkr_data.rec_sample.play_modes

  for i=1,3,1 do
    sample_player.set_play_mode(i, rec_play_modes[i])
  end

  sample_player.voice_rates     = splnkr_data.rec_sample.voice_rates
  sample_player.length          = splnkr_data.rec_sample.length
  sample_player.cut_type        = splnkr_data.rec_sample.cut_type
  
  sample_player.cutters_start_finish_update()
  for i=1,3,1 do sample_player.reset(i) end

  -- load live sample data
  spl.autogenerate_cutters(#splnkr_data.live_sample.cutters,splnkr_data.live_sample.cut_type)

  local live_cutters = splnkr_data.live_sample.cutters

  for i=1,#live_cutters,1 do
    for k,v in pairs(live_cutters[i]) do 
      spl.cutters[i][k] = v
    end
  end

  spl.cutter_assignments = splnkr_data.live_sample.cutter_assignments

  local live_play_modes = splnkr_data.live_sample.play_modes

  for i=4,6,1 do
    spl.set_play_mode(i,live_play_modes[i])
  end

  spl.voice_rates             = splnkr_data.live_sample.voice_rates
  spl.length                  = splnkr_data.live_sample.length
  spl.cut_type                = splnkr_data.live_sample.cut_type
  spl.live_voices             = splnkr_data.live_sample.live_voices
  spl.cutters_start_finish_update()
  for i=4,6,1 do spl.reset(i) end
end

-- function save_load.add_plant_to_garden(path)
--    if string.find(path, 'flora') ~= nil then
--     print("adding...")
--     local data = tab.load(path)
--     if data ~= nil then
--       print("plant found", path)
--       plant_to_plant = tab.load (path)
--       local plant_filename = string.gsub(path,save_path,"")
--       plant_to_plant.name=plant_filename
--       garden.add(plant_to_plant)
--     else
--       print("no data")
--     end
--   end
-- end

-- function save_load.remove_plant_from_garden(plant_to_remove)
--   print("removing plant...", plant_to_remove)
--   if plant_to_remove ~= "cancel" then
--     if string.find(plant_to_remove, 'flora') ~= nil then
--       garden.remove(plant_to_remove)
--   else
--      print("no plant found")
--     end
--  end
-- end

function save_load.init()
  -- local grid_found = false
  -- for i=1,#grid.vports,1 do
  --   if grid.vports[i].cols >= 16 then
  --     grid_found = true
  --   end
  -- end
  
  params:add_separator("DATA MANAGEMENT")
  params:add_group("splnkr data",3)

  params:add_trigger("save_splnkr_data", "> SAVE SPLNKR DATA")
  params:set_action("save_splnkr_data", function(x) textentry.enter(save_load.save_splnkr_data) end)

  params:add_trigger("remove_splnkr_data", "< REMOVE SPLNKR DATA")
  params:set_action("remove_splnkr_data", function(x) fileselect.enter(folder_path, save_load.remove_splnkr_data) end)

  params:add_trigger("load_splnkr_data", "> LOAD SPLNKR DATA" )
  params:set_action("load_splnkr_data", function(x) fileselect.enter(folder_path, save_load.load_splnkr_data) end)

  -- params:add_trigger("remove_plant_from_garden", "< REMOVE PLANT FROM GARDEN" )

  -- params:set_action("remove_plant_from_garden", function(x) 
  --   local saved_sequins = tab.load(saved_sequins_path) or {"no plants planted"}
  --   listselect.enter(saved_sequins, save_load.remove_plant_from_garden) 
  -- end)

end

return save_load
