-- TODO: add a parameter to the number 'controlspec' to indicate the number of decimal places
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
sc = sequencer_controller



function sc.init()

  -- placeholder until views are implemented for the sequencer controller
  sc.from_view = 1

  -- UI data
  sc.selected_sequin_group = nil
  sc.selected_sequin_subgroup = nil 
  sc.selected_sequin = nil
  sc.selected_sequin_output_type = nil
  sc.selected_sequin_output = nil
  sc.selected_sequin_output_mode = nil
  sc.selected_sequin_output_param = nil
  sc.value_place_integer = nil
  sc.value_place_decimal = nil
  sc.sequence_mode = nil
  sc.value_number = nil
  sc.value_option = nil
  sc.value_note_num = nil
  sc.value_octave = nil

  sc.selectors_x_offset = 5
  sc.value_polarity = 1
  -- value data 
  sc.sequins_outputs_table = {}

  sc.grid_input_processors = {}

  sc.active_sequin_value = {}
  sc.active_sequin_value.place_values = {}
  sc.active_sequin_value.place_values.ten_thousands  =  0
  sc.active_sequin_value.place_values.thousands      =  0
  sc.active_sequin_value.place_values.hundreds       =  0
  sc.active_sequin_value.place_values.tens           =  0
  sc.active_sequin_value.place_values.ones           =  0
  sc.active_sequin_value.place_values.tenths         =  0
  sc.active_sequin_value.place_values.hundredths     =  0
  sc.active_sequin_value.place_values.thousandths    =  0

  sc.lattice = Lattice:new{
    auto = true,
    meter = 1/4,
    ppqn = 96
  }

  sequin_processor.init()
  devices_crow_processor.init()
  devices_jf_processor.init()

  sc.refresh_output_control_specs_map()
  sc.sequencers = {}
  sc.sequencers[1] = Sequencer:new(sc.lattice,1)
  sc.sequencers[2] = Sequencer:new(sc.lattice,2)
  sc.sequencers[3] = Sequencer:new(sc.lattice,3)
  sc.sequencers[4] = Sequencer:new(sc.lattice,4)
  sc.sequencers[5] = Sequencer:new(sc.lattice,5)
  sc.lattice:hard_restart()
  -- sc.lattice:start()

end

function sc.copy_paste_sequinsets(target_sequinset,source_sequinset)
  sc.sequins_outputs_table[target_sequinset] = {}
  sc.sequins_outputs_table[target_sequinset] = fn.deep_copy(sc.sequins_outputs_table[source_sequinset])
  clock.run(sc.activate_sequinset,target_sequinset)
  -- sc.reset_sequinset_value_heirarcy(target_sequinset)
  -- clock.run(grid_sequencer.activate_grid_key_at,target_sequinset,1,0.1)
  
end

function sc.activate_sequinset(target_sequinset)
  -- clock.run(grid_sequencer.activate_grid_key_at,target_sequinset,1,0.01)
  clock.sleep(0.1)
  print("act",target_sequinset)
  sc.reset_sequinset_value_heirarcy(target_sequinset)
end

function sc.reset_sequinset_value_heirarcy(sgp,inner_table)
  local tab = inner_table and inner_table or sc.sequins_outputs_table[sgp]
  -- local table_type
  -- tab == tab or 
  if tab then
    for k, v in pairs(tab) do 
      if type(v) == "table" and k ~="seq" then
        sc.reset_sequinset_value_heirarcy(sgp,v)
      end
      if k == "value_heirarchy" then
        v.sgp = sgp
      end
    end
  end
  local selected_sequin = sc.selected_sequin
  for i=1,params:get("num_sequin"),1 do
    sc.set_selected_sequin(i)
    sc.update_sequin(i)
  end
  sc.set_selected_sequin(selected_sequin)

end

-----------------------

function sc.clear_sequence_data(source_id, data_path, end_node)
  local source_table
  if #data_path == 2 then
    local source_table = sc.sequins_outputs_table[data_path[1]][data_path[2]][source_id]
    sc.sequins_outputs_table[data_path[1]][data_path[2]][source_id] = {}
    source_table = sc.sequins_outputs_table[data_path[1]][data_path[2]][source_id]
  end
  sc.update_value_heirarcy(end_node, source_id, source_table)
  sc.update_sequin()
end

function sc.copy_paste_sequence_data(source_id, target_id, data_path, end_node)
  local target_table
  if #data_path == 2 then
    local source_table = sc.sequins_outputs_table[data_path[1]][data_path[2]][source_id]
    sc.sequins_outputs_table[data_path[1]][data_path[2]][target_id] = {}
    sc.sequins_outputs_table[data_path[1]][data_path[2]][target_id] = fn.deep_copy(source_table)
    target_table = sc.sequins_outputs_table[data_path[1]][data_path[2]][target_id]
  end
  sc.update_value_heirarcy(end_node, target_id, target_table)
  clock.run(sc.activate_target,target_id)
end

function sc.activate_target(target_id)
  clock.sleep(0.1)
  sc.update_sequin(target_id)
  clock.run(grid_sequencer.activate_grid_key_at,target_id+5,1,0.1)
end

function sc.update_value_heirarcy(end_node,end_node_value, output_data_table)
  -- local tab = inner_table and inner_table or sc.sequins_outputs_table[sgp][ssg][target_id]
  -- local table_type
  if output_data_table then 
    for k, v in pairs(output_data_table) do 
      if type(v) == "table" and k ~= "seq" then
        sc.update_value_heirarcy(end_node,end_node_value,v)
      end
      if k == "value_heirarchy" then
        v[end_node] = end_node_value
      end
    end
  end
end

-----------------------
function sc.reset_active_sequin_value()
  sc.active_sequin_value = {}
  -- if sc.sequin_output_types then sc:unregister_ui_group(6,2) end
end



-- set in update_value_place_integers and update_value_place_decimals
sc.active_value_selector_place = nil 


-- utilities
function sc.print_svt()
  for k, v in pairs(sc.active_sequin_value) do print(k,v) end
end

function sc.print_outputs_table(inner_table)
  -- debug = 1
  local tab_to_print = inner_table and inner_table or sc.sequins_outputs_table
  -- local table_type
  for k, v in pairs(tab_to_print) do 
    if type(v) == "table" then
      sc.print_outputs_table(v)
    end
    if k == "value_heirarchy" then
      -- tab.print(v)
      --print(">>>>>")
    end
    if k == "output_data" then
      -- do something???
      -- tab.print(v)
      
    end
  end
  -- debug = 0
end

-- maps
-- output map: the values represent the number of different outputs for each output type
sc.outputs_map = {
  6, -- softcut voices NOTE: the sequencer will only allow 6 voices to play at once
  4, -- devices (midi, crow, just friends, w/)
  6, -- effects (amp, drywet, delay, bitcrush, enveloper, pitchshift
  2, -- lattice and patterns
  2, -- sequins
}

-- note: '(nil)' means the output mode takes just 1 param) 
sc.output_mode_map = {
  {nil,nil,nil,nil,nil,nil},    -- softcut 
  {7,2,7,5},                    -- devices midi out (7), crow(2), just_friends(7),w/(5)
  {nil,nil,4,3,3,7},            -- effects: amp(nil), drywet(nil), delay(4),bitcrush(3),enveloper(3),pitchshift(7)
  {nil,nil},         -- lattice and patterns: set_meter (nil), auto_pulses (nil), ppqn (nil))
  {nil,6},                        -- sequins:
                                --  main sequins: every(1-9), times(1-9), count(1-9), all(), reset(), swap with (1-9), copy from (1-9), 
                                --  sub-sequins: : every(1-9), times(1-9), count(1-9), all(), reset(), swap with (1-9), copy from (1-9), 
}

-- note: '(nil)' means just 1 output param' 
sc.output_params_map = {
  {
    -- 4 softcut output params: 
    --    sample_cut_num: 1-10 ????
    --    rate: -20 - 20 ??????
    --    rate_direction: -1, 1
    --    level: 0-1
    5,5,5,5,5,5
  }, 
  {{6,6,6,3,3,3,nil},{nil,nil},{2,2,2,2,2,2,2},{9,9,9,4,9}}, -- device (midi out (4), crow(2), just_friends(2),w/(2))
  {nil,nil,{nil,nil,nil,nil},{nil,nil,nil},{nil,nil,nil},{nil,nil,nil,nil,nil,nil,nil}}, -- effect (amp(nil), drywet(nil), pitchshift(nil), pitchshift offset(nil), pitchshift array (5)), phaser(nil), delay(nil), enveloper (3)
  {nil,{nil,nil,nil,nil,nil,nil}}, -- sequins 
  {nil,nil}, -- pattern
  {nil,nil,nil,nil,nil,nil},  -- lattice 
}

function sc.get_num_cutters()
  return #cutters > 0 and #cutters or 1
end

function sc.get_output_control_specs_map()
  local map = sc.output_control_specs_map and sc.output_control_specs_map or nil
  return map
end

function sc.refresh_output_control_specs_map()
  local num_cutters = sc.get_num_cutters()
  local cutters = {}
  local min_note = initializing == false and params:get("note_center_frequency") * -1 or note_center_frequency_default
  local max_note = scale_length - min_note
  for i=1,num_cutters,1 do table.insert(cutters,i) end
  sc.output_control_specs_map = {
    {
      -- 4 softcut output params: 
      --    sample_cut_num: 1-10 ????
      --    rate: -20 - 20 ??????
      --    rate_direction: -1, 1
      --    level: 0-1
      {
        {"option",{"stp","la", "ac", "sc","1sh"},nil,nil,"v_mode","v_mode"},      -- play mode
        {"option",cutters,nil,"cutter","cutter"},  -- cutter
        {"number","0.00",20,1,"rate","rate"},    -- rate
        {"option",{-1,1},2,nil,"direction","direction"},      -- direction
        {"number",'0.00',10,0.20,"level","level"}         -- level (amp)
      },  
      {{"option",{"stp","lp", "ac", "sc","1sh"},nil,nil,"v_mode","v_mode"},{"option",cutters,nil,"cutter","cutter"},{"number","0.00",20.00,1,"rate","rate"},{"option",{-1,1},2,nil,"direction","direction"},{"number",'0.00',10,"level","level"}},  
      {{"option",{"stp","lp", "ac", "sc","1sh"},nil,nil,"v_mode","v_mode"},{"option",cutters,nil,"cutter","cutter"},{"number","0.00",20.00,1,"rate","rate"},{"option",{-1,1},2,nil,"direction","direction"},{"number",'0.00',10,"level","level"}},  
      {{"option",{"stp","lp", "ac", "sc","1sh"},nil,nil,"v_mode","v_mode"},{"option",cutters,nil,"cutter","cutter"},{"number","0.00",20.00,1,"rate","rate"},{"option",{-1,1},2,nil,"direction","direction"},{"number",'0.00',10,"level","level"}},  
      {{"option",{"stp","lp", "ac", "sc","1sh"},nil,nil,"v_mode","v_mode"},{"option",cutters,nil,"cutter","cutter"},{"number","0.00",20.00,1,"rate","rate"},{"option",{-1,1},2,nil,"direction","direction"},{"number",'0.00',10,"level","level"}},  
      {{"option",{"stp","lp", "ac", "sc","1sh"},nil,nil,"v_mode","v_mode"},{"option",cutters,nil,"cutter","cutter"},{"number","0.00",20.00,1,"rate","rate"},{"option",{-1,1},2,nil,"direction","direction"},{"number",'0.00',10,"level","level"}},  
    }, 
    { -- device (midi(4), crow(2), just_friends(3),w/(2))
      { -- midi note out 1-3 and stop/start
        { 
          {"note",min_note,max_note,nil,"pitch","pitch"},     -- note
          {"number","0",16,0,"rp","repeats"},                   -- note_repeats
          {"option",NOTE_REPEAT_FREQUENCIES,nil,nil,"rep_frq","repeat frequency"}, -- note repeat frequency
          {"option",MIDI_DURATIONS,3,nil,"dur","dur"},        -- midi stop/start
          {"number","0",127,80,"vel","vel"},                   -- velocity
          {"number","1",16,1,"chan","chan"},                   -- channel
        }, 
         
          
        {{"note",min_note,max_note,nil,"pitch","pitch"},{"number","0",16,0,"rp","repeats"},{"option",NOTE_REPEAT_FREQUENCIES,nil,nil,"rp_frq","repeat frequency"},{"option",{"1","1/2","1/4","1/8","1/16"},3,nil,"dur","dur"},{"number","0",127,80,"vel","vel"},{"number","1",16,1,"chan","chan"}}, 
        {{"note",min_note,max_note,nil,"pitch","pitch"},{"number","0",16,0,"rp","repeats"},{"option",NOTE_REPEAT_FREQUENCIES,nil,nil,"rp_frq","repeat frequency"},{"option",{"1","1/2","1/4","1/8","1/16"},3,nil,"dur","dur"},{"number","0",127,80,"vel","vel"},{"number","1",16,1,"chan","chan"}}, 
        { 
          {"number","0",127,1,"cc","cc cc"},                   -- cc cc
          {"number","0",127,1,"val","cc val"},                   -- cc value
          {"number","1",16,1,"chan","chan"},                   -- cc channel
        }, 
        {{"number","0",127,1,"cc","cc"},{"number","0",127,1,"val","val"},{"number","1",16,1,"chan","chan"}}, 
        {{"number","0",127,1,"cc","cc"},{"number","0",127,1,"val","val"},{"number","1",16,1,"chan","chan"}}, 
        {"option",{"stop","start"},2,nil,"stp_strt","stp/strt"},        -- midi stop/start
      }, 
      { -- crow
        {"note",min_note,max_note,nil,"c1_pitch","c1 pitch"}, -- crow1 pitch
        {"note",min_note,max_note,nil,"c3_pitch","c3 pitch"}, -- crow3 pitch
        -- {"note",min_note,max_note,nil,"drum","drum"} -- drums ??????????????
      }, 
      { -- just friends
        {{"note",min_note,max_note,nil,"pitch","pitch"},{"number",'0.00',10,nil,"level","level"}}, -- play_note: pitch, level
        {{"note",min_note,max_note,nil,"pitch","pitch"},{"number",'0.00',10,nil,"level","level"}}, -- play_voice channel 1: pitch, level
        {{"note",min_note,max_note,nil,"pitch","pitch"},{"number",'0.00',10,nil,"level","level"}}, -- play_voice channel 2: pitch, level
        {{"note",min_note,max_note,nil,"pitch","pitch"},{"number",'0.00',10,nil,"level","level"}}, -- play_voice channel 3: pitch, level
        {{"note",min_note,max_note,nil,"pitch","pitch"},{"number",'0.00',10,nil,"level","level"}}, -- play_voice channel 4: pitch, level
        {{"note",min_note,max_note,nil,"pitch","pitch"},{"number",'0.00',10,nil,"level","level"}}, -- play_voice channel 5: pitch, level
        {{"note",min_note,max_note,nil,"pitch","pitch"},{"number",'0.00',10,nil,"level","level"}}, -- play_voice channel 6: pitch, level
        -- {{"number",1,6,nil,"channel"},{"note",min_note,max_note,nil,"pitch","pitch"},{"number",'0.00',10,nil,"level","level"}}, -- play_voice: channel, pitch, level
        -- {"note",-24,3,nil,6,"pitch_portamento","pitch portamento"}, -- play_note: pitch (portamento)
      }, 
      {  -- w/
        {   -- w_syn voice 1                                                          
          {"note",min_note,max_note,nil,"pitch","pitch"},          -- w_syn: pitch
          {"number",'0.00',5,nil,"vel","vel"},              -- w_syn: velocity
          {"number",'-5.00',5,nil,"crv","crv"},              -- w_syn: ar_curve
          {"number",'-5.00',5,nil,"rmp","rmp"},              -- w_syn: ar_ramp
          {"number",'-5.00',5.00,nil,"fm_ix","fm_ix"},                -- w_syn: fm index
          {"number",'-5.00',5.00,nil,"fm_env","fm_env"},                 -- w_syn: fm envelope
          {"option",{"1","1/2","1/4","3/4","1/3","2/3","1/5","2/5","3/5",},1,nil,"fm_rat","fm_rat"}, -- w_syn: fm ratio
          {"number",'-5.00',5,nil,"lpg_tme","lpg_tme"},               -- w_syn: lpg time
          {"number",'-5.00',5.0,nil,"lpg_sym","lpg_sym"},         -- w_syn: lpg symmetry
        },          
        {   -- w_syn voice 2                                                          
          {"note",min_note,max_note,nil,"pitch","pitch"},          -- w_syn: pitch
          {"number",'0.00',5,nil,"vel","vel"},              -- w_syn: velocity
          {"number",'-5.00',5,nil,"crv","crv"},              -- w_syn: ar_curve
          {"number",'-5.00',5,nil,"rmp","rmp"},              -- w_syn: ar_ramp
          {"number",'-5.00',5,nil,"fm_ix","fm_ix"},                -- w_syn: fm index
          {"number",'-5.00',5,nil,"fm_env","fm_env"},                 -- w_syn: fm envelope
          {"option",{"1","1/2","1/4","3/4","1/3","2/3","1/5","2/5","3/5",},1,nil,"fm_rat","fm_rat"}, -- w_syn: fm ratio
          {"number",'-5.00',5,nil,"lpg_tme","lpg_tme"},               -- w_syn: lpg time
          {"number",'-5.00',5.0,nil,"lpg_sym","lpg_sym"},         -- w_syn: lpg symmetry
        },          
        {   -- w_syn voice 3                                                          
          {"note",min_note,max_note,nil,"pitch","pitch"},          -- w_syn: pitch
          {"number",'0.00',5,nil,"vel","vel"},              -- w_syn: velocity
          {"number",'-5.00',5,nil,"crv","crv"},              -- w_syn: ar_curve
          {"number",'-5.00',5,nil,"rmp","rmp"},              -- w_syn: ar_ramp
          {"number",'-5.00',5,nil,"fm_ix","fm_ix"},                -- w_syn: fm index
          {"number",'-5.00',5,nil,"fm_env","fm_env"},                 -- w_syn: fm envelope
          {"option",{"1","1/2","1/4","3/4","1/3","2/3","1/5","2/5","3/5",},1,nil,"fm_rat","fm_rat"}, -- w_syn: fm ratio
          {"number",'-5.00',5,nil,"lpg_tme","lpg_tme"},               -- w_syn: lpg time
          {"number",'-5.00',5.0,nil,"lpg_sym","lpg_sym"},         -- w_syn: lpg symmetry
        },          
        {   -- w_del karplus                                                          
          {"note",min_note,max_note,nil,"pitch","pitch"},    -- w_del_ks: pitch
          {"number","0",100,nil,"mix","mix"},              -- w_del_ks: mix
          {"number",'0',100,99,"fbk","fbk"},              -- w_del_ks: feedback
          {"number",'1',16,12,"flt","flt"},           -- w_del_ks: filter
          -- {"number",'0.000',5.00,nil,"rte","rate"},     -- w_del_ks: fm index
          -- {"note",min_note,max_note,nil,"frq","frq"},      -- w_del_ks: pitch
          -- {"number",'0.00',5,nil,"mod_rte","mod_rte"},     -- w_del_ks: lpg time
          -- {"number",'0.00',5.0,nil,"mod_amt","mod_amt"},   -- w_del_ks: lpg symmetry
          -- {"option",{0,1},1,nil,"frz","frz"},           -- w_del_ks: lpg freeze
        },          
        {   -- w_del delay                                                          
          {"number","0",100,nil,"mix","mix"},                  -- w_del: mix
          {"number",'0.000',10,nil,"tme","tme"},               -- w_del: delay time
          {"number",'0',100,nil,"fbk","fbk"},               -- w_del: feedback
          {"number",'1',16,12,"flt","flt"},                -- w_del: filter
          {"number",'0.000',5.00,nil,"rte","rate"},               -- w_del: fm index
          {"note",min_note,max_note,nil,"frq","frq"},         -- w_syn: pitch
          {"number",'0.00',5,nil,"mod_rte","mod_rte"},        -- w_del: lpg time
          {"number",'0.00',5.0,nil,"mod_amt","mod_amt"},      -- w_del: lpg symmetry
          {"option",{0,1},1,nil,"frz","frz"},                 -- w_del: lpg freeze
        },          
      }, 
    },
    {   -- effects
      {"number",'0.00',1,nil,{"amp","amp"}},                        -- level (amp)
      {"number",'0.00',1,nil,"drywet","drywet"},                        -- drywet
      { -- delay
        {"number",'0.00',1,1,"amt","delay"}, 
        {"number",'0.00',5,0.25,"del_time","delay time"},                         
        {"number",'0.00',5,4,"del_dcy","delay decay"},                         
        {"number",'0.00',5,1,"del_amp","delay amp"},    
      },                     
      { -- bitcrush
        {"number",'0.00',1,nil,"amt","bitcrush"}, 
        {"number",'1',16,nil,"bits","bitcrush bits"},                         
        {"number",'100',48000,nil,"rate","bitcrush rate"},    
      },                     
      {   -- enveloper 
        {"option",{"off","on"},1,nil,"off_on","enveloper off/on"},        -- off/on
        {"number", "1", 20,5,"rate","trig rate"},                             -- trig_rate 0.01 - 50.00
        {"number",'0.01',0.99,0.99,"ovrlap","overlap"}                                   -- overlap 0-1
      },
      {   -- pitchshift                                                        -- pitchshift array
        {"number",'0.00',1,nil,"amt","pitchshift"},                -- pitchshift
        {"number",'1',50,1,"rate","ps_freq"},                -- pitchshift
        {"note",min_note,max_note,nil,"ps_1","ps note 1"},
        {"note",min_note,max_note,nil,"ps_2","ps note 2"},
        {"note",min_note,max_note,nil,"ps_3","ps note 3"},
        {"note",min_note,max_note,nil,"ps_4","ps note 4"},
        {"note",min_note,max_note,nil,"ps_5","ps note 5"},
      },
    }, 
    {   -- lattice and patterns
      {   -- lattice 
        -- {"option",{"stp","strt","tgl",nil,nil,"stop_start_toggle","stop/start/toggle"}},         -- stop/start/toggle pattern
        -- {"option",{"off","on"},nil,1,"auto_off_on","autopulse off/on"},        -- auto pulse(s) off/on
        -- {"option",{"off","on"},nil,nil,"man_off_on","manual pulse off/on"},          -- manual pulse off/on (NOTE: setting is ignored if auto_pulse is enabled)
        {"number",1,18,nil,"meter","meter"},                  -- meter: quarter notes per measure
        {"option",{12,24,36,48,60,72,84,96,108},8,nil,"ppqn","ppqn"},          -- ppqn (default 96)
        {"option",{"reset","hard reset"},nil,nil,"reset","reset"}                  
        -- {"option",{"off","reset","hard reset"},nil,nil,"off/reset/hard reset","off/reset/hard reset"}                  
      },
      {   -- pattern (TODO: replace with more flexible pattern division selector)
        {"option",{1,1/2,1/4,1/8,1/16,1/3,2/3,3/8,5/8},nil,nil,"pattern_division","pattern division"},                   -- pattern division 1-18/1-18
        {"option",{"stop","start","toggle"},nil,"pat_state","pattern state"} -- stop/start/toggle pattern 
      }, 
    },  
    {   -- sequins: step, every, times, count, all, reset
      {"number", "1", 9,1,"step","step"},
      { -- sub sequins      
        {{"number", "1", 5,1,"step","step"},{"number", "1", 5,1,"every","every"},{"number", "1", 20,1,"times","times"},{"number", "1", 20,1,"count","count"},{"number", "1", 20,1,"all","all"},{"number", "1", 20,1,"reset","reset"}},
        {{"number", "1", 5,1,"step","step"},{"number", "1", 5,1,"every","every"},{"number", "1", 20,1,"times","times"},{"number", "1", 20,1,"count","count"},{"number", "1", 20,1,"all","all"},{"number", "1", 20,1,"reset","reset"}},
        {{"number", "1", 5,1,"step","step"},{"number", "1", 5,1,"every","every"},{"number", "1", 20,1,"times","times"},{"number", "1", 20,1,"count","count"},{"number", "1", 20,1,"all","all"},{"number", "1", 20,1,"reset","reset"}},
      },
    },
  }
end

function sc:unregister_ui_group(x1,y1)
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
      sc[group_name] = nil
    end
  end
  local selected_outputs = {
    sc.selected_sequin_output,
    sc.selected_sequin_output_mode,
    sc.selected_sequin_output_param,
    sc.active_sequin_value
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
function sc.get_active_sequinset_id()
  return sc.selected_sequin_group
end

function sc.update_selected_sequin_group(index,state, seq_ix)
  sc.active_value_heirarchy = nil
  if state == "on" then
    for i=1,5,1 do
      for j=1,1,1 do
        if i ~= index then
          grid_sequencer:solid_off(i, j, sc.from_view)  
        end
      end
    end
    sc.selected_sequin_group = index or nil
    sc.selected_sequin_subgroup = 1
    sc.set_ui_sequin_selector()
    if seq_ix then
      local seq = sc.sequencers[sc.selected_sequin_group].seq
      -- local next_seq_ix = seq.ix < #seq.data and seq.ix+1 or 1
      -- seq:select(next_seq_ix)
      seq:select(seq_ix)
    end
    if sc.lattice.enabled == false then 
      sc.lattice:start()
    end
  else
    if sc.lattice.enabled == true then 
      sc.lattice:stop()
    end
    sc.selected_sequin_group = nil
    -- sc:unregister_ui_group(6,1)
    -- sc.selected_sequin_group = nil
    -- sc.selected_sequin_subgroup = nil
    -- sc.selected_sequin = nil
    -- sc.selected_sequin_output_type = nil
    -- sc.selected_sequin_output = nil
    -- sc.selected_sequin_output_mode = nil
    -- sc.selected_sequin_output_param = nil
    -- sc.value_place_integer = nil
    -- sc.value_place_decimal = nil
    -- sc.value_polarity = nil
    -- sc.sequence_mode = nil      
    -- sc.value_number = nil
    -- sc.value_option = nil
    -- sc.active_output_value_text = nil
  end
end

-----------------------------
--  row 1: cols 6-14
--  ui group 6 sequin selector - functions
-----------------------------
-- UI functions
function sc.set_selected_sequin(index)
  sc.selected_sequin = index
end


function sc.set_ui_sequin_selector()
  if sc.sequin_selector == nil then
    sc.sequin_selector = grid_sequencer:register_ui_group("sequin_selector",6,1,14,1,2,3)
  local selected_sequin = sc.selected_sequin
    for i=6,14,1 do
      for j=1,1,1 do
        if i ~= selected_sequin then
          grid_sequencer:solid_off(i, j, sc.from_view)  
        end
      end
    end
    if selected_sequin then
      local selected_sequin_offset = 5
      grid_sequencer:solid_on(selected_sequin+selected_sequin_offset, 1, 1) 
    end
  end
end

function sc.update_sequin_selector(x, y, state)
  if state == "on" then
    local num_output_types = #sc.outputs_map
    -- if sc.sequin_output_types then sc:unregister_ui_group(6,2) end
    if sc.sequin_output_types == nil then 
      sc.sequin_output_types = grid_sequencer:register_ui_group("sequin_output_types",6,2,5+num_output_types,2,4,3)
    end
    -- sc.sequins_mods = grid_sequencer:register_ui_group("sequins_mods",15,2,15,7,7,3)
    sc.set_selected_sequin(x - sc.selectors_x_offset)
  else
    -- sc.active_value_heirarchy = nil
    -- sc:unregister_ui_group(6,2)
    -- sc.selected_sequin = nil
    -- sc.selected_sequin_output_type = nil
    -- sc.selected_sequin_output = nil
    -- sc.selected_sequin_output_mode = nil
    -- sc.selected_sequin_output_param = nil
    -- sc.value_place_integer = nil
    -- sc.value_place_decimal = nil
    -- sc.value_polarity = nil
    -- sc.sequence_mode = nil
    -- sc.value_number = nil
    -- sc.value_option = nil
    -- sc.active_output_value_text = nil
  end
end

-----------------------------
--  row 2: cols 6-14
-- ui group 7 sequins modifiers - functions
-----------------------------
-- UI functions
function sc.update_sequins_mods(x, y, state)
  if state == "on" then

  else
  
  end
end


-----------------------------
-- rows 2-7, col 15
-- ui group 8 sequin output types - functions
-----------------------------

-- UI functions
function sc.update_sequin_output_types(x, y, state)
  sc.active_value_heirarchy = nil
  if state == "on" then
    local  output_type_selected = x - sc.selectors_x_offset
    sc.selected_sequin_output_type =   output_type_selected
    sc:unregister_ui_group(6,3)
    local num_outputs = sc.outputs_map[output_type_selected]
    -- if sc.sequin_output_modes then 
    --   sc:unregister_ui_group(6,4)
    -- elseif sc.sequin_output_params then
    --   sc:unregister_ui_group(6,5)
    -- end

    sc.sequin_outputs = grid_sequencer:register_ui_group("sequin_outputs",6,3,5+num_outputs,3,7,3)
  else
    sc:unregister_ui_group(6,3)
    sc.selected_sequin_output = nil
    sc.selected_sequin_output_mode = nil
    sc.selected_sequin_output_param = nil
    sc.value_place_integer = nil
    sc.value_place_decimal = nil
    sc.value_polarity = nil
    sc.sequence_mode = nil
    sc.value_number = nil
    sc.value_option = nil
    sc.active_output_value_text = nil
  end
end

-----------------------------
--  row 3: cols 6-14
-- ui group 9 sequin outputs - functions
-----------------------------

-- UI functions
function sc.update_sequin_outputs(x, y, state)
  -- sc.unregister_value_selectors()
  -- sc.selected_sequin_output = nil
  -- sc.selected_sequin_output_mode = nil
  -- sc.selected_sequin_output_param = nil
  sc.active_value_heirarchy = nil
  if state == "on" then
    sc.selected_sequin_output_mode = nil
    sc.selected_sequin_output_param = nil
    sc.value_place_integer = nil
    sc.value_place_decimal = nil
    sc.value_polarity = nil
    sc.sequence_mode = nil
    sc.value_number = nil
    sc.value_option = nil
    sc.value_note_num = nil
    sc.value_octave = nil
    sc.active_output_value_text = nil

    local output_type_selected = sc.selected_sequin_output_type
    local output_selected = x - sc.selectors_x_offset
    sc.selected_sequin_output = output_selected

    if sc.sequin_output_modes then 
      sc:unregister_ui_group(6,4)
    elseif sc.sequin_output_params then
      sc:unregister_ui_group(6,5)
    else 
      for i=1,14,1 do
        if grid_sequencer:find_ui_group_num_by_xy(i,6) then
          sc:unregister_ui_group(i,6)
        end
      end
      for i=1,14,1 do
        if grid_sequencer:find_ui_group_num_by_xy(i,7) then
          sc:unregister_ui_group(i,7)
        end
      end
    end
    local num_output_modes = sc.output_mode_map[output_type_selected][output_selected]
    local num_output_params = sc.output_params_map[output_type_selected][output_selected]
    -- if #sc.output_mode_map[output_type_selected][output_selected] > 0 then -- there are output sub types
    if num_output_modes then -- the output selected has output_modes, show them
      sc.sequin_output_modes = grid_sequencer:register_ui_group("sequin_output_modes",6,4,5+num_output_modes,4,7,3)
    elseif num_output_params then -- no output_modes, show the output params if there are any
      sc.sequin_output_params = grid_sequencer:register_ui_group("sequin_output_params",6,5,5+num_output_params,5,7,3)
    else -- show value setters
      sc.set_sequin_output_value_controls()
    end
  else

    if sc.sequin_output_modes then 
      sc:unregister_ui_group(6,4)
    elseif sc.sequin_output_params then
      sc:unregister_ui_group(6,5)
    else
      for i=1,14,1 do
        if grid_sequencer:find_ui_group_num_by_xy(i,6) then
          sc:unregister_ui_group(i,6)
        end
      end
      for i=1,14,1 do
        if grid_sequencer:find_ui_group_num_by_xy(i,7) then
          sc:unregister_ui_group(i,7)
        end
      end
    end
    sc.selected_sequin_output = nil
    sc.selected_sequin_output_mode = nil
    sc.selected_sequin_output_param = nil
    sc.value_place_integer = nil
    sc.value_place_decimal = nil
    sc.value_polarity = nil
    sc.sequence_mode = nil
    sc.value_number = nil
    sc.value_option = nil
    sc.value_note_num = nil
    sc.value_octave = nil
    sc.active_output_value_text = nil
  end
end

-----------------------------
--  row 4: cols 6-14
-- ui group 10 sequin output modes - functions
-----------------------------
-- UI functions
function sc.update_sequin_output_modes(x, y, state)
  -- sc.unregister_value_selectors()
  -- sc.selected_sequin_output_param = nil
  -- sc.active_value_heirarchy = nil
  if state == "on" then
    local output_mode_selected = x - sc.selectors_x_offset
    sc.selected_sequin_output_mode = output_mode_selected
    local output_type_selected = sc.selected_sequin_output_type
    local output_selected = sc.selected_sequin_output
    local num_output_mode_params = sc.output_params_map[output_type_selected][output_selected][output_mode_selected]
    if sc.sequin_output_params or sc.value_option then
      sc:unregister_ui_group(6,6)
      sc:unregister_ui_group(6,5)
      sc.selected_sequin_output_param = nil
      sc.value_place_integer = nil
      sc.value_place_decimal = nil
      sc.value_polarity = nil
      sc.sequence_mode = nil
      sc.value_number = nil
      sc.value_option = nil
      sc.value_note_num = nil
      sc.value_octave = nil
      sc.active_output_value_text = nil  
    end
    for i=1,14,1 do
      if grid_sequencer:find_ui_group_num_by_xy(i,7) then
        sc:unregister_ui_group(i,7)
      end
    end

    if num_output_mode_params then
      sc.sequin_output_params = grid_sequencer:register_ui_group("sequin_output_params",6,5,5+num_output_mode_params,5,7,3)
    else
      -- just 1 param: show values
      sc.set_sequin_output_value_controls()
    end
  else
    sc:unregister_ui_group(6,6)
    sc:unregister_ui_group(6,5)

    for i=1,14,1 do
      if grid_sequencer:find_ui_group_num_by_xy(i,7) then
        sc:unregister_ui_group(i,7)
      end
    end
    -- sc.unregister_value_selectors()
    sc.selected_sequin_output_mode = nil
    sc.selected_sequin_output_param = nil
    sc.value_place_integer = nil
    sc.value_place_decimal = nil
    sc.value_polarity = nil
    sc.sequence_mode = nil
    sc.value_number = nil
    sc.value_option = nil
    sc.value_note_num = nil
    sc.value_octave = nil
    sc.active_output_value_text = nil
  end
end


-----------------------------
--  row 5: cols 6-14
-- ui group 11 sequin output params - functions
-----------------------------
-- UI functions
function sc.update_sequin_output_params(x, y, state)
  -- sc.unregister_value_selectors()
  sc.active_value_heirarchy = nil
  if state == "on" then
    sc.selected_sequin_output_param = x - sc.selectors_x_offset
    --SHOW VALUE SETTERS
    sc:unregister_ui_group(6,6)
    for i=1,14,1 do
      if grid_sequencer:find_ui_group_num_by_xy(i,7) then
        sc:unregister_ui_group(i,7)
      end
    end
    sc.set_sequin_output_value_controls()
  else
    for i=1,14,1 do
      if grid_sequencer:find_ui_group_num_by_xy(i,7) then
        sc:unregister_ui_group(i,7)
      end
    end
    sc:unregister_ui_group(6,6)
    sc.selected_sequin_output_param = nil
    sc.value_place_integer = nil
    sc.value_place_decimal = nil
    sc.value_polarity = nil
    sc.sequence_mode = nil
    sc.value_number = nil
    sc.value_option = nil
    sc.value_note_num = nil
    sc.value_octave = nil
    sc.active_output_value_text = nil
    -- sc.unregister_value_selectors()
  end
end

----------------------------------
--  row 7: cols 6-14
-- 8-10 sequin output control specs (options/number place settings)
----------------------------------
function sc.set_sequin_output_value_controls()
  sc.update_active_value_heirarchy()
  local output_type_selected = sc.selected_sequin_output_type
  local output_selected = sc.selected_sequin_output
  local output_mode_selected = sc.selected_sequin_output_mode
  local output_param_selected = sc.selected_sequin_output_param
  
  if output_param_selected and grid_sequencer:find_ui_group_num_by_xy(6,5) then -- the output has multiple params, check if it also has modes
    if output_mode_selected and grid_sequencer:find_ui_group_num_by_xy(6,4) then -- the output has modes and multiple params
      --output param selected with modes
      sc.refresh_output_control_specs_map()
      sc.output_control_specs_selected = 
        sc.output_control_specs_map[output_type_selected][output_selected][output_mode_selected][output_param_selected]
    else -- the output has just params
      sc.refresh_output_control_specs_map()
      sc.output_control_specs_selected = 
        sc.output_control_specs_map[output_type_selected][output_selected][output_param_selected]
    end
  elseif output_mode_selected and grid_sequencer:find_ui_group_num_by_xy(6,4) then -- the output has modes but no params
    --output mode selected, no params
    sc.refresh_output_control_specs_map()
    sc.output_control_specs_selected = 
      sc.output_control_specs_map[output_type_selected][output_selected][output_mode_selected]
  elseif output_selected and grid_sequencer:find_ui_group_num_by_xy(6,3) then -- the output doesn't have either modes or multiple params
    --output selected, neither nodes nor params
    sc.refresh_output_control_specs_map()
    sc.output_control_specs_selected = 
      sc.output_control_specs_map[output_type_selected][output_selected]
  end
  sc.set_output_values(sc.output_control_specs_selected)
end

-- todo: address use case where control_max is < 0
-- todo: make this function less horribly written
function sc.set_output_values(control_spec)
  local control_type = control_spec[1]
  local control_default_index = control_spec[4] or 1
  sc.active_sequin_control_id = control_spec[5]
  sc.active_sequin_control_name = control_spec[6]
  if control_type == "note" then
    sc.set_active_sequin_value_type("notes")
    -- sc:unregister_ui_group(4,6) 

    -- scale_length
    local root_note = params:get("root_note")
    local note_center_frequency = params:get("note_center_frequency")
    local notes_per_octave = fn.get_num_notes_per_octave()
    local num_octaves = math.ceil(scale_length/notes_per_octave)

    local last_key = 5
    local first_key = num_octaves > last_key and 1 or last_key - num_octaves + 1
    local default_key = math.floor((last_key+first_key)/2)
    sc.value_selector_notes = grid_sequencer:register_ui_group("value_selector_notes",6,6,5+notes_per_octave,6,7,3,control_spec)
    sc.value_selector_octaves = grid_sequencer:register_ui_group("value_selector_octaves",first_key,6,last_key,6,4,6,control_spec, default_key)
    if sc.selector_sequence_mode == nil then
      sc.selector_sequence_mode = grid_sequencer:register_ui_group("selector_sequence_mode",4,7,5,7,10,6,control_spec, 5)
    end

  elseif control_type == "number" then
    sc.set_active_sequin_value_type("number")

    local control_min, control_max
    
    
    local polarity = sc.value_polarity and sc.value_polarity or 1
    control_min = tonumber(control_spec[2])
    control_max = tonumber(control_spec[3])
    local control_default_index = control_spec[4]
    local control_min_length, control_max_length
    -- control_min_length = #tostring(math.abs(control_min)) 
    control_min_length = #control_spec[2] 
    control_max_length = polarity ~= -1 and #tostring(math.floor(control_max)) or control_min_length
    -- control_max_length = polarity ~= -1 and #control_spec[3] or control_min_length
     
    local decimal_location = string.find(math.abs(control_min),"%.") or 0
    local decimal_num_places = decimal_location > 0 and control_min_length - decimal_location or 0
    -- local integer_num_places = decimal_location > 0 and control_max_length - (control_max_length - decimal_location) or control_max_length
    local integer_num_places = control_max_length
    integer_num_places = (control_max <= -1 or control_max >= 1) and integer_num_places or nil
    -- local value_selector_length = integer_num_places + decimal_num_places
    local value_place_decimals_x1, value_place_decimals_x2
    if decimal_location > 0 then
      value_place_decimals_x1 = decimal_num_places and 14 - decimal_num_places + 1 or nil
      value_place_decimals_x2 = decimal_num_places and 14 or nil
      sc.value_place_decimals = grid_sequencer:register_ui_group("value_place_decimals",value_place_decimals_x1,7,value_place_decimals_x2,7,4,3,control_spec, control_default_index)
      sc.decimal_button = grid_sequencer:register_ui_group("decimal_button",value_place_decimals_x1-1,7,value_place_decimals_x1-1,7,15,5)
    end

    local polarity_min_max = control_min < 0 and control_max > 0
    if polarity_min_max and sc.value_selector_polarity == nil then
      sc.value_selector_polarity = grid_sequencer:register_ui_group("value_selector_polarity",4,6,5,6,4,6,control_spec, 5)
    end

    if sc.selector_sequence_mode == nil then
      sc.selector_sequence_mode = grid_sequencer:register_ui_group("selector_sequence_mode",4,7,5,7,10,6,control_spec, 5)
    end

    if integer_num_places then
      local value_place_integers_x1, value_place_integers_x2
      if decimal_num_places and integer_num_places then
        value_place_integers_x1 = 14 - integer_num_places - decimal_num_places
        value_place_integers_x2 = value_place_integers_x1 + integer_num_places - 1
      elseif integer_num_places then
        value_place_integers_x1 = 14 - integer_num_places
        value_place_integers_x2 = value_place_integers_x1 + integer_num_places - 1
      end
      sc.value_place_integers = grid_sequencer:register_ui_group("value_place_integers",value_place_integers_x1,7,value_place_integers_x2,7,4,3,control_spec, control_default_index)
      -- if there's just 1 value for the integer place auto-select it
      if(value_place_integers_x1 == value_place_integers_x2 and value_place_decimals_x1 == nil) then
        grid_sequencer.activate_grid_key_at(14,7)
      end
    end  

    
  elseif control_type == "fraction" then
    sc.set_active_sequin_value_type("fraction")
    
    sc:unregister_ui_group(4,6) 
  
  elseif control_type == "option" then
    sc.set_active_sequin_value_type("option")
    
    sc:unregister_ui_group(4,6) 

    local num_options = #control_spec[2]
    local control_default_index = control_spec[3]
    sc.value_selector_options = grid_sequencer:register_ui_group("value_selector_options",6,6,6+num_options-1,6,4,3,control_spec, control_default_index)
    local existing_output_value = sc.get_active_output_table_slot().output_value
    if existing_output_value then
      clock.run(sc.activate_grid_key_at,5+tonumber(existing_output_value.value),6) 
    end
  end
end

function sc.activate_grid_key_at(x,y)
  clock.sleep(0.1)
  grid_sequencer.activate_grid_key_at(x,y)    
  grid_sequencer.activate_grid_key_at(x,y)
end
-----------------------------
--  row 6: cols 6-14
-- ui group 11-13  value number place setters (integers/decimals) - functions
-----------------------------
function sc.update_value_place_integers(x, y, state)
  sc:unregister_ui_group(6,6)
  if sc.value_place_integers == nil then
    sc.set_sequin_output_value_controls()
  end
  local x1 =  sc.value_place_integers.grid_data.x1
  local x2 =  sc.value_place_integers.grid_data.x2
  local x_offset = x1 - 1
  if state == "on" then
    if sc.value_place_decimals then
      local decimal_x1 = sc.value_place_decimals.grid_data.x1
      local decimal_x2 = sc.value_place_decimals.grid_data.x2
      for i=decimal_x1,decimal_x2,1 do
        grid_sequencer:solid_off(i, 7)  
      end
    end
    local num_integer_places = x2 - x1 + 1
    local is_last_integer_place = x == x1

    local x_location = x2 - x + 1
    sc.value_place_integer = x_location
    if x_location == 1 then 
      sc.active_value_selector_place = "ones"
    elseif x_location == 2 then 
      sc.active_value_selector_place = "tens"
    elseif x_location == 3 then 
      sc.active_value_selector_place = "hundreds"
    elseif x_location == 4 then 
      sc.active_value_selector_place = "thousands"
    elseif x_location == 5 then 
      sc.active_value_selector_place = "ten_thousands"
    end

    local control_spec = sc.value_place_integers.control_spec
    local max = control_spec[3]
    local last_place_value = string.sub(tostring(max),1,1)
    local selector_length = (is_last_integer_place and  tonumber(last_place_value) > 0) and 5+tonumber(last_place_value) or 14
    sc.value_selector_nums = grid_sequencer:register_ui_group("value_selector_nums",6,6,selector_length,6,4,3)
    local existing_output_value = sc.get_active_output_table_slot().output_value
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
    -- sc:unregister_ui_group(6,6)
    sc.value_place_integer = nil
    sc.active_output_value_text = nil
  end
end

function sc.update_value_place_decimals(x, y, state)
  sc:unregister_ui_group(6,6)

  local x1 =  sc.value_place_decimals.grid_data.x1
  local x2 =  sc.value_place_decimals.grid_data.x2
  local x_offset = x1 - 1
  
  if state == "on" then
    if sc.value_place_integers then
      local integer_x1 = sc.value_place_integers.grid_data.x1
      local integer_x2 = sc.value_place_integers.grid_data.x2
      for i=integer_x1,integer_x2,1 do
          grid_sequencer:solid_off(i, 7)  
      end
    end
    local num_decimal_places = x2 - x1 + 1
    local is_last_decimal_place = x == x2

    local x_location = x - x1 + 1
    sc.value_place_decimal = x_location
    if x_location  == 1 then 
      sc.active_value_selector_place = "tenths"
    elseif x_location  == 2 then 
      sc.active_value_selector_place = "hundredths"
    elseif x_location  == 3 then 
      sc.active_value_selector_place = "thousandths"
    end

    local control_spec = sc.value_place_decimals.control_spec
    local min = control_spec[2]
    local min_length = #min
    local last_place_value = tonumber(string.sub(min,min_length))


    
    local first_selector = (is_last_decimal_place and  last_place_value > 0) and 5+last_place_value or 6
    sc.value_selector_nums = grid_sequencer:register_ui_group("value_selector_nums",first_selector,6,14,6,4,3)

    local selector_length = (is_last_decimal_place and  last_place_value > 0) and 5+last_place_value or 14
    -- sc.value_selector_nums = grid_sequencer:register_ui_group("value_selector_nums",6,6,selector_length,6,4,3)


    local existing_output_value = sc.get_active_output_table_slot().output_value
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
    -- sc:unregister_ui_group(6,6)
    sc.value_place_decimal = nil
    sc.active_output_value_text = nil
  end
end

-----------------------------
--  row 8: col 5
-- ui group 14 sequin value selector  - functions
--  HERE IS WHERE THE SEQUIN GETS SET
-----------------------------
-- function sc.unregister_value_selectors(active_selector_type)
function sc.unregister_value_selectors()
  sc:unregister_ui_group(4,6) 
  if sc.value_place_integers then 
    local x1 = sc.value_place_integers.grid_data.x1
    local x2 = sc.value_place_integers.grid_data.x2
    local y1 = sc.value_place_integers.grid_data.y1
    local y2 = sc.value_place_integers.grid_data.y2
    sc:unregister_ui_group(x1,y1) 
  end
  if sc.value_place_decimals then 
    local x1 = sc.value_place_decimals.grid_data.x1
    local x2 = sc.value_place_decimals.grid_data.x2
    local y1 = sc.value_place_decimals.grid_data.y1
    local y2 = sc.value_place_decimals.grid_data.y2
    sc:unregister_ui_group(x1,y1) 
  end
  if sc.decimal_button then 
    local x1 = sc.decimal_button.grid_data.x1
    local x2 = sc.decimal_button.grid_data.x2
    local y1 = sc.decimal_button.grid_data.y1
    local y2 = sc.decimal_button.grid_data.y2
    sc:unregister_ui_group(x1,y1) 
  end
  sc.active_value_selector_place = nil
  sc.active_output_value_text = nil
end

function sc.update_value_selector_notes(x, y, state)
  if state == "on" then  
    local x_offset = sc.value_selector_notes.grid_data.x1 - 1
    local selector_value = x - x_offset
    sc.active_sequin_value.note_value = selector_value
    sc.value_note_num = selector_value
    sc.sequin_output_values = grid_sequencer:register_ui_group("sequin_output_values",6,8,10,8,5,3)
  else
    -- if sc.sequin_output_values then sc:unregister_ui_group(6,8) end
    sc.active_sequin_value.note_value = 0
    sc.value_note_num = 0
    sc.active_output_value_text = 0
  end
end

  -- octave zero is the default octave 0. 
  -- grid selections to the left  of octave_zero will be negative octave values
  -- grid selections to the right of octave_zero will be postitive octave values
  -- for example:
  --    if octave_zero is 3
  --    and x_offset is 0 (meaning, the first octave grid key is in the first grid column)
  --    and the selected key column is 1 (x param is the selected key column)
  --    then the octave value will be -2
    function sc.update_value_octave(x, y, state)
  if state == "on" then  
    local x_offset = sc.value_selector_octaves.grid_data.x1 - 1
    local octave_zero = sc.value_selector_octaves.grid_data.default_value
    local selector_value = x - octave_zero - x_offset
    sc.active_sequin_value.octave_value = selector_value
    sc.value_octave = selector_value
    sc.sequin_output_values = grid_sequencer:register_ui_group("sequin_output_values",6,8,10,8,5,3)
  end
end

function sc.update_value_selector_options(x, y, state)
  local x_offset = sc.value_selector_options.grid_data.x1 - 1
  if state == "on" then  
    local selector_value = x - x_offset
    sc.active_sequin_value.option_value = selector_value
    sc.value_option = selector_value

                                              -- grid_sequencer:register_ui_group(group_name,x1,y1,x2, y2, off_level, selection_mode, control_spec, default_value)

    sc.sequin_output_values = grid_sequencer:register_ui_group("sequin_output_values",6,8,10,8,5,3)
  else
    if sc.sequin_output_values then sc:unregister_ui_group(6,8) end
    sc.value_option = nil
    sc.active_output_value_text = nil
  end
end

function sc.update_value_polarity(x, y, state)
    sc.value_polarity = x == 4 and -1 or 1
    -- sc.unregister_value_selectors()
    sc.set_sequin_output_value_controls()
end

function sc.update_selector_sequence_mode(x, y, state)
  sc.sequence_mode = x == 4 and 1 or 2
  -- sc.unregister_value_selectors()
  sc.set_sequin_output_value_controls()
end



function sc.update_value_selector_nums(x, y, state)
  local x_offset = 5 --sc.value_selector_nums.grid_data.x1 - 1
  if state == "on" then
    local selector_value = x - x_offset
    sc.value_number = selector_value
    if sc.active_value_selector_place == "ten_thousands" then
      sc.active_sequin_value.place_values.ten_thousands =  selector_value
    elseif sc.active_value_selector_place == "thousands" then
      sc.active_sequin_value.place_values.thousands =  selector_value
    elseif sc.active_value_selector_place == "hundreds" then
      sc.active_sequin_value.place_values.hundreds =  selector_value
    elseif sc.active_value_selector_place == "ones" then
      sc.active_sequin_value.place_values.ones =  selector_value
    elseif sc.active_value_selector_place == "tens" then
      sc.active_sequin_value.place_values.tens =  selector_value
    elseif sc.active_value_selector_place == "tenths" then
      sc.active_sequin_value.place_values.tenths =  selector_value
    elseif sc.active_value_selector_place == "hundredths" then
      sc.active_sequin_value.place_values.hundredths =  selector_value
    elseif sc.active_value_selector_place == "thousandths" then
      sc.active_sequin_value.place_values.thousandths =  selector_value
    end
    
    sc.sequin_output_values = grid_sequencer:register_ui_group("sequin_output_values",6,8,10,8,5,3)
  else
    sc.value_number = nil
    if sc.active_value_selector_place == "ten_thousands" then
      sc.active_sequin_value.place_values.ten_thousands =  0
    elseif sc.active_value_selector_place == "thousands" then
      sc.active_sequin_value.place_values.thousands =  0
    elseif sc.active_value_selector_place == "hundreds" then
      sc.active_sequin_value.place_values.hundreds =  0
    elseif sc.active_value_selector_place == "ones" then
      sc.active_sequin_value.place_values.ones =  0
    elseif sc.active_value_selector_place == "tens" then
      sc.active_sequin_value.place_values.tens =  0
    elseif sc.active_value_selector_place == "tenths" then
      sc.active_sequin_value.place_values.tenths =  0
    elseif sc.active_value_selector_place == "hundredths" then
      sc.active_sequin_value.place_values.hundredths =  0
    elseif sc.active_value_selector_place == "thousandths" then
      sc.active_sequin_value.place_values.thousandths =  0
    end
    sc.sequin_output_values = grid_sequencer:register_ui_group("sequin_output_values",6,8,10,8,5,3)    
  end
end


---------------- THE SEQUIN GETS SET HERE ---------------
function sc.reset_place_values(exception)
  sc.active_sequin_value.place_values.ten_thousands   = (exception == "ten_thousands")  and  sc.active_sequin_value.place_values.ten_thousands or  0
  sc.active_sequin_value.place_values.thousands       = (exception == "thousands")      and  sc.active_sequin_value.place_values.thousands     or  0
  sc.active_sequin_value.place_values.hundreds        = (exception == "hundreds")       and  sc.active_sequin_value.place_values.hundreds      or  0
  sc.active_sequin_value.place_values.ones            = (exception == "ones")           and  sc.active_sequin_value.place_values.ones          or  0
  sc.active_sequin_value.place_values.tens            = (exception == "tens")           and  sc.active_sequin_value.place_values.tens          or  0
  sc.active_sequin_value.place_values.tenths          = (exception == "tenths")         and  sc.active_sequin_value.place_values.tenths        or  0
  sc.active_sequin_value.place_values.hundredths      = (exception == "hundredths")     and  sc.active_sequin_value.place_values.hundredths    or  0
  sc.active_sequin_value.place_values.thousandths     = (exception == "thousandths")    and  sc.active_sequin_value.place_values.thousandths   or  0
end

function sc.get_previous_active_sequin_value(selected_sequin)
  -- selected_control_indices = sc.get_selected_indices()
  local active_output_values = sc.get_output_values()
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

function sc.get_active_control_min()
  return tonumber(sequencer_controller.value_place_integers.control_spec[2])
end
function sc.get_active_control_max()
  return tonumber(sequencer_controller.value_place_integers.control_spec[3])
end

function sc.update_sequin_output_value(x, y, state, press_type)
  
  local output_value
  local value_selector_default_value
  if press_type == "long" then
    local value_selector_group_id = grid_sequencer:find_ui_group_num_by_xy(6,6)
    value_selector_default_value = grid_sequencer.ui_groups[value_selector_group_id].default_value
    value_selector_default_value = value_selector_default_value and value_selector_default_value or nil

    -- if sc.active_value_selector_place then
    --   local reset_exception = sc.active_value_selector_place
    --   -- sc.reset_place_values(reset_exception)
    --   sc.reset_place_values()
    -- else
    --   sc.reset_place_values()
    -- end

  end

  if sc.active_sequin_value.value_type == "number" then
    output_value =  sc.active_sequin_value.place_values.ten_thousands ..
                    sc.active_sequin_value.place_values.thousands ..
                    sc.active_sequin_value.place_values.hundreds ..
                    sc.active_sequin_value.place_values.tens ..
                    sc.active_sequin_value.place_values.ones .. "." ..
                    sc.active_sequin_value.place_values.tenths ..
                    sc.active_sequin_value.place_values.hundredths ..
                    sc.active_sequin_value.place_values.thousandths
   
    local polarity = sc.value_polarity and sc.value_polarity or 1
    output_value = tonumber(output_value * polarity)

    if sequencer_controller.value_place_integers then
      local spec_min = sc.get_active_control_min()
      local spec_max = sc.get_active_control_max()
      output_value = util.clamp(output_value,spec_min,spec_max)
    end

    -- here's where the number gets cleared or set according to the sequence_mode
    local sequence_mode = sc.sequence_mode and sc.sequence_mode or 1
    if press_type == "long" then -- clear 
      output_value = "-" 
      sc.reset_place_values()
    else -- set
      local sequence_mode = sc.sequence_mode 
      output_value = sequence_mode == 1 and output_value .. "r" or output_value    
    end

    -- if press_type == "long" and output_value == 0 then 
    --   output_value = "-" 
    -- else 
    --   local sequence_mode = sc.sequence_mode 
    --   output_value = sequence_mode == 1 and output_value .. "r" or output_value    
    -- end                    
    
    sc.active_output_value_text = output_value
  elseif sc.active_sequin_value.value_type == "notes" then
    if press_type == "long" then
      -- output_value = value_selector_default_value
      output_value = "-"
    elseif sc.active_sequin_value.note_value then
      local num_notes_per_octave = fn.get_num_notes_per_octave()
      local octave_offset = sc.active_sequin_value.octave_value * num_notes_per_octave
      local sequence_mode = sc.sequence_mode 
      output_value = sc.active_sequin_value.note_value + octave_offset
      output_value = sequence_mode == 1 and output_value .. "r" or output_value    
    end
    -- local value_text = sc.get_options_text(output_value)
    sc.active_output_value_text = output_value
  elseif sc.active_sequin_value.value_type == "option" then
    if press_type == "long" then
      output_value = value_selector_default_value and value_selector_default_value or "-"
      sc.reset_place_values()
    else
      output_value = sc.active_sequin_value.option_value
    end
    local value_text = sc.get_options_text(output_value)
    sc.active_output_value_text = value_text
  end

  if x then
    local output_sequins_index = x - 5
    ---------------------------------------
    -- !!!!!!!!!!!!!!!!!!!!!!!!!!
    -- update the ouptut table
    -- !!!!!!!!!!!!!!!!!!!!!!!!!!
    ---------------------------------------
    sc.update_outputs_table(output_value,output_sequins_index)
    
    sc.update_sequin()
  end
end

-- todo: implement subgroups

function sc.update_sequin()
  local selected_indices = sc.get_selected_indices()
  local sgp = selected_indices.selected_sequin_group
  local sqn = selected_indices.selected_sequin
  -- print("update_sequin",sgp, sqn, sc.sequencers[sgp], sc.sequencers)
  local sequin_to_update = sc.sequencers[sgp].sequin_set[sqn]
  sequin_to_update.set_output_table(sc.sequins_outputs_table)
end

function sc.get_selected_indices()
  local indices = {
    selected_sequin_group         = sc.selected_sequin_group,         -- selected_sequin_group:  value table level 1
    selected_sequin_subgroup      = sc.selected_sequin_subgroup,      -- selected_sequin_group:  value table level 2
    selected_sequin               = sc.selected_sequin,          -- selected_sequin:  value table level 3
    selected_sequin_output_type   = sc.selected_sequin_output_type,    -- output_type_selected:  value table level 4
    selected_sequin_output        = sc.selected_sequin_output,         -- output_selected:  value table level 5
    selected_sequin_output_mode   = sc.selected_sequin_output_mode,    -- output_mode_selected:  value table level 6
    selected_sequin_output_param  = sc.selected_sequin_output_param,   -- output_param_selected:  value table level 7
  }
  return indices
end

function sc.get_options_text(option_index)
  -- local sgp = sc.selected_sequin_group
  -- local ssg = sc.selected_sequin_subgroup
  -- local sqn = sc.selected_sequin
  local typ = sc.selected_sequin_output_type
  local out = sc.selected_sequin_output
  local mod = sc.selected_sequin_output_mode
  local par = sc.selected_sequin_output_param
  local opt = sc.value_option

  local map = sc.get_output_control_specs_map()
  local options_table
  if map[typ][out] then 
    if map[typ][out][mod] and map[typ][out][mod][par] then
      options_table = map[typ][out][mod][par][2]
    elseif map[typ][out][mod] then
      options_table = map[typ][out][mod][2]
    elseif map[typ][out][par] then
      options_table = map[typ][out][par][2]
    end
  end
  -- tab.print(options_table)
  if option_index and type(options_table) == 'table' then
    local active_option_text = options_table[option_index]
    return active_option_text
  elseif options_table then
    options_table = type(options_table) == "table" and options_table or nil 
    return options_table
  else
    -- print("error",typ,out,mod,par)
  end
end

function sc.get_active_output_table_slot()
  local sgp     =   sc.selected_sequin_group         -- selected_sequin_group:  value table level 1
  local ssg  =   sc.selected_sequin_subgroup      -- selected_sequin_sub_group:  value table level 2
  local sqn     =   sc.selected_sequin          -- selected_sequin:  value table level 3
  local typ    =   sc.selected_sequin_output_type    -- output_type_selected:  value table level 4
  local out   =   sc.selected_sequin_output         -- output_selected:  value table level 5
  local mod    =   sc.selected_sequin_output_mode    -- output_mode_selected:  value table level 6
  local par    =   sc.selected_sequin_output_param   -- output_param_selected:  value table level 7
  mod = mod ~= nil and mod or 1 -- if output mode is nil set it to one to indicate there is just 1 output mode

  -- ??????????????????? IS THIS NEEDED  ???????????????????????
  sc.update_outputs_table()
  -- ??????????????????? ??????????????????? ???????????????????

  if par == nil then
    return sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod]
  else
    return sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par]
  end
end

function sc.update_outputs_table(output_value,output_sequins_index)
  local sgp     =   sc.selected_sequin_group         -- selected_sequin_group:  value table level 1
  local ssg  =   sc.selected_sequin_subgroup      -- selected_sequin_sub_group:  value table level 2
  local sqn     =   sc.selected_sequin          -- selected_sequin:  value table level 3
  local typ    =   sc.selected_sequin_output_type    -- output_type_selected:  value table level 4
  local out   =   sc.selected_sequin_output         -- output_selected:  value table level 5
  local mod    =   sc.selected_sequin_output_mode    -- output_mode_selected:  value table level 6
  local par    =   sc.selected_sequin_output_param   -- output_param_selected:  value table level 7
  mod = mod ~= nil and mod or 1 -- if output mode is nil set it to one to indicate there is just 1 output mode
  -- kinda klunky but push the output_value into the sequins_outputs_table
  --local sc.sequins_outputs_table = sc.sequins_outputs_table
  if sc.sequins_outputs_table[sgp] == nil then sc.sequins_outputs_table[sgp] = {} sc.sequins_outputs_table[sgp].table_type = "sgp" end
  if sc.sequins_outputs_table[sgp][ssg] == nil then sc.sequins_outputs_table[sgp][ssg] = {} sc.sequins_outputs_table[sgp][ssg].table_type = "sgp" end
  if sc.sequins_outputs_table[sgp][ssg][sqn] == nil then sc.sequins_outputs_table[sgp][ssg][sqn] = {} sc.sequins_outputs_table[sgp][ssg][sqn].table_type = "sqn" end
  if sc.sequins_outputs_table[sgp][ssg][sqn][typ] == nil then sc.sequins_outputs_table[sgp][ssg][sqn][typ] = {} sc.sequins_outputs_table[sgp][ssg][sqn][typ].table_type = "typ" end
  if sc.sequins_outputs_table[sgp][ssg][sqn][typ][out] == nil then sc.sequins_outputs_table[sgp][ssg][sqn][typ][out] = {} sc.sequins_outputs_table[sgp][ssg][sqn][typ][out].table_type = "out" end
  if sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod] == nil then sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod] = {} sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].table_type = "mod" end

  if par == nil then
    if sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod] == nil then 
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod] = {} 
    end
    -- local existing_output_data_at_location = sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data
    if output_value and output_value ~= "clear" then 
      if sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data == nil then
        local num_outputs = sc.sequins_outputs_table[sgp][ssg][sqn].num_outputs
        num_outputs = num_outputs == nil and 1 or num_outputs + 1
        sc.sequins_outputs_table[sgp][ssg][sqn].num_outputs = num_outputs
        sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].num_outputs = num_outputs
        sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data = {}
        sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data.seq = Sequins{table.unpack(DEFAULT_SUB_SEQUINS_TAB)}
      end
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].table_type = "mod" 
      -- sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data.value = output_value
      if output_value ~= "-" then
        sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data.seq[output_sequins_index] = output_value 
      else
        sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data.seq[output_sequins_index] = "nil"
      end
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data.value_heirarchy = {sgp=sgp,ssg=ssg,sqn=sqn,typ=typ,out=out,mod=mod}
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data.control_id = sc.active_sequin_control_id
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data.control_name = sc.active_sequin_control_name
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].output_data.value_type = sc.active_sequin_value.value_type
      sc.active_value_heirarchy = {sgp=sgp,ssg=ssg,sqn=sqn,typ=typ,out=out,mod=mod}
    elseif output_value == "clear" then
      -- print("clear all")
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod] = {}
    end
  else
    if sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod] == nil then 
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod] = {} 
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod].table_type = "mod" 
    end
    if sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par] == nil then 
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par] = {} 
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].table_type = "par" 
    end
    -- local existing_output_data_at_location = sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data
    if output_value and output_value ~= "clear" then 
      if sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data == nil then
        local num_outputs = sc.sequins_outputs_table[sgp][ssg][sqn].num_outputs
        num_outputs = num_outputs == nil and 1 or num_outputs + 1
        sc.sequins_outputs_table[sgp][ssg][sqn].num_outputs = num_outputs
        sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].num_outputs = num_outputs
        sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data = {}
        sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data.seq = Sequins{table.unpack(DEFAULT_SUB_SEQUINS_TAB)}
      end
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].table_type = "par" 
      -- sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data.value = output_value 
      if output_value ~= "-" then
        -- print("output_sequins_index",output_sequins_index)
        sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data.seq[output_sequins_index] = output_value 
      else
        sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data.seq[output_sequins_index] = "nil"
      end
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data.value_heirarchy = {sgp=sgp,ssg=ssg,sqn=sqn,typ=typ,out=out,mod=mod,par=par}
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data.control_id = sc.active_sequin_control_id
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data.control_name = sc.active_sequin_control_name
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par].output_data.value_type = sc.active_sequin_value.value_type
      sc.active_value_heirarchy = {sgp=sgp,ssg=ssg,sqn=sqn,typ=typ,out=out,mod=mod,par=par}
    elseif output_value == "clear" then
      local num_outputs = sc.sequins_outputs_table[sgp][ssg][sqn].num_outputs
      sc.sequins_outputs_table[sgp][ssg][sqn].num_outputs = num_outputs - 1
      sc.sequins_outputs_table[sgp][ssg][sqn][typ][out][mod][par] = {}
    end
  end
end

function sc.get_acnym_map()
  local acnym_map = {
    sgp = sc.selected_sequin_group,         -- selected_sequin_group:  value table level 1
    ssg = sc.selected_sequin_subgroup,      -- selected_sequin_group:  value table level 2
    sqn = sc.selected_sequin,          -- selected_sequin:  value table level 3
    typ = sc.selected_sequin_output_type,    -- output_type_selected:  value table level 4
    out = sc.selected_sequin_output,         -- output_selected:  value table level 5
    mod = sc.selected_sequin_output_mode,    -- output_mode_selected:  value table level 6
    par = sc.selected_sequin_output_param,   -- output_param_selected:  value table level 7
    int = sc.value_place_integer,
    dec = sc.value_place_decimal,
    sqm = sc.sequence_mode,
    pol = sc.value_polarity,
    num = sc.value_number,
    opt = sc.value_option,
    ntn = sc.value_note_num,
    oct = sc.value_octave,

  }
  if acnym_map.mod == nil and acnym_map.par then acnym_map.mod = 1 end
  return acnym_map
end

function sc.update_active_value_heirarchy()
  local a_map = sc.get_acnym_map()
  -- if sc.sequins_outputs_table[a_map.sgp] and sc.sequins_outputs_table[a_map.sgp][a_map.ssg] then 
    -- local sgp = a_map.sgp
    -- local ssg = a_map.ssg
    -- local sqn = sc.sequins_outputs_table[a_map.sgp][a_map.ssg][a_map.sqn]
    -- local type = sqn and sc.sequins_outputs_table[a_map.sgp][a_map.ssg][a_map.sqn][a_map.typ]
    -- local out = (sqn and type) and sc.sequins_outputs_table[a_map.sgp][a_map.ssg][a_map.sqn][a_map.typ][a_map.out]
    -- local mod = (sqn and type and out) and sc.sequins_outputs_table[a_map.sgp][a_map.ssg][a_map.sqn][a_map.typ][a_map.out][a_map.mod]
    -- local par = (sqn and type and out and mod) and sc.sequins_outputs_table[a_map.sgp][a_map.ssg][a_map.sqn][a_map.typ][a_map.out][a_map.mod][a_map.par]
    -- return output_data
    local output_data
    if a_map.par then 
      output_data = (a_map.sqn and a_map.type and a_map.out and a_map.mod and a_map.par) and sc.sequins_outputs_table[a_map.sgp][a_map.ssg][a_map.sqn][a_map.typ][a_map.out][a_map.mod][a_map.par].output_data
      sc.active_value_heirarchy = {sgp=a_map.sgp,ssg=a_map.ssg,sqn=a_map.sqn,typ=a_map.typ,out=a_map.out,mod=a_map.mod,par=a_map.par}
    elseif a_map.mod then
      output_data = (sqn and type and out and mod and par) and sc.sequins_outputs_table[a_map.sgp][a_map.ssg][a_map.sqn][a_map.typ][a_map.out][a_map.mod].output_data
      sc.active_value_heirarchy = {sgp=a_map.sgp,ssg=a_map.ssg,sqn=a_map.sqn,typ=a_map.typ,out=a_map.out,mod=a_map.mod}
    end
    if output_data then
      -- return output_data
      
    else
      --print("no output data") 
    end
  -- else
    --print("no heirarchy")
  -- end
end

function sc.refresh_selected_sequin_values(sgp,sqn,output_table,selected_sequin_values)
  sc.update_active_value_heirarchy()
  local output_table = output_table and output_table or sc.sequencers[sgp].seq[sqn].active_outputs
  local sequin_id = sqn

  sc.selected_sequin_values = selected_sequin_values and selected_sequin_values or nil
  local selected_sequin_values = selected_sequin_values and selected_sequin_values or nil
  local selected_sequin_value_heirarchy
  for k, v in pairs(output_table) do 
    if k == "output_data" then
      local selected_sequin = v.value_heirarchy.sqn
      
      if selected_sequin == sequin_id then
        -- local selected_sequin_output_group = sc.get_active_sequinset_id()
        local sequin_group = v.value_heirarchy.sgp
        local sequin_output_type  = v.value_heirarchy.typ
        local sequin_output        = v.value_heirarchy.out
        local sequin_output_param  = v.value_heirarchy.par      
        local sequin_output_mode   = v.value_heirarchy.mod

        
        -- local sequin_output_type_processor = sequin_processor.processors[sequin_output_type]

        -- if selected_sequin_output_group == sequin_output_group then

        local sel_ixs = sequencer_controller.get_selected_indices()
        
        
        if (
          sel_ixs.selected_sequin_group           == sequin_group         and
          sel_ixs.selected_sequin_output_type     == sequin_output_type   and 
          sel_ixs.selected_sequin_output          == sequin_output        and
          (sel_ixs.selected_sequin_output_param  == nil or sel_ixs.selected_sequin_output_param  == sequin_output_param)  and 
          (sel_ixs.selected_sequin_output_mode   == nil or sel_ixs.selected_sequin_output_mode   == sequin_output_mode)    
        ) then
          selected_sequin_values = fn.deep_copy(v.seq.data)
          selected_sequin_value_heirarchy = v.value_heirarchy
          sc.selected_sequin_ix = v.seq.ix

          -- if the selected control is an option, convert the values 
          if sc.output_control_specs_selected[1]=="option" then
            for i=1,#selected_sequin_values,1 do
              local idx = selected_sequin_values[i]
              selected_sequin_values[i]=sc.output_control_specs_selected[2][idx]
            end
          end
          sc.selected_sequin_values = selected_sequin_values
        else
          -- print("no match")
          -- selected_sequin_value_heirarchy = nil
          -- sc.selected_sequin_ix = nil
          -- selected_sequin_values = nil
        end
      end
    elseif type(v) == "table" and selected_sequin_values == nil then
      sc.refresh_selected_sequin_values(sgp,sqn,v,sc.selected_sequin_values)    
    end
  end
  
end

function sc.get_output_values(vh)
  sc.update_active_value_heirarchy()
  local vh = vh or sc.active_value_heirarchy
  local outputs_table = {}
  if vh and vh.par then
    for i=1,params:get("num_sequin"),1 do
      local sqn_index = i
      local sgp = sc.sequins_outputs_table[vh.sgp]
      local ssg = sgp and sc.sequins_outputs_table[vh.sgp][vh.ssg]
      local sqn = (sgp and ssg) and sc.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index]
      local type = (sgp and ssg and sqn) and sc.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ]
      local out = (sgp and ssg and sqn and type) and sc.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ][vh.out]
      local mod = (sgp and ssg and sqn and type and out) and sc.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ][vh.out][vh.mod]
      local par = (sgp and ssg and sqn and type and out and mod) and sc.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ][vh.out][vh.mod][vh.par]
      local output_data = (sgp and ssg and sqn and type and out and mod and par) and sc.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ][vh.out][vh.mod][vh.par].output_data
      local output_value = (sqn and output_data) and output_data.value or nil
      output_value = output_value == nil and "nil" or output_value
      local calculated_absolute_value = (sqn and output_data and output_data.calculated_absolute_value) and output_data.calculated_absolute_value or nil
      calculated_absolute_value = calculated_absolute_value == nil and "nil" or calculated_absolute_value
      table.insert(outputs_table,{output_value,calculated_absolute_value})
    end
  elseif vh and vh.mod then
    for i=1,params:get("num_sequin"),1 do
      local sqn_index = i
      local sgp = sc.sequins_outputs_table[vh.sgp]
      local ssg = sgp and sc.sequins_outputs_table[vh.sgp][vh.ssg]
      local sqn = (sgp and ssg) and sc.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index]
      local type = (sgp and ssg and sqn) and sc.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ]
      local out = (sgp and ssg and sqn and type) and sc.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ][vh.out]
      local mod = (sgp and ssg and sqn and type and out) and sc.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ][vh.out][vh.mod]
      local output_data = (sgp and ssg and sqn and type and out and mod) and sc.sequins_outputs_table[vh.sgp][vh.ssg][sqn_index][vh.typ][vh.out][vh.mod].output_data
      local output_value = (sqn and output_data) and output_data.value or nil
      output_value = output_value == nil and "nil" or output_value
      local calculated_absolute_value = (sqn and output_data and output_data.calculated_absolute_value) and output_data.calculated_absolute_value or nil
      calculated_absolute_value = calculated_absolute_value == nil and "nil" or calculated_absolute_value
      table.insert(outputs_table,{output_value,calculated_absolute_value})
    end
  end
  return outputs_table
end

----------------------------------
-- 
----------------------------------
function sc:get_active_ui_group()
  local num_ui_groups = grid_sequencer.get_num_ui_groups()
  local group_name = grid_sequencer.ui_groups[num_ui_groups].group_name
  -- group_name = string.sub(group_name,1,13) == "sequin_groups" and "sequin_groups" or group_name
  group_name = group_name:gsub("_"," ")
  return group_name
end

function sc.set_active_sequin_value_type(value_type)
  if value_type == "number" and sc.active_sequin_value.place_values == nil then
    sc.reset_place_values()
  elseif value_type == "option" and sc.active_sequin_value == nil then
    -- do something here?
    sc.active_sequin_value.place_values = nil
  end
  sc.active_sequin_value.value_type = value_type
end

function sc.get_active_sequin_value_type()
  return sc.active_sequin_value.value_type
end

function sc:update_group(group_name,x, y, state, press_type)
  -- print("group_name,x, y, state, press_type",group_name,x, y, state, press_type)
  -- local sequin_groups_start, sequin_groups_finish = string.find(group_name,"sequin_groups")
  -- sequencer_screen.update_screen_instructions(group_name, state)
  sc.active_output_value_text = nil
  if string.sub(group_name,1,13) == "sequin_groups" then 
    -- sync the sequin index 
    sc.selected_sequin_group = x
    local seq_ix = sc.sequencers[sc.selected_sequin_group].seq.ix

    -- local seq_ix
    -- if sc.selected_sequin_group then
      -- seq_ix = sc.sequencers[sc.selected_sequin_group].seq.ix
    -- end
    -- print("sc.selected_sequin_group,seq_ix",sc.selected_sequin_group,seq_ix)
    self.update_selected_sequin_group(x,state,seq_ix)
  elseif group_name == "sequin_selector" then
    self.update_sequin_selector(x, y, state)
  elseif group_name == "sequin_output_types" then
    self.update_sequin_output_types(x, y, state)
  elseif group_name == "sequins_mods" then
    self.update_sequins_mods(x, y, state)
  elseif group_name == "sequin_outputs" then
    self.update_sequin_outputs(x, y, state)
  elseif group_name == "sequin_output_modes" then
    self.update_sequin_output_modes(x, y, state)
  elseif group_name == "sequin_output_params" then
    self.update_sequin_output_params(x, y, state)
  elseif group_name == "value_selector_notes" then
    self.set_active_sequin_value_type("notes")
    self.update_value_selector_notes(x, y, state)
  elseif group_name == "value_selector_octaves" then
    self.update_value_octave(x, y, state)
  elseif group_name == "value_selector_options" then
    self.set_active_sequin_value_type("option")
    self.update_value_selector_options(x, y, state)
  elseif group_name == "value_place_integers" then
    self.set_active_sequin_value_type("number")
    self.update_value_place_integers(x, y, state)
  elseif group_name == "value_place_decimals" then
    self.set_active_sequin_value_type("number")
    self.update_value_place_decimals(x, y, state)
  elseif group_name == "selector_sequence_mode" then
    self.update_selector_sequence_mode(x, y, state)
  elseif group_name == "value_selector_polarity" then
    self.update_value_polarity(x, y, state)
  elseif group_name == "value_selector_nums" then
    self.update_value_selector_nums(x, y, state)
  elseif group_name == "sequin_output_values" then
    self.update_sequin_output_value(x, y, state, press_type)
  end
  self.update_sequin_output_value()
  self.update_active_value_heirarchy()

end


return sc