-- TODO: implement subgroups
-- TODO: figure out how to implement conditional/probabilisticx controls
-- TODO: save sequencer settings
-- TODO: setup midi stop/start
-- TODO: implement 4 levels of sequins sub  groups
-- TODO: move ui_groups table and associated getters/setters from grid_sequencer.lua to here

-- ui groups heirarchy
--  sequins group[1-5]:     each group defines contains a pattern and a sequins sequence
--  sequins subgroup[a-d]:  details TBD (general idea: each sub group is a copy of group above it)
--  sequin selector:        selects a sequin for editing up to 9 sequin(s) per sequins group)
--  output type:            a type of output (e.g. softcut, device, effect, etc.)
--  output:                 examples: softcut voice 1, just friends, delay effect, etc.
--  output mode:            some outputs have modes (e.g. just friends play_note, w/ delay mode, etc.
--  output params:          some outputs/output modes have more than 1 param  
--                            (e.g. just friends-play_note has 2 params: pitch and level)
--  value controlspec:      a "controlspec" for each output/output mode param

local sequencer_controller = {}
sqc = sequencer_controller

-- placeholder until views are implemented for the sequencer controller
sequencer_controller.from_view = 1

-- UI data
sequencer_controller.selected_sequin_groups = nil
sequencer_controller.selected_sequin_subgroups = nil 
sequencer_controller.selected_sequin = nil
sequencer_controller.selected_sequin_output_type = nil
sequencer_controller.selected_sequin_output = nil
sequencer_controller.selected_sequin_output_mode = nil
sequencer_controller.selected_sequin_output_param = nil
sequencer_controller.value_place_integer = nil
sequencer_controller.value_place_decimal = nil
-- sequencer_controller.value_polarity = nil
sequencer_controller.number_sequence_mode = nil
sequencer_controller.value_number = nil
sequencer_controller.value_option = nil

sequencer_controller.selectors_x_offset = 5
sequencer_controller.value_polarity = 1
-- value data 
sequencer_controller.sequins_outputs_table = {}

sequencer_controller.grid_input_processors = {}

sequencer_controller.active_sequin_value = {}
sequencer_controller.active_sequin_value.place_values = {}
sequencer_controller.active_sequin_value.place_values.ten_thousands  =  0
sequencer_controller.active_sequin_value.place_values.thousands      =  0
sequencer_controller.active_sequin_value.place_values.hundreds       =  0
sequencer_controller.active_sequin_value.place_values.tens           =  0
sequencer_controller.active_sequin_value.place_values.ones           =  0
sequencer_controller.active_sequin_value.place_values.tenths         =  0
sequencer_controller.active_sequin_value.place_values.hundredths     =  0
sequencer_controller.active_sequin_value.place_values.thousandths    =  0

function sequencer_controller.init()
  sequencer_controller.lattice = Lattice:new{
    auto = true,
    meter = 1/4,
    ppqn = 96
  }

  sequin_processor.init()
  devices_crow_processor.init()
  
  sequencer_controller.refresh_output_control_specs_map()
  sequencer_controller.sequencers = {}
  sequencer_controller.sequencers[1] = Sequencer:new(sequencer_controller.lattice,1)
  sequencer_controller.sequencers[2] = Sequencer:new(sequencer_controller.lattice,2)
  sequencer_controller.sequencers[3] = Sequencer:new(sequencer_controller.lattice,3)
  sequencer_controller.sequencers[4] = Sequencer:new(sequencer_controller.lattice,4)
  sequencer_controller.sequencers[5] = Sequencer:new(sequencer_controller.lattice,5)
  sequencer_controller.lattice:start()
end

function sequencer_controller.copy_paste_sequinsets(source_sequinset, target_sequinset)
  print("copy/paste",source_sequinset, target_sequinset)
  sequencer_controller.sequins_outputs_table[target_sequinset] = fn.deep_copy(sequencer_controller.sequins_outputs_table[source_sequinset])
  clock.run(sequencer_controller.activate_sequinset,target_sequinset)
end

function sequencer_controller.activate_sequinset(target_sequinset)
  sequencer_controller.reset_sequinset_value_heirarcy(target_sequinset)
  clock.sleep(0.2)
  print("activate",target_sequinset)
  clock.run(grid_sequencer.activate_grid_key_at,target_sequinset,1,0.2)
end

function sequencer_controller.reset_sequinset_value_heirarcy(sgp,inner_table)
  local tab = inner_table and inner_table or sequencer_controller.sequins_outputs_table[sgp]
  -- local table_type
  for k, v in pairs(tab) do 
    if type(v) == "table" then
      sequencer_controller.reset_sequinset_value_heirarcy(sgp,v)
    end
    if k == "value_heirarchy" then
      v.sgp = sgp
    end
  end
end

-----------------------

function sequencer_controller.copy_paste_sequence_data(source_id, target_id, data_path, end_node)
  -- source_table = sequencer_controller.sequins_outputs_table
  -- target_table = sequencer_controller.sequins_outputs_table
  -- for i=1,#data_path,1 do
  --   source_table = source_table[data_path[i]]
  --   -- target_table = target_table[data_path[i]]
  -- end
  -- source_table = source_table[source_id]
  -- target_table = target_table[target_id]
  local target_table
  if #data_path == 2 then
    local source_table = sequencer_controller.sequins_outputs_table[data_path[1]][data_path[2]][source_id]
    -- target_table = sequencer_controller.sequins_outputs_table[data_path[1]][data_path[2]][target_id]
    sequencer_controller.sequins_outputs_table[data_path[1]][data_path[2]][target_id] = fn.deep_copy(source_table)
    target_table = sequencer_controller.sequins_outputs_table[data_path[1]][data_path[2]][target_id]
  end
  sequencer_controller.update_value_heirarcy(end_node, target_id, target_table)
  clock.run(sequencer_controller.activate_target,target_id)
end

function sequencer_controller.activate_target(target_id)
  clock.sleep(0.2)
  clock.run(grid_sequencer.activate_grid_key_at,target_id+5,1,0.1)
end

function sequencer_controller.update_value_heirarcy(end_node,end_node_value, output_data_table)
  -- local tab = inner_table and inner_table or sequencer_controller.sequins_outputs_table[sgp][ssg][target_id]
  -- local table_type
  for k, v in pairs(output_data_table) do 
    if type(v) == "table" then
      sequencer_controller.update_value_heirarcy(end_node,end_node_value,v)
    end
    if k == "value_heirarchy" then
      print("found value heirarchy before", v[end_node],end_node_value)
      v[end_node] = end_node_value
      print("found value heirarchy after", v[end_node],end_node_value)
    end
  end
end

-----------------------
function sequencer_controller.reset_active_sequin_value()
  sequencer_controller.active_sequin_value = {}
  -- if sequencer_controller.sequin_output_types then sequencer_controller:unregister_ui_group(6,2) end
end



-- set in update_value_place_integers and update_value_place_decimals
sequencer_controller.active_value_selector_place = nil 


-- utilities
function sequencer_controller.print_svt()
  for k, v in pairs(sequencer_controller.active_sequin_value) do print(k,v) end
end

function sequencer_controller.print_outputs_table(inner_table)
  -- debug = 1
  local tab_to_print = inner_table and inner_table or sequencer_controller.sequins_outputs_table
  -- local table_type
  for k, v in pairs(tab_to_print) do 
    if type(v) == "table" then
      sequencer_controller.print_outputs_table(v)
    end
    if k == "value_heirarchy" then
      -- tab.print(v)
      -- print(">>>>>")
    end
    if k == "output_data" then
      -- do something???
      tab.print(v)
      
    end
  end
  -- debug = 0
end

-- maps
-- output map: the values represent the number of different outputs for each output type
sequencer_controller.outputs_map = {
  6, -- softcut voices NOTE: the sequencer will only allow 6 voices to play at once
  4, -- devices (midi, crow, just friends, w/)
  7, -- effects (amp, drywet, pitchshift, pitchshift offset, pitchshift array (8)
  3, -- enveloper 
  2, -- pattern 
  5, -- lattice
}

-- note: '(nil)' means the output mode takes just 1 param) 
sequencer_controller.output_mode_map = {
  {nil,nil,nil,nil,nil,nil},                        -- softcut 
  {nil,2,3,2},                  -- devices midi out (nil), crow(2), just_friends(5),w/(2)
  {nil,nil,nil,nil,8,nil,nil},  -- effects: amp(nil), drywet(nil), pitchshift(nil), pitchshift offset(nil), pitchshift array (8)
  {nil},                        -- enveloper: on/off (nil), trig_rate(nil), overlap (nil)
  {nil,nil},                    -- pattern (division)
  {nil,nil,nil,nil,nil}         -- lattice: set_meter (nil), auto_pulses (nil), ppqn (nil))
}

-- note: '(nil)' means just 1 output param' 
sequencer_controller.output_params_map = {
  {
    -- 4 softcut output params: 
    --    sample_cut_num: 1-10 ????
    --    rate: -20 - 20 ??????
    --    rate_direction: -1, 1
    --    level: 0-1
    5,5,5,5,5,5
  }, 
  {nil,{nil,nil},{2,3,nil},{nil,nil}}, -- device (midi out (nil), crow(2), just_friends(3),w/(2))
  {nil,nil,nil,nil,{nil,nil,nil,nil,nil,nil,nil,nil},nil,nil}, -- effect (amp(nil), drywet(nil), pitchshift(nil), pitchshift offset(nil), pitchshift array (8)), phaser(nil), delay(nil)
  {nil,nil,nil}, -- enveloper 
  {nil,nil}, -- pattern
  {nil,nil,nil,nil,nil,nil},  -- lattice 
}

function sequencer_controller.get_num_cutters()
  return #cutters > 0 and #cutters or 1
end

function sequencer_controller.get_output_control_specs_map()
  local map = sequencer_controller.output_control_specs_map and sequencer_controller.output_control_specs_map or nil
  return map
end

function sequencer_controller.refresh_output_control_specs_map()
  local num_cutters = sequencer_controller.get_num_cutters()
  local cutters = {}
  for i=1,num_cutters,1 do table.insert(cutters,i) end
  sequencer_controller.output_control_specs_map = {
    {
      -- 4 softcut output params: 
      --    sample_cut_num: 1-10 ????
      --    rate: -20 - 20 ??????
      --    rate_direction: -1, 1
      --    level: 0-1
      {
        {"option",{"stop","loop all", "all cuts", "sel cut"},2,nil,"v_mode","v_mode"},      -- play mode
        {"option",cutters,nil,"cutter","cutter"},  -- cutter
        {"number","0.00",20.00,1,"rate","rate"},    -- rate
        {"option",{-1,1},2,nil,"direction","direction"},      -- direction
        {"number",'0.00',10,0.20,"level","level"}         -- level (amp)
      },  
      {{"option",{"stop","loop all", "all cuts", "sel cut"},2,nil,"v_mode","v_mode"},{"option",cutters,nil,"cutter","cutter"},{"number","0.00",20.00,1,"rate","rate"},{"option",{-1,1},2,nil,"direction","direction"},{"number",'0.00',10,"level","level"}},  
      {{"option",{"stop","loop all", "all cuts", "sel cut"},2,nil,"v_mode","v_mode"},{"option",cutters,nil,"cutter","cutter"},{"number","0.00",20.00,1,"rate","rate"},{"option",{-1,1},2,nil,"direction","direction"},{"number",'0.00',10,"level","level"}},  
      {{"option",{"stop","loop all", "all cuts", "sel cut"},2,nil,"v_mode","v_mode"},{"option",cutters,nil,"cutter","cutter"},{"number","0.00",20.00,1,"rate","rate"},{"option",{-1,1},2,nil,"direction","direction"},{"number",'0.00',10,"level","level"}},  
      {{"option",{"stop","loop all", "all cuts", "sel cut"},2,nil,"v_mode","v_mode"},{"option",cutters,nil,"cutter","cutter"},{"number","0.00",20.00,1,"rate","rate"},{"option",{-1,1},2,nil,"direction","direction"},{"number",'0.00',10,"level","level"}},  
      {{"option",{"stop","loop all", "all cuts", "sel cut"},2,nil,"v_mode","v_mode"},{"option",cutters,nil,"cutter","cutter"},{"number","0.00",20.00,1,"rate","rate"},{"option",{-1,1},2,nil,"direction","direction"},{"number",'0.00',10,"level","level"}},  
    }, 
    { -- device (, crow(2), just_friends(3),w/(2))
      {"number",-24,36,nil,"midi_note","midi note"}, -- midi out
      { -- crow
        {"number",-24,36,nil,"volts","volts"}, -- volts
        {"number",-24,36,nil,"drum","drum"} -- drums ??????????????
      }, 
      { -- just friends
        {{"number",-24,36,nil,"pitch","pitch"},{"number",'0.00',10,nil,"level","level"}}, -- play_note: pitch, level
        {{"number",1,6,nil,"channel"},{"number",-24,36,nil,"pitch","pitch"},{"number",'0.00',10,nil,"level","level"}}, -- play_voice: channel, pitch, level
        {"number",-24,3,nil,6,"pitch_portamento","pitch portamento"}, -- play_note: pitch (portamento)
      }, 
      {  -- w/
        {"number",-24,36,nil,"pitch","pitch"},          -- w_syn: pitch
        {"number",-24,36,nil,"pitch","pitch"}           -- w_del karplus: pitch
      }, 
    },
    {   -- effects (, pitchshift array (8))
      {"number",'0.00',10,nil,{"level","level"}},                -- level (amp)
      {"number",'0.00',10,nil,"drywet","drywet"},                -- drywet
      {"number",'0.00',10,nil,"pitchshift","pitchshift"},                -- pitchshift
      {"number",'0.00',10,nil,"pitchshift_offset","pitchshift offset"},                -- pitchshift offset
      {                               -- pitchshift array
        {"number",-24,36,"pitchshift_note_1","pitchshift note 1"},
        {"number",-24,36,"pitchshift_note_2","pitchshift note 2"},
        {"number",-24,36,"pitchshift_note_3","pitchshift note 3"},
        {"number",-24,36,"pitchshift_note_4","pitchshift note 4"},
        {"number",-24,36,"pitchshift_note_5","pitchshift note 5"},
        {"number",-24,36,"pitchshift_note_6","pitchshift note 6"},
        {"number",-24,36,"pitchshift_note_7","pitchshift note 7"},
        {"number",-24,36,"pitchshift_note_8","pitchshift note 8"}
      },
      {"number",'0.00',10,nil,"phaser","phaser"}, -- phaser
      {"number",'0.00',10,nil,"delay","delay"} -- delay
    }, 
    {   -- enveloper 
      {"option",{"off","on"},nil,nil,"enveloper_off_on","enveloper off/on"},        -- off/on
      {"number", 0.01, 50.00,nil,"trig_rate","trig rate"},        -- trig_rate 0.01 - 50.00
      {"number",'0.00',1,nil,"overlap","overlap"}                  -- overlap 0-1
    },
    {   -- pattern (TODO: replace with more flexible pattern division selector)
      {"option",{1,1/2,1/4,1/8,1/16,1/3,2/3,1/4,3/4,1/8,1},nil,nil,"pattern_division","pattern division"},                   -- pattern division 1-18/1-18
      {"option",{"stop","start","toggle"},nil,"stop_start_toggle","stop/start/toggle"} -- stop/start/toggle pattern 
      
    }, 
    {   -- lattice 
      {                                 
        "option",{"stop","start","toggle",nil,nil,"stop_start_toggle","stop/start/toggle"}         -- stop/start/toggle pattern
      },
      {"number",1,18,nil,"meter","meter"},                  -- meter: quarter notes per measure
      {"option",{"off","on"},nil,1,"autopulse_off_on","autopulse off/on"},        -- auto pulse(s) off/on
      {"option",{"off","on"},nil,nil,"manual_pulse_off_on","manual pulse off/on"},          -- manual pulse off/on (NOTE: setting is ignored if auto_pulse is enabled)
      {"option",{12,24,36,48,60,72,84,96,108},8,nil,"ppqn","ppqn"},          -- ppqn (default 96)
      {"option",{"off","reset","hard reset"},nil,nil,"off/reset/hard reset","off/reset/hard reset"}                  
    },  
  }
end

function sequencer_controller:unregister_ui_group(x1,y1)
  -- todo: figure out why the value selector row needs to be "manually" turned off
  for i=6,14,1 do
    local level = grid_sequencer:get_current_level_at(i, 6, 1)
    if level == "on" then
      grid_sequencer:unregister_flicker_at(i, 6)
      grid_sequencer:set_current_level_at(i, 6, 1, "off")  
    end
  end

  local groups_unregistered = grid_sequencer:unregister_ui_group(x1,y1)
  if groups_unregistered then 
    for i=1,#groups_unregistered,1 do
      local group_num,group_name = table.unpack(groups_unregistered[i])
      sequencer_controller[group_name] = nil
    end
  end
  local selected_outputs = {
    sequencer_controller.selected_sequin_output,
    sequencer_controller.selected_sequin_output_mode,
    sequencer_controller.selected_sequin_output_param,
    sequencer_controller.active_sequin_value
  } 
  if selected_outputs[y1-2] then 
    selected_outputs[y1-2] = nil
  end
end


-----------------------------------         ------------------------------------------------------------------------
-----------------------------------         ------------------------------------------------------------------------
-----------------------------------         ------------------------------------------------------------------------
-------------         ----------------------------------------------------------------------------------------------
-------------         ----------------------------------------------------------------------------------------------
------------------------------------------------------------          ----------------------------------------------
------------------------------------------------------------          ----------------------------------------------
--
--
--
--
-------------------------------------------------------------------------
--
-- UI GROUP FUNCTIONS START HERE
--
-------------------------------------------------------------------------
--
--
--
--
--
-- row 1: cols 1-5
-- ui groups 1-5 sequins groups - functions
--

-- UI functions
function sequencer_controller.get_active_sequin_groups()
  return sequencer_controller.selected_sequin_groups
end

function sequencer_controller.set_selected_sequin_groups(index,state)
  sequencer_controller.active_value_heirarchy = nil
  if state == "on" then
    for i=1,5,1 do
      for j=1,1,1 do
        if i ~= index then
          grid_sequencer:solid_off(i, j, sequencer_controller.from_view)  
        end
      end
    end
    sequencer_controller.selected_sequin_groups = index or nil
    sequencer_controller.selected_sequin_subgroups = 1
    sequencer_controller.set_ui_sequin_selector()
    -- print(sequencer_controller.lattice.enabled)
    if sequencer_controller.lattice.enabled == false then 
      sequencer_controller.lattice:start()
    end
  else
    -- print(sequencer_controller.lattice.enabled)
    if sequencer_controller.lattice.enabled == true then 
      sequencer_controller.lattice:stop()
    end
    -- sequencer_controller:unregister_ui_group(6,1)
    -- sequencer_controller.selected_sequin_groups = nil
    -- sequencer_controller.selected_sequin_subgroups = nil
    -- sequencer_controller.selected_sequin = nil
    -- sequencer_controller.selected_sequin_output_type = nil
    -- sequencer_controller.selected_sequin_output = nil
    -- sequencer_controller.selected_sequin_output_mode = nil
    -- sequencer_controller.selected_sequin_output_param = nil
    -- sequencer_controller.value_place_integer = nil
    -- sequencer_controller.value_place_decimal = nil
    -- sequencer_controller.value_polarity = nil
    -- sequencer_controller.number_sequence_mode = nil      
    -- sequencer_controller.value_number = nil
    -- sequencer_controller.value_option = nil
    -- sequencer_controller.active_output_value_text = nil
  end
end

-----------------------------
--  row 1: cols 6-14
--  ui group 6 sequin selector - functions
-----------------------------
-- UI functions
function sequencer_controller.set_selected_sequin(index)
  sequencer_controller.selected_sequin = index
end


function sequencer_controller.set_ui_sequin_selector()
  sequencer_controller.sequin_selector = grid_sequencer:register_ui_group("sequin_selector",6,1,14,1,2,3)
  local selected_sequin = sequencer_controller.selected_sequin
  for i=6,14,1 do
    for j=1,1,1 do
      if i ~= selected_sequin then
        grid_sequencer:solid_off(i, j, sequencer_controller.from_view)  
      end
    end
  end
  if selected_sequin then
    local selected_sequin_offset = 5
    grid_sequencer:solid_on(selected_sequin+selected_sequin_offset, 1, 1) 
  end
end

function sequencer_controller.update_sequin_selector(x, y, state)
  if state == "on" then
    local num_output_types = #sequencer_controller.outputs_map
    -- if sequencer_controller.sequin_output_types then sequencer_controller:unregister_ui_group(6,2) end
    if sequencer_controller.sequin_output_types == nil then 
      sequencer_controller.sequin_output_types = grid_sequencer:register_ui_group("sequin_output_types",6,2,5+num_output_types,2,4,3)
    end
    -- sequencer_controller.sequins_mods = grid_sequencer:register_ui_group("sequins_mods",15,2,15,7,7,3)
    sequencer_controller.set_selected_sequin(x - sequencer_controller.selectors_x_offset)
  else
    -- sequencer_controller.active_value_heirarchy = nil
    -- sequencer_controller:unregister_ui_group(6,2)
    -- sequencer_controller.selected_sequin = nil
    -- sequencer_controller.selected_sequin_output_type = nil
    -- sequencer_controller.selected_sequin_output = nil
    -- sequencer_controller.selected_sequin_output_mode = nil
    -- sequencer_controller.selected_sequin_output_param = nil
    -- sequencer_controller.value_place_integer = nil
    -- sequencer_controller.value_place_decimal = nil
    -- sequencer_controller.value_polarity = nil
    -- sequencer_controller.number_sequence_mode = nil
    -- sequencer_controller.value_number = nil
    -- sequencer_controller.value_option = nil
    -- sequencer_controller.active_output_value_text = nil
  end
end

-----------------------------
--  row 2: cols 6-14
-- ui group 7 sequins modifiers - functions
-----------------------------
-- UI functions
function sequencer_controller.update_sequins_mods(x, y, state)
  if state == "on" then
  
  else
  
  end
end


-----------------------------
-- rows 2-7, col 15
-- ui group 8 sequin output types - functions
-----------------------------

-- UI functions
function sequencer_controller.update_sequin_output_types(x, y, state)
  sequencer_controller.active_value_heirarchy = nil
  if state == "on" then
    local  output_type_selected = x - sequencer_controller.selectors_x_offset
    sequencer_controller.selected_sequin_output_type =   output_type_selected
    sequencer_controller:unregister_ui_group(6,3)
    local num_outputs = sequencer_controller.outputs_map[output_type_selected]
    -- if sequencer_controller.sequin_output_modes then 
    --   sequencer_controller:unregister_ui_group(6,4)
    -- elseif sequencer_controller.sequin_output_params then
    --   sequencer_controller:unregister_ui_group(6,5)
    -- end

    sequencer_controller.sequin_outputs = grid_sequencer:register_ui_group("sequin_outputs",6,3,5+num_outputs,3,7,3)
  else
    sequencer_controller:unregister_ui_group(6,3)
    sequencer_controller.selected_sequin_output = nil
    sequencer_controller.selected_sequin_output_mode = nil
    sequencer_controller.selected_sequin_output_param = nil
    sequencer_controller.value_place_integer = nil
    sequencer_controller.value_place_decimal = nil
    sequencer_controller.value_polarity = nil
    sequencer_controller.number_sequence_mode = nil
    sequencer_controller.value_number = nil
    sequencer_controller.value_option = nil
    sequencer_controller.active_output_value_text = nil
  end
end

-----------------------------
--  row 3: cols 6-14
-- ui group 9 sequin outputs - functions
-----------------------------

-- UI functions
function sequencer_controller.update_sequin_outputs(x, y, state)
  -- sequencer_controller.unregister_value_selectors()
  -- sequencer_controller.selected_sequin_output = nil
  -- sequencer_controller.selected_sequin_output_mode = nil
  -- sequencer_controller.selected_sequin_output_param = nil
  sequencer_controller.active_value_heirarchy = nil
  if state == "on" then
    local output_type_selected = sequencer_controller.selected_sequin_output_type
    local output_selected = x - sequencer_controller.selectors_x_offset
    sequencer_controller.selected_sequin_output = output_selected

    if sequencer_controller.sequin_output_modes then 
      sequencer_controller:unregister_ui_group(6,4)
    elseif sequencer_controller.sequin_output_params then
      sequencer_controller:unregister_ui_group(6,5)
    else 
      for i=1,14,1 do
        if grid_sequencer:find_ui_group_num_by_xy(i,6) then
          sequencer_controller:unregister_ui_group(i,6)
        end
      end
      for i=1,14,1 do
        if grid_sequencer:find_ui_group_num_by_xy(i,7) then
          sequencer_controller:unregister_ui_group(i,7)
        end
      end
    end
    local num_output_modes = sequencer_controller.output_mode_map[output_type_selected][output_selected]
    local num_output_params = sequencer_controller.output_params_map[output_type_selected][output_selected]
    -- if #sequencer_controller.output_mode_map[output_type_selected][output_selected] > 0 then -- there are output sub types
    if num_output_modes then -- the output selected has output_modes, show them
      sequencer_controller.sequin_output_modes = grid_sequencer:register_ui_group("sequin_output_modes",6,4,5+num_output_modes,4,7,3)
    elseif num_output_params then -- no output_modes, show the output params if there are any
      sequencer_controller.sequin_output_params = grid_sequencer:register_ui_group("sequin_output_params",6,5,5+num_output_params,5,7,3)
    else -- show value setters
      sequencer_controller.set_sequin_output_value_controls()
    end
  else

    if sequencer_controller.sequin_output_modes then 
      sequencer_controller:unregister_ui_group(6,4)
    elseif sequencer_controller.sequin_output_params then
      sequencer_controller:unregister_ui_group(6,5)
    else
      for i=1,14,1 do
        if grid_sequencer:find_ui_group_num_by_xy(i,6) then
          sequencer_controller:unregister_ui_group(i,6)
        end
      end
      for i=1,14,1 do
        if grid_sequencer:find_ui_group_num_by_xy(i,7) then
          sequencer_controller:unregister_ui_group(i,7)
        end
      end
    end
    sequencer_controller.selected_sequin_output = nil
    sequencer_controller.selected_sequin_output_mode = nil
    sequencer_controller.selected_sequin_output_param = nil
    sequencer_controller.value_place_integer = nil
    sequencer_controller.value_place_decimal = nil
    sequencer_controller.value_polarity = nil
    sequencer_controller.number_sequence_mode = nil
    sequencer_controller.value_number = nil
    sequencer_controller.value_option = nil
    sequencer_controller.active_output_value_text = nil
  end
end

-----------------------------
--  row 4: cols 6-14
-- ui group 10 sequin output modes - functions
-----------------------------
-- UI functions
function sequencer_controller.update_sequin_output_modes(x, y, state)
  -- sequencer_controller.unregister_value_selectors()
  -- sequencer_controller.selected_sequin_output_param = nil
  -- sequencer_controller.active_value_heirarchy = nil
  if state == "on" then
    local output_mode_selected = x - sequencer_controller.selectors_x_offset
    sequencer_controller.selected_sequin_output_mode = output_mode_selected
    local output_type_selected = sequencer_controller.selected_sequin_output_type
    local output_selected = sequencer_controller.selected_sequin_output
    local num_output_mode_params = sequencer_controller.output_params_map[output_type_selected][output_selected][output_mode_selected]
    if sequencer_controller.sequin_output_params then
      sequencer_controller:unregister_ui_group(6,5)
    end
    for i=1,14,1 do
      if grid_sequencer:find_ui_group_num_by_xy(i,7) then
        sequencer_controller:unregister_ui_group(i,7)
      end
    end

    if num_output_mode_params then
      sequencer_controller.sequin_output_params = grid_sequencer:register_ui_group("sequin_output_params",6,5,5+num_output_mode_params,5,7,3)
    else
      -- just 1 param: show values
      sequencer_controller.set_sequin_output_value_controls()
    end
  else
    sequencer_controller:unregister_ui_group(6,5)
    for i=1,14,1 do
      if grid_sequencer:find_ui_group_num_by_xy(i,7) then
        sequencer_controller:unregister_ui_group(i,7)
      end
    end
    -- sequencer_controller.unregister_value_selectors()
    sequencer_controller.selected_sequin_output_mode = nil
    sequencer_controller.selected_sequin_output_param = nil
    sequencer_controller.value_place_integer = nil
    sequencer_controller.value_place_decimal = nil
    sequencer_controller.value_polarity = nil
    sequencer_controller.number_sequence_mode = nil
    sequencer_controller.value_number = nil
    sequencer_controller.value_option = nil
    sequencer_controller.active_output_value_text = nil
  end
end


-----------------------------
--  row 5: cols 6-14
-- ui group 11 sequin output params - functions
-----------------------------
-- UI functions
function sequencer_controller.update_sequin_output_params(x, y, state)
  -- sequencer_controller.unregister_value_selectors()
  sequencer_controller.active_value_heirarchy = nil
  if state == "on" then
    sequencer_controller.selected_sequin_output_param = x - sequencer_controller.selectors_x_offset
    --SHOW VALUE SETTERS
    sequencer_controller:unregister_ui_group(6,6)
    for i=1,14,1 do
      if grid_sequencer:find_ui_group_num_by_xy(i,7) then
        sequencer_controller:unregister_ui_group(i,7)
      end
    end
    sequencer_controller.set_sequin_output_value_controls()
  else
    for i=1,14,1 do
      if grid_sequencer:find_ui_group_num_by_xy(i,7) then
        sequencer_controller:unregister_ui_group(i,7)
      end
    end
    sequencer_controller:unregister_ui_group(6,6)
    sequencer_controller.selected_sequin_output_param = nil
    sequencer_controller.value_place_integer = nil
    sequencer_controller.value_place_decimal = nil
    sequencer_controller.value_polarity = nil
    sequencer_controller.number_sequence_mode = nil
    sequencer_controller.value_number = nil
    sequencer_controller.value_option = nil
    sequencer_controller.active_output_value_text = nil
    -- sequencer_controller.unregister_value_selectors()
  end
end

----------------------------------
--  row 7: cols 6-14
-- 8-10 sequin output control specs (options/number place settings)
----------------------------------
function sequencer_controller.set_sequin_output_value_controls()
  sequencer_controller.update_active_value_heirarchy()
  local output_type_selected = sequencer_controller.selected_sequin_output_type
  local output_selected = sequencer_controller.selected_sequin_output
  local output_mode_selected = sequencer_controller.selected_sequin_output_mode
  local output_param_selected = sequencer_controller.selected_sequin_output_param
  
  if output_param_selected and grid_sequencer:find_ui_group_num_by_xy(6,5) then -- the output has multiple params, check if it also has modes
    if output_mode_selected and grid_sequencer:find_ui_group_num_by_xy(6,4) then -- the output has modes and multiple params
      --output param selected with modes
      sequencer_controller.refresh_output_control_specs_map()
      sequencer_controller.output_control_specs_selected = 
        sequencer_controller.output_control_specs_map[output_type_selected][output_selected][output_mode_selected][output_param_selected]
    else -- the output has just params
      sequencer_controller.refresh_output_control_specs_map()
      sequencer_controller.output_control_specs_selected = 
        sequencer_controller.output_control_specs_map[output_type_selected][output_selected][output_param_selected]
    end
  elseif output_mode_selected and grid_sequencer:find_ui_group_num_by_xy(6,4) then -- the output has modes but no params
    --output mode selected, no params
    sequencer_controller.refresh_output_control_specs_map()
    sequencer_controller.output_control_specs_selected = 
      sequencer_controller.output_control_specs_map[output_type_selected][output_selected][output_mode_selected]
  elseif output_selected and grid_sequencer:find_ui_group_num_by_xy(6,3) then -- the output doesn't have either modes or multiple params
    --output selected, neither nodes nor params
    sequencer_controller.refresh_output_control_specs_map()
    sequencer_controller.output_control_specs_selected = 
      sequencer_controller.output_control_specs_map[output_type_selected][output_selected]
  end
  sequencer_controller.set_output_values(sequencer_controller.output_control_specs_selected)
end

-- todo: address use case where control_max is < 0
-- todo: make this function less horribly written
function sequencer_controller.set_output_values(control_spec)
  local control_type = control_spec[1]
  local control_default_index = control_spec[4] or 1
  sequencer_controller.active_sequin_control_id = control_spec[5]
  sequencer_controller.active_sequin_control_name = control_spec[6]
  if control_type == "number" then
    local control_min, control_max
    
    if sequencer_controller.number_selector_sequence_mode == nil then
      sequencer_controller.number_selector_sequence_mode = grid_sequencer:register_ui_group("number_selector_sequence_mode",4,6,5,6,10,6,control_spec, 5)
    end
    
    local polarity = sequencer_controller.value_polarity and sequencer_controller.value_polarity or 1
    control_min = tonumber(control_spec[2])
    control_max = tonumber(control_spec[3])
    local control_default_index = control_spec[4]
    local control_min_length, control_max_length
    control_min_length = #tostring(math.abs(control_min)) 
    control_max_length = polarity ~= -1 and #tostring(math.abs(control_max)) or control_min_length
    local decimal_location = string.find(math.abs(control_min),"%.") or 0
    local decimal_num_places = decimal_location > 0 and control_min_length - decimal_location or 0
    local integer_num_places = decimal_location > 0 and control_max_length - (control_max_length - decimal_location) or control_max_length
    integer_num_places = (control_max <= -1 or control_max >= 1) and integer_num_places or nil
    local value_selector_length = integer_num_places + decimal_num_places
    local value_place_decimals_x1, value_place_decimals_x2
    if decimal_location > 0 then
      value_place_decimals_x1 = decimal_num_places and 14 - decimal_num_places + 1 or nil
      value_place_decimals_x2 = decimal_num_places and 14 or nil
      sequencer_controller.value_place_decimals = grid_sequencer:register_ui_group("value_place_decimals",value_place_decimals_x1,7,value_place_decimals_x2,7,4,3,control_spec, control_default_index)
      sequencer_controller.decimal_button = grid_sequencer:register_ui_group("decimal_button",value_place_decimals_x1-1,7,value_place_decimals_x1-1,7,15,5)
    end
    local polarity_min_max = control_min < 0 and control_max > 0
    if polarity_min_max and sequencer_controller.value_selector_polarity == nil then
      sequencer_controller.value_selector_polarity = grid_sequencer:register_ui_group("value_selector_polarity",4,7,5,7,4,6,control_spec, 5)
    end

    local value_place_integers_x1 = integer_num_places and 14 - integer_num_places - decimal_location + 1 or nil
    local value_place_integers_x2 = integer_num_places and value_place_integers_x1 + integer_num_places - 1
    sequencer_controller.value_place_integers = grid_sequencer:register_ui_group("value_place_integers",value_place_integers_x1,7,value_place_integers_x2,7,4,3,control_spec, control_default_index)
    
    -- if there's just 1 value for the integer place auto-select it
    if(value_place_integers_x1 == value_place_integers_x2) then
      grid_sequencer.activate_grid_key_at(14,7)
    end

    
  elseif control_type == "fraction" then
    sequencer_controller:unregister_ui_group(4,6) 
  elseif control_type == "option" then
    sequencer_controller:unregister_ui_group(4,6) 

    local num_options = #control_spec[2]
    local control_default_index = control_spec[3]
    sequencer_controller.value_selector_options = grid_sequencer:register_ui_group("value_selector_options",6,6,6+num_options-1,6,4,3,control_spec, control_default_index)
    local existing_output_value = sequencer_controller.get_active_output_table_slot().output_value
    if existing_output_value then
      clock.run(sequencer_controller.activate_grid_key_at,5+tonumber(existing_output_value.value),6) 
    end
  end
end

function sequencer_controller.activate_grid_key_at(x,y)
  clock.sleep(0.5)
  grid_sequencer.activate_grid_key_at(x,y)    
  grid_sequencer.activate_grid_key_at(x,y)
end
-----------------------------
--  row 6: cols 6-14
-- ui group 11-13  value number place setters (integers/decimals) - functions
-----------------------------
function sequencer_controller.update_value_place_integers(x, y, state)
  sequencer_controller:unregister_ui_group(6,6)

  local x1 =  sequencer_controller.value_place_integers.grid_data.x1
  local x2 =  sequencer_controller.value_place_integers.grid_data.x2
  local x_offset = x1 - 1
  if state == "on" then
    if sequencer_controller.value_place_decimals then
      local decimal_x1 = sequencer_controller.value_place_decimals.grid_data.x1
      local decimal_x2 = sequencer_controller.value_place_decimals.grid_data.x2
      for i=decimal_x1,decimal_x2,1 do
        grid_sequencer:solid_off(i, 7)  
      end
    end
    local num_integer_places = x2 - x1 + 1
    local is_last_integer_place = x == x1

    local x_location = x2 - x + 1
    sequencer_controller.value_place_integer = x_location
    if x_location == 1 then 
      sequencer_controller.active_value_selector_place = "ones"
    elseif x_location == 2 then 
      sequencer_controller.active_value_selector_place = "tens"
    elseif x_location == 3 then 
      sequencer_controller.active_value_selector_place = "hundreds"
    elseif x_location == 4 then 
      sequencer_controller.active_value_selector_place = "thousands"
    elseif x_location == 5 then 
      sequencer_controller.active_value_selector_place = "ten_thousands"
    end

    local control_spec = sequencer_controller.value_place_integers.control_spec
    local max = control_spec[3]
    local last_place_value = string.sub(tostring(max),1,1)
    local selector_length = (is_last_integer_place and  tonumber(last_place_value) > 0) and 5+tonumber(last_place_value) or 14
    sequencer_controller.value_selector_nums = grid_sequencer:register_ui_group("value_selector_nums",6,6,selector_length,6,4,3)
    local existing_output_value = sequencer_controller.get_active_output_table_slot().output_value
    if existing_output_value then
      local existing_output_value_int = tostring(math.floor(existing_output_value))
      local existing_output_value_int_length = #existing_output_value_int
      local existing_output_value_at_place = string.sub(
                                                          existing_output_value_int,
                                                          existing_output_value_int_length-x_location+1,
                                                          existing_output_value_int_length-x_location+1)

      if existing_output_value_at_place == "" then existing_output_value_at_place = 0 end
      grid_sequencer.activate_grid_key_at(5+tonumber(existing_output_value_at_place),6) 
    end
  else
    -- sequencer_controller:unregister_ui_group(6,6)
    sequencer_controller.value_place_integer = nil
    sequencer_controller.active_output_value_text = nil
  end
end

function sequencer_controller.update_value_place_decimals(x, y, state)
  sequencer_controller:unregister_ui_group(6,6)

  local x1 =  sequencer_controller.value_place_decimals.grid_data.x1
  local x2 =  sequencer_controller.value_place_decimals.grid_data.x2
  local x_offset = x1 - 1
  
  if state == "on" then
    if sequencer_controller.value_place_integers then
      local integer_x1 = sequencer_controller.value_place_integers.grid_data.x1
      local integer_x2 = sequencer_controller.value_place_integers.grid_data.x2
      for i=integer_x1,integer_x2,1 do
          grid_sequencer:solid_off(i, 7)  
      end
    end
    local num_decimal_places = x2 - x1 + 1
    local is_last_decimal_place = x == x2

    local x_location = x - x1 + 1
    sequencer_controller.value_place_decimal = x_location
    if x_location  == 1 then 
      sequencer_controller.active_value_selector_place = "tenths"
    elseif x_location  == 2 then 
      sequencer_controller.active_value_selector_place = "hundredths"
    elseif x_location  == 3 then 
      sequencer_controller.active_value_selector_place = "thousandths"
    end

    local control_spec = sequencer_controller.value_place_decimals.control_spec
    local min = control_spec[2]
    local min_length = #min
    local last_place_value = tonumber(string.sub(min,min_length))
    local selector_length = (is_last_decimal_place and  last_place_value > 0) and 5+last_place_value or 14


    sequencer_controller.value_selector_nums = grid_sequencer:register_ui_group("value_selector_nums",6,6,selector_length,6,4,3)

    local existing_output_value = sequencer_controller.get_active_output_table_slot().output_value
    local decimal_location = existing_output_value and string.find(existing_output_value,"%.") or 0
    
    local decimal_point_at = existing_output_value and string.find(existing_output_value,"%.")
    if existing_output_value and decimal_point_at then
      local existing_output_value_dec = tostring(string.sub(existing_output_value,decimal_point_at+1))
      local existing_output_value_dec_length = #existing_output_value_dec
      local existing_output_value_at_place = string.sub(
                                                          existing_output_value_dec,
                                                          x_location,
                                                          x_location)

      if existing_output_value_at_place == "" then existing_output_value_at_place = 0 end
      grid_sequencer.activate_grid_key_at(5+tonumber(existing_output_value_at_place),6) 
    end
  else
    -- sequencer_controller:unregister_ui_group(6,6)
    sequencer_controller.value_place_decimal = nil
    sequencer_controller.active_output_value_text = nil
  end
end

-----------------------------
--  row 8: col 5
-- ui group 14 sequin value selector  - functions
--  HERE IS WHERE THE SEQUIN GETS SET
-----------------------------
-- function sequencer_controller.unregister_value_selectors(active_selector_type)
function sequencer_controller.unregister_value_selectors()
  sequencer_controller:unregister_ui_group(4,6) 
  if sequencer_controller.value_place_integers then 
    local x1 = sequencer_controller.value_place_integers.grid_data.x1
    local x2 = sequencer_controller.value_place_integers.grid_data.x2
    local y1 = sequencer_controller.value_place_integers.grid_data.y1
    local y2 = sequencer_controller.value_place_integers.grid_data.y2
    sequencer_controller:unregister_ui_group(x1,y1) 
  end
  if sequencer_controller.value_place_decimals then 
    local x1 = sequencer_controller.value_place_decimals.grid_data.x1
    local x2 = sequencer_controller.value_place_decimals.grid_data.x2
    local y1 = sequencer_controller.value_place_decimals.grid_data.y1
    local y2 = sequencer_controller.value_place_decimals.grid_data.y2
    sequencer_controller:unregister_ui_group(x1,y1) 
  end
  if sequencer_controller.decimal_button then 
    local x1 = sequencer_controller.decimal_button.grid_data.x1
    local x2 = sequencer_controller.decimal_button.grid_data.x2
    local y1 = sequencer_controller.decimal_button.grid_data.y1
    local y2 = sequencer_controller.decimal_button.grid_data.y2
    sequencer_controller:unregister_ui_group(x1,y1) 
  end
  sequencer_controller.active_value_selector_place = nil
  sequencer_controller.active_output_value_text = nil
end

function sequencer_controller.update_value_selector_options(x, y, state)
  local x_offset = sequencer_controller.value_selector_options.grid_data.x1 - 1
  if state == "on" then  
    local selector_value = x - x_offset
    sequencer_controller.active_sequin_value.option_value = selector_value
    sequencer_controller.value_option = selector_value
    sequencer_controller.sequin_output_values = grid_sequencer:register_ui_group("sequin_output_values",6,8,6,8,5,3)
  else
    if sequencer_controller.sequin_output_values then sequencer_controller:unregister_ui_group(6,8) end
    sequencer_controller.value_option = nil
    sequencer_controller.active_output_value_text = nil
  end
end

function sequencer_controller.update_value_polarity(x, y, state)
    sequencer_controller.value_polarity = x == 4 and -1 or 1
    -- sequencer_controller.unregister_value_selectors()
    sequencer_controller.set_sequin_output_value_controls()
end

function sequencer_controller.update_number_selector_sequence_mode(x, y, state)
  sequencer_controller.number_sequence_mode = x == 4 and 1 or 2
  -- sequencer_controller.unregister_value_selectors()
  sequencer_controller.set_sequin_output_value_controls()
end



function sequencer_controller.update_value_selector_nums(x, y, state)
  local x_offset = sequencer_controller.value_selector_nums.grid_data.x1 - 1
  if state == "on" then
    local selector_value = x - x_offset
    sequencer_controller.value_number = selector_value
    if sequencer_controller.active_value_selector_place == "ten_thousands" then
      sequencer_controller.active_sequin_value.place_values.ten_thousands =  selector_value
    elseif sequencer_controller.active_value_selector_place == "thousands" then
      sequencer_controller.active_sequin_value.place_values.thousands =  selector_value
    elseif sequencer_controller.active_value_selector_place == "hundreds" then
      sequencer_controller.active_sequin_value.place_values.hundreds =  selector_value
    elseif sequencer_controller.active_value_selector_place == "ones" then
      sequencer_controller.active_sequin_value.place_values.ones =  selector_value
    elseif sequencer_controller.active_value_selector_place == "tens" then
      sequencer_controller.active_sequin_value.place_values.tens =  selector_value
    elseif sequencer_controller.active_value_selector_place == "tenths" then
      sequencer_controller.active_sequin_value.place_values.tenths =  selector_value
    elseif sequencer_controller.active_value_selector_place == "hundredths" then
      sequencer_controller.active_sequin_value.place_values.hundredths =  selector_value
    elseif sequencer_controller.active_value_selector_place == "thousandths" then
      sequencer_controller.active_sequin_value.place_values.thousandths =  selector_value
    end
    
    sequencer_controller.sequin_output_values = grid_sequencer:register_ui_group("sequin_output_values",6,8,6,8,5,3)
  else
    sequencer_controller.value_number = nil
    if sequencer_controller.active_value_selector_place == "ten_thousands" then
      sequencer_controller.active_sequin_value.place_values.ten_thousands =  0
    elseif sequencer_controller.active_value_selector_place == "thousands" then
      sequencer_controller.active_sequin_value.place_values.thousands =  0
    elseif sequencer_controller.active_value_selector_place == "hundreds" then
      sequencer_controller.active_sequin_value.place_values.hundreds =  s0
    elseif sequencer_controller.active_value_selector_place == "ones" then
      sequencer_controller.active_sequin_value.place_values.ones =  0
    elseif sequencer_controller.active_value_selector_place == "tens" then
      sequencer_controller.active_sequin_value.place_values.tens =  0
    elseif sequencer_controller.active_value_selector_place == "tenths" then
      sequencer_controller.active_sequin_value.place_values.tenths =  0
    elseif sequencer_controller.active_value_selector_place == "hundredths" then
      sequencer_controller.active_sequin_value.place_values.hundredths =  0
    elseif sequencer_controller.active_value_selector_place == "thousandths" then
      sequencer_controller.active_sequin_value.place_values.thousandths =  0
    end
    sequencer_controller.sequin_output_values = grid_sequencer:register_ui_group("sequin_output_values",6,8,6,8,5,3)    
  end
end


---------------- THE SEQUIN GETS SET HERE ---------------
function sequencer_controller.reset_place_values(exception)
  -- print("exception, = =tenths", exception, exception == "tenths",sequencer_controller.active_sequin_value.place_values.tenths)
  -- sequencer_controller.active_sequin_value.place_values = {}
  sequencer_controller.active_sequin_value.place_values.ten_thousands   = (exception == "ten_thousands")  and  sequencer_controller.active_sequin_value.place_values.ten_thousands or  0
  sequencer_controller.active_sequin_value.place_values.thousands       = (exception == "thousands")      and  sequencer_controller.active_sequin_value.place_values.thousands     or  0
  sequencer_controller.active_sequin_value.place_values.hundreds        = (exception == "hundreds")       and  sequencer_controller.active_sequin_value.place_values.hundreds      or  0
  sequencer_controller.active_sequin_value.place_values.ones            = (exception == "ones")           and  sequencer_controller.active_sequin_value.place_values.ones          or  0
  sequencer_controller.active_sequin_value.place_values.tens            = (exception == "tens")           and  sequencer_controller.active_sequin_value.place_values.tens          or  0
  sequencer_controller.active_sequin_value.place_values.tenths          = (exception == "tenths")         and  sequencer_controller.active_sequin_value.place_values.tenths        or  0
  sequencer_controller.active_sequin_value.place_values.hundredths      = (exception == "hundredths")     and  sequencer_controller.active_sequin_value.place_values.hundredths    or  0
  sequencer_controller.active_sequin_value.place_values.thousandths     = (exception == "thousandths")    and  sequencer_controller.active_sequin_value.place_values.thousandths   or  0
end

function sequencer_controller.get_previous_active_sequin_value(selected_sequin)
  -- selected_control_indices = sequencer_controller.get_selected_indices()
  local active_output_values = sequencer_controller.get_active_output_values()
  local previous_active_sequin_value = nil
  local previous_active_sequin_value_index
  for i=selected_sequin-1,1,-1 do
    if active_output_values[i][1] ~= "nil" then
      previous_active_sequin_value = active_output_values[i][1]
      previous_active_sequin_value_index = i
      break
    end 
  end
  return previous_active_sequin_value, previous_active_sequin_value_index
end

function sequencer_controller.update_sequin_output_value(x, y, state, press_type)
  local output_value
  local value_selector_default_value
  if press_type == "long" then
    local value_selector_group_id = grid_sequencer:find_ui_group_num_by_xy(6,6)
    value_selector_default_value = grid_sequencer.ui_groups[value_selector_group_id].default_value
    value_selector_default_value = value_selector_default_value and value_selector_default_value or 1

    if sequencer_controller.active_value_selector_place then
      local reset_exception = sequencer_controller.active_value_selector_place
      print("reset_exception",reset_exception)
      sequencer_controller.reset_place_values(reset_exception)
    else
      print("reset_place_values to default",press_type)
      sequencer_controller.reset_place_values()
      -- output_value = value_selector_default_value
    end

  end

  if sequencer_controller.active_sequin_value.value_type == "number" then
    output_value =  sequencer_controller.active_sequin_value.place_values.ten_thousands ..
                    sequencer_controller.active_sequin_value.place_values.thousands ..
                    sequencer_controller.active_sequin_value.place_values.hundreds ..
                    sequencer_controller.active_sequin_value.place_values.tens ..
                    sequencer_controller.active_sequin_value.place_values.ones .. "." ..
                    sequencer_controller.active_sequin_value.place_values.tenths ..
                    sequencer_controller.active_sequin_value.place_values.hundredths ..
                    sequencer_controller.active_sequin_value.place_values.thousandths
   
    local polarity = sequencer_controller.value_polarity and sequencer_controller.value_polarity or 1
    output_value = tonumber(output_value * polarity)

    -- here's where the number gets set according to the number_sequence_mode
    local number_sequence_mode = sequencer_controller.number_sequence_mode and sequencer_controller.number_sequence_mode or 1
    -- sequencer_controller.selected_sequin
    -- local active_output_values = sequencer_controller.get_active_output_values()[1]
    -- clear out the place values if press_type == "long" and value is already 0
    if press_type == "long" and output_value == 0 then 
      output_value = "clear" 
    else 
      local selected_sequin = sequencer_controller.selected_sequin
      -- local previous_active_value = sequencer_controller.get_previous_active_sequin_value(selected_sequin)
      -- print("previous_active_value",previous_active_value)
      local sequence_mode = sequencer_controller.number_sequence_mode 
      -- output_value = previous_active_value and output_value + previous_active_value or output_value
      
      -- sequence mode of 1 == "relative mode" (set output_value value relative to the previous one)
      -- sequence mode of 1 == "absolute mode" (set the value according to the output value)
      output_value = sequence_mode == 1 and output_value .. "r" or output_value
      
    end                    
    
    sequencer_controller.active_output_value_text = output_value
  elseif sequencer_controller.active_sequin_value.value_type == "option" then
    if press_type == "long" then
      print("reset to default value",press_type)
      output_value = value_selector_default_value
    else
      output_value = sequencer_controller.active_sequin_value.option_value
    end
    local value_text = sequencer_controller.get_options_text(output_value)
    sequencer_controller.active_output_value_text = value_text
  end

  -- update the ouptut table
  sequencer_controller.update_outputs_table(output_value)
  
  -- sequencer_controller.update_sequin(x-5)
  sequencer_controller.update_sequin()
end

-- todo: implement subgroups

function sequencer_controller.update_sequin(sequin)
  local selected_indices = sequencer_controller.get_selected_indices()
  local sgp = selected_indices.selected_sequin_groups
  local ssg = selected_indices.selected_sequin_subgroups
  local sqn = sequin and sequin or selected_indices.selected_sequin
  local sequin_to_update = sequencer_controller.sequencers[sgp].sequin_set[sqn]
  sequin_to_update.set_output_table(sequencer_controller.sequins_outputs_table)
end

function sequencer_controller.get_selected_indices()
  local indices = {
    selected_sequin_groups        = sequencer_controller.selected_sequin_groups,         -- selected_sequin_groups:  value table level 1
    selected_sequin_subgroups     = sequencer_controller.selected_sequin_subgroups,      -- selected_sequin_groups:  value table level 2
    selected_sequin               = sequencer_controller.selected_sequin,          -- selected_sequin:  value table level 3
    selected_sequin_output_type   = sequencer_controller.selected_sequin_output_type,    -- output_type_selected:  value table level 4
    selected_sequin_output        = sequencer_controller.selected_sequin_output,         -- output_selected:  value table level 5
    selected_sequin_output_mode   = sequencer_controller.selected_sequin_output_mode,    -- output_mode_selected:  value table level 6
    selected_sequin_output_param  = sequencer_controller.selected_sequin_output_param,   -- output_param_selected:  value table level 7
  }
  return indices
end

function sequencer_controller.get_options_text(option_index)
  -- local sgp = sequencer_controller.selected_sequin_groups
  -- local ssg = sequencer_controller.selected_sequin_subgroups
  -- local sqn = sequencer_controller.selected_sequin
  local typ = sequencer_controller.selected_sequin_output_type
  local out = sequencer_controller.selected_sequin_output
  local mod = sequencer_controller.selected_sequin_output_mode
  local par = sequencer_controller.selected_sequin_output_param
  local opt = sequencer_controller.value_option

  local map = sequencer_controller.get_output_control_specs_map()
  local options_table
  if mod and par then
    options_table = map[typ][out][mod][par][2]
  elseif mod then
    options_table = map[typ][out][mod][2]
  else
    options_table = map[typ][out][par][2]
  end
  if option_index then
    local active_option_text = options_table[option_index]
    print("active_option_text",active_option_text)
    return active_option_text
  else
    options_table = type(options_table) == "table" and options_table or nil 
    return options_table
  end
end

function sequencer_controller.get_active_output_table_slot()
  local sgp     =   sequencer_controller.selected_sequin_groups         -- selected_sequin_groups:  value table level 1
  local ssg  =   sequencer_controller.selected_sequin_subgroups      -- selected_sequin_sub_group:  value table level 2
  local sqn     =   sequencer_controller.selected_sequin          -- selected_sequin:  value table level 3
  local typ    =   sequencer_controller.selected_sequin_output_type    -- output_type_selected:  value table level 4
  local out   =   sequencer_controller.selected_sequin_output         -- output_selected:  value table level 5
  local mod    =   sequencer_controller.selected_sequin_output_mode    -- output_mode_selected:  value table level 6
  local par    =   sequencer_controller.selected_sequin_output_param   -- output_param_selected:  value table level 7
  mod = mod ~= nil and mod or 1 -- if output mode is nil set it to one to indicate there is just 1 output mode

  -- ??????????????????? IS THIS NEEDED  ???????????????????????
  sequencer_controller.update_outputs_table()
  -- ??????????????????? ??????????????????? ???????????????????

  if par == nil then
    return sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod]
  else
    return sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par]
  end
end

function sequencer_controller.update_outputs_table(output_value)
  local sgp     =   sequencer_controller.selected_sequin_groups         -- selected_sequin_groups:  value table level 1
  local ssg  =   sequencer_controller.selected_sequin_subgroups      -- selected_sequin_sub_group:  value table level 2
  local sqn     =   sequencer_controller.selected_sequin          -- selected_sequin:  value table level 3
  local typ    =   sequencer_controller.selected_sequin_output_type    -- output_type_selected:  value table level 4
  local out   =   sequencer_controller.selected_sequin_output         -- output_selected:  value table level 5
  local mod    =   sequencer_controller.selected_sequin_output_mode    -- output_mode_selected:  value table level 6
  local par    =   sequencer_controller.selected_sequin_output_param   -- output_param_selected:  value table level 7
  mod = mod ~= nil and mod or 1 -- if output mode is nil set it to one to indicate there is just 1 output mode
  -- kinda klunky but push the output_value into the sequins_outputs_table
  --local sequencer_controller.sequins_outputs_table = sequencer_controller.sequins_outputs_table
  if sequencer_controller.sequins_outputs_table[sgp] == nil then sequencer_controller.sequins_outputs_table[sgp] = {} sequencer_controller.sequins_outputs_table[sgp].table_type = "sgp" end
  if sequencer_controller.sequins_outputs_table[sgp][ssg] == nil then sequencer_controller.sequins_outputs_table[sgp][ssg] = {} sequencer_controller.sequins_outputs_table[sgp][ssg].table_type = "sgp" end
  if sequencer_controller.sequins_outputs_table[sgp][ssg][sqn] == nil then sequencer_controller.sequins_outputs_table[sgp][ssg][sqn] = {} sequencer_controller.sequins_outputs_table[sgp][ssg][sqn].table_type = "sqn" end
  if sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ] == nil then sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ] = {} sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ].table_type = "typ" end
  if sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out] == nil then sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out] = {} sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out].table_type = "out" end
  if sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod] == nil then sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod] = {} sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].table_type = "mod" end

  if par == nil then
    if sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod] == nil then 
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod] = {} 
    end
    -- print("selected item table structure som",sgp,ssg,sqn,typ,out,som)
    local existing_output_data_at_location = sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data
    if output_value and output_value ~= "clear" then 
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data = {}
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].table_type = "mod" 
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data.value = output_value 
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data.value_heirarchy = {sgp=sgp,ssg=ssg,sqn=sqn,typ=typ,out=out,mod=mod}
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data.control_id = sequencer_controller.active_sequin_control_id
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data.control_name = sequencer_controller.active_sequin_control_name
      sequencer_controller.active_value_heirarchy = {sgp=sgp,ssg=ssg,sqn=sqn,typ=typ,out=out,mod=mod}
    elseif output_value == "clear" then
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod] = {}
    end
  else
    if sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod] == nil then 
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod] = {} 
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].table_type = "mod" 
    end
    if sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par] == nil then 
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par] = {} 
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].table_type = "par" 
    end
    local existing_output_data_at_location = sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data
    if output_value and output_value ~= "clear" then 
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data = {}
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data.value = output_value 
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data.value_heirarchy = {sgp=sgp,ssg=ssg,sqn=sqn,typ=typ,out=out,mod=mod,par=par}
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data.control_id = sequencer_controller.active_sequin_control_id
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data.control_name = sequencer_controller.active_sequin_control_name
      sequencer_controller.active_value_heirarchy = {sgp=sgp,ssg=ssg,sqn=sqn,typ=typ,out=out,mod=mod,par=par}
    elseif output_value == "clear" then
      sequencer_controller.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par] = {}
    end
  end
end

function sequencer_controller.get_acnym_map()
  local acnym_map = {
    sgp = sequencer_controller.selected_sequin_groups,         -- selected_sequin_groups:  value table level 1
    ssg = sequencer_controller.selected_sequin_subgroups,      -- selected_sequin_groups:  value table level 2
    sqn = sequencer_controller.selected_sequin,          -- selected_sequin:  value table level 3
    typ = sequencer_controller.selected_sequin_output_type,    -- output_type_selected:  value table level 4
    out = sequencer_controller.selected_sequin_output,         -- output_selected:  value table level 5
    mod = sequencer_controller.selected_sequin_output_mode,    -- output_mode_selected:  value table level 6
    par = sequencer_controller.selected_sequin_output_param,   -- output_param_selected:  value table level 7
    int = sequencer_controller.value_place_integer,
    dec = sequencer_controller.value_place_decimal,
    sqm = sequencer_controller.number_sequence_mode,
    pol = sequencer_controller.value_polarity,
    num = sequencer_controller.value_number,
    opt = sequencer_controller.value_option,
  }
  if acnym_map.mod == nil and acnym_map.par then acnym_map.mod = 1 end
  return acnym_map
end

function sequencer_controller.update_active_value_heirarchy()
  local a_map = sequencer_controller.get_acnym_map()
  -- if sequencer_controller.sequins_outputs_table[a_map.sgp] and sequencer_controller.sequins_outputs_table[a_map.sgp][a_map.ssg] then 
    -- local sgp = a_map.sgp
    -- local ssg = a_map.ssg
    -- local sqn = sequencer_controller.sequins_outputs_table[a_map.sgp][a_map.ssg][a_map.sqn]
    -- local type = sqn and sequencer_controller.sequins_outputs_table[a_map.sgp][a_map.ssg][a_map.sqn][a_map.typ]
    -- local out = (sqn and type) and sequencer_controller.sequins_outputs_table[a_map.sgp][a_map.ssg][a_map.sqn][a_map.typ][a_map.out]
    -- local mod = (sqn and type and out) and sequencer_controller.sequins_outputs_table[a_map.sgp][a_map.ssg][a_map.sqn][a_map.typ][a_map.out][a_map.mod]
    -- local par = (sqn and type and out and mod) and sequencer_controller.sequins_outputs_table[a_map.sgp][a_map.ssg][a_map.sqn][a_map.typ][a_map.out][a_map.mod][a_map.par]
    -- print(a_map, sqn, type, out, mod, par, output_data)
    -- return output_data
    local output_data
    if a_map.par then 
      output_data = (a_map.sqn and a_map.type and a_map.out and a_map.mod and a_map.par) and sequencer_controller.sequins_outputs_table[a_map.sgp][a_map.ssg][a_map.sqn][a_map.typ][a_map.out][a_map.mod][a_map.par].output_data
      -- print ("found par",output_data )
      sequencer_controller.active_value_heirarchy = {sgp=a_map.sgp,ssg=a_map.ssg,sqn=a_map.sqn,typ=a_map.typ,out=a_map.out,mod=a_map.mod,par=a_map.par}
    elseif a_map.mod then
      output_data = (sqn and type and out and mod and par) and sequencer_controller.sequins_outputs_table[a_map.sgp][a_map.ssg][a_map.sqn][a_map.typ][a_map.out][a_map.mod].output_data
      -- print ("found mod, no par",output_data)
      sequencer_controller.active_value_heirarchy = {sgp=a_map.sgp,ssg=a_map.ssg,sqn=a_map.sqn,typ=a_map.typ,out=a_map.out,mod=a_map.mod}
    end
    if output_data then
      -- print("found output data") 
      -- return output_data
      
    else
      -- print("no output data") 
    end
  -- else
    -- print("no heirarchy")
  -- end
end

function sequencer_controller.get_active_output_values()
  sequencer_controller.update_active_value_heirarchy()
  local vh = sequencer_controller.active_value_heirarchy
  if vh then
    -- print(vh,vh.sgp,vh.ssg, vh.mod, vh.par)
  end
  local outputs_table = {}
  if vh and vh.par then
    for i=1,params:get("num_sequin"),1 do
      local sqn_index = i
      local sgp = sequencer_controller.sequins_outputs_table[vh.sgp]
      local ssg = sgp and sequencer_controller.sequins_outputs_table[vh.sgp][vh.ssg]
      local sqn = (sgp and ssg) and sequencer_controller.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index]
      local type = (sgp and ssg and sqn) and sequencer_controller.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ]
      local out = (sgp and ssg and sqn and type) and sequencer_controller.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ][vh.out]
      local mod = (sgp and ssg and sqn and type and out) and sequencer_controller.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ][vh.out][vh.mod]
      local par = (sgp and ssg and sqn and type and out and mod) and sequencer_controller.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ][vh.out][vh.mod][vh.par]
      local output_data = (sgp and ssg and sqn and type and out and mod and par) and sequencer_controller.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ][vh.out][vh.mod][vh.par].output_data
      local output_value = (sqn and output_data) and output_data.value or nil
      output_value = output_value == nil and "nil" or output_value
      local calculated_absolute_value = (sqn and output_data and output_data.calculated_absolute_value) and output_data.calculated_absolute_value or nil
      calculated_absolute_value = calculated_absolute_value == nil and "nil" or calculated_absolute_value
      -- table.insert(outputs_table,output_value)
      -- print(output_value,calculated_absolute_value)
      table.insert(outputs_table,{output_value,calculated_absolute_value})
      -- print("par i",i, #outputs_table)
    end
  elseif vh and vh.mod then
    for i=1,params:get("num_sequin"),1 do
      local sqn_index = i
      local sgp = sequencer_controller.sequins_outputs_table[vh.sgp]
      local ssg = sgp and sequencer_controller.sequins_outputs_table[vh.sgp][vh.ssg]
      local sqn = (sgp and ssg) and sequencer_controller.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index]
      local type = (sgp and ssg and sqn) and sequencer_controller.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ]
      local out = (sgp and ssg and sqn and type) and sequencer_controller.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ][vh.out]
      local mod = (sgp and ssg and sqn and type and out) and sequencer_controller.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ][vh.out][vh.mod]
      local output_data = (sgp and ssg and sqn and type and out and mod) and sequencer_controller.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ][vh.out][vh.mod].output_data
      local output_value = (sqn and output_data) and output_data.value or nil
      output_value = output_value == nil and "nil" or output_value
      local calculated_absolute_value = (sqn and output_data and output_data.calculated_absolute_value) and output_data.calculated_absolute_value or nil
      calculated_absolute_value = calculated_absolute_value == nil and "nil" or calculated_absolute_value
      -- table.insert(outputs_table,output_value)
      -- print(output_value,calculated_absolute_value)
      table.insert(outputs_table,{output_value,calculated_absolute_value})
      -- print("mod i",i, #outputs_table)
    end
  end
  if outputs_table then 
    -- print(outputs_table)
    -- tab.print(outputs_table[1],outputs_table[2])
    -- tab.print(outputs_table[1])
    -- tab.print(outputs_table[2])
  end
  return outputs_table
end

----------------------------------
-- 
----------------------------------
function sequencer_controller:get_active_ui_group()
  local num_ui_groups = grid_sequencer.get_num_ui_groups()
  local group_name = grid_sequencer.ui_groups[num_ui_groups].group_name
  -- group_name = string.sub(group_name,1,13) == "sequin_groups" and "sequin_groups" or group_name
  group_name = group_name:gsub("_"," ")
  return group_name
end

function sequencer_controller.set_active_sequin_value_type(value_type)
  if value_type == "number" and sequencer_controller.active_sequin_value.place_values == nil then
    sequencer_controller.reset_place_values()
  elseif value_type == "option" and sequencer_controller.active_sequin_value == nil then
    -- do something here?
    sequencer_controller.active_sequin_value.place_values = nil
  end
  sequencer_controller.active_sequin_value.value_type = value_type
end

function sequencer_controller:update_group(group_name,x, y, state, press_type)
  -- local sequin_groups_start, sequin_groups_finish = string.find(group_name,"sequin_groups")
  -- sequencer_screen.update_screen_instructions(group_name, state)
  sequencer_controller.active_output_value_text = nil
  if string.sub(group_name,1,13) == "sequin_groups" then 
    self.set_selected_sequin_groups(x,state)
  elseif group_name == "sequin_selector" then
    self.update_sequin_selector(x, y, state)
  elseif group_name == "sequin_output_types" then
    self.update_sequin_output_types(x, y, state)
  elseif group_name == "sequin_outputs" then
    self.update_sequin_outputs(x, y, state)
  elseif group_name == "sequin_output_modes" then
    self.update_sequin_output_modes(x, y, state)
  elseif group_name == "sequin_output_params" then
    self.update_sequin_output_params(x, y, state)
  elseif group_name == "sequins_mods" then
    self.update_sequins_mods(x, y, state)
  elseif group_name == "value_selector_options" then
    self.set_active_sequin_value_type("option")
    self.update_value_selector_options(x, y, state)
  elseif group_name == "value_place_integers" then
    self.set_active_sequin_value_type("number")
    self.update_value_place_integers(x, y, state)
  elseif group_name == "value_place_decimals" then
    self.set_active_sequin_value_type("number")
    self.update_value_place_decimals(x, y, state)
  elseif group_name == "number_selector_sequence_mode" then
    self.update_number_selector_sequence_mode(x, y, state)
  elseif group_name == "value_selector_polarity" then
    self.update_value_polarity(x, y, state)
  elseif group_name == "value_selector_nums" then
    self.update_value_selector_nums(x, y, state)
  elseif group_name == "sequin_output_values" then
    self.update_sequin_output_value(x, y, state, press_type)
  end
end


return sequencer_controller