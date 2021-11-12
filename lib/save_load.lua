local save_load = {}
local sc = sequencer_controller
local save_path = norns.state.data .. "sequences/" 
-- local saved_sequins_path = norns.state.data .. "saved_sequins.tbl"

function save_load.collect_data_for_save()
  local sequence_data = sequencer_controller.sequins_outputs_table
  return sequence_data
end

function save_load.save_sequence_data(sequence_name)
  if sequence_name then
    if os.rename(save_path, save_path) == nil then
      os.execute("mkdir " .. save_path)
    end
    
    local save_path = save_path .. sequence_name  ..".sqd"
    local data_for_save = save_load.collect_data_for_save(sequence_name)
    tab.save(data_for_save, save_path)
    print("saved!")
  else
    print("save cancel")
  end
end

function save_load.remove_sequence(path)
   if string.find(path, 'splnkr') ~= nil then
    local data = tab.load(path)
    if data ~= nil then
      print("sequence found to remove", path)
      os.execute("rm -rf "..path)
    else
      print("no data")
    end
  end
end

function save_load.load_sequence(path)
  local sequence_data = tab.load(path)
  if sequence_data ~= nil then
    print("sequence found", path)
    
    for i=1,5,1 do
      sc.sequins_outputs_table[i] = {}
      if sequence_data[i] then
        if grid_mode ~= "sequencer" then 
          grid_mode="sequencer" 
        end
        grid_sequencer.activate_grid_key_at(i,1)
        grid_sequencer.activate_grid_key_at(6,1)
        sc.sequins_outputs_table[i] = fn.deep_copy(sequence_data[i])
        sc.reset_sequinset_value_heirarcy(i)
      end
    end
    -- sc.sequins_outputs_table[target_sequinset] = {}
    -- sc.sequins_outputs_table[target_sequinset] = fn.deep_copy(sc.sequins_outputs_table[source_sequinset])
    -- clock.run(sc.activate_sequinset,target_sequinset)
    





    -- sd = sequence_data
    -- sequencer_controller.sequins_outputs_table = sequence_data
    -- sequencer_controller.active_sequin_value = {}
    -- grid_sequencer:unregister_ui_group(6,3)
    -- sequencer_controller.init()
    -- grid_sequencer.activate_grid_key_at(1,1)
    -- clock.run(sc.activate_sequinset,1)
    -- sequencer_controller:update_group("sequin_groups1",1,"on","short")
  else
    print("no data")
  end
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
  local grid_found = false
  for i=1,#grid.vports,1 do
    if grid.vports[i].cols >= 16 then
      grid_found = true
    end
  end
  
  if grid_found == true then
    params:add_separator()
    params:add_separator("SAVE SEQUENCE DATA")

    params:add_trigger("save_sequence", "> SAVE SEQUENCE")
    params:set_action("save_sequence", function(x) textentry.enter(save_load.save_sequence_data) end)

    params:add_trigger("remove_sequence", "< REMOVE SAVED SEQUENCE")
    params:set_action("remove_sequence", function(x) fileselect.enter(save_path, save_load.remove_sequence) end)

    params:add_trigger("load_sequence", "> LOAD SEQUENCE" )
    params:set_action("load_sequence", function(x) fileselect.enter(save_path, save_load.load_sequence) end)

  end
  -- params:add_trigger("remove_plant_from_garden", "< REMOVE PLANT FROM GARDEN" )

  -- params:set_action("remove_plant_from_garden", function(x) 
  --   local saved_sequins = tab.load(saved_sequins_path) or {"no plants planted"}
  --   listselect.enter(saved_sequins, save_load.remove_plant_from_garden) 
  -- end)

end

return save_load
