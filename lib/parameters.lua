
local parameters = {}

function parameters.init()
  --[[
  if p3_index==1 then
    -- vinyl = util.clamp(d_mul + vinyl,0,10)
    -- engine.vinyl(vinyl)
    pitchshift = util.clamp(d_mul + pitchshift,0,10)
    engine.pitchshift(pitchshift)
  elseif p3_index==2 then
    phaser = util.clamp(d_mul + phaser,0,10)
    engine.phaser(phaser)
  elseif p3_index==3 then
    delay = util.clamp(d_mul + delay,0,10)
    engine.delay(delay)
  elseif p3_index==4 then
    strobe = util.clamp(d_mul + strobe,0,5)
    engine.strobe(strobe)
  elseif p3_index==5 then
    drywet = util.clamp(d_mul + drywet,0,1)
    engine.drywet(drywet)
  end
  ]]


  params:add_control("center_frequency","center frequency",controlspec.FREQ:copy())
  params:set_action("center_frequency",function(x) 
    engine.set_center_frequency(x)
  end)  

  params:add_control("rq","center rq",controlspec.AMP:copy())
  params:set_action("rq",function(x) 
    if x <= 0 then 
      local rq = params:lookup_param("rq")
      params:set("rq",0.01)
    end
    engine.set_center_frequency(x)
  end)  

  ------------------------------
  -- effect params
  ------------------------------
  local effect_params = {
    -- {vinyl,vinyl,0,10,0,engine.vinyl}
    -- effect_name,effect_id,effect_min,effect_max,effect_default, effect_fn, effect_type
    {"pitchshift","pitchshift",0,1,0,engine.pitchshift,"control",},
    {"phaser","phaser",0,10,0,engine.phaser,"number",},
    {"delay","delay",0,10,0,engine.delay,"number",},
    {"strobe","strobe",0,5,0,engine.strobe,"number",},
    {"drywet","drywet",0,1,1,engine.drywet,"control",},
  }

  function parameters.add_effect_param(effect_name,effect_id,effect_min,effect_max,effect_default, effect_fn, effect_type)
    -- print(effect_name,effect_id,effect_min,effect_max,effect_default, effect_fn, effect_type)
    params:add{
      type = effect_type, id = effect_id, name = effect_name, default = effect_default,
      min=effect_min,max=effect_max,
      action = function(x) 
        effect_fn(x)
      end}
  end

  -- function parameters.set_params()
    params:add_separator("effects")
    for i=1,#effect_params,1
    do
      parameters.add_effect_param(effect_params[i][1],effect_params[i][2],effect_params[i][3],effect_params[i][4],effect_params[i][5],effect_params[i][6],effect_params[i][7])
    end


  -- end

  function build_scale()
    notes = {}
    notes = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), scale_length)
    local num_to_add = scale_length - #notes
    for i = 1, num_to_add do
      table.insert(notes, notes[scale_length - num_to_add])
    end
  end

  -- function set_scale_length()
  --   scale_length = params:get("scale_length")
  -- end


  -- params:add{type = "option", id = "scale_mode", name = "scale mode",
  -- options = scale_names, default = 5,
  -- action = function() build_scale() end}

  -- params:add{type = "number", id = "root_note", name = "root note",
  -- min = 0, max = 127, default = root_note_default, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
  -- action = function() build_scale() end}

  ------------------------------
  -- amplitude/frequency detection params
  ------------------------------
  params:add_separator("amp/freq detection")

  function parameters.add_amp_freq_params(afd_num_params,afd_id,afd_name,afd_controlspec,afd_fn,afd_default, afd_spread_defaults)  
    local min = afd_controlspec.minval
    local max = afd_controlspec.maxval
    local is_min = string.find(afd_id,"min")~=nil
      for i=1,afd_num_params,1
    do
      local cspec = afd_controlspec:copy()
      print(afd_spread_defaults)
      local spread = is_min == true and (max/afd_num_params) * (i-1) or  (max/afd_num_params) * (i)
      spread = util.linexp(min,max, 20, 2000, spread)
      if afd_spread_defaults == true then  
        cspec.default = spread
      elseif is_min == false then
        cspec.default = max
      end
      params:add_control(afd_id..i,afd_name..i,cspec)
    end
  end

  -- in the amp and freq action, make sure the min is never more than the max and vice versa
  -- note: there's probably a much, much simpler way to do this
  function parameters.set_amp_freq_param_actions(afd_num_params,afd_id,afd_fn)
    for i=1,afd_num_params,1
    do
      params:set_action(afd_id..i,function(x) 
        if (string.find(afd_id,"min")~=nil) then
          if (string.find(afd_id,"amp")~=nil) then
            local min_param = params:lookup_param("amp_min"..i)
            local max_val = params:get("amp_max"..i)
            local min_min_val = params:lookup_param("amp_min"..i).controlspec.minval
            x = util.clamp(x,min_min_val,max_val)
          else
            local min_param = params:lookup_param("frequency_min"..i)
            local max_val = params:get("frequency_max"..i)
            local min_min_val = params:lookup_param("frequency_min"..i).controlspec.minval
            x = util.clamp(x,min_min_val,max_val)
          end
        elseif (string.find(afd_id,"max")~=nil) then
          if (string.find(afd_id,"amp")~=nil) then
            local max_param = params:lookup_param("amp_max"..i)
            local min_val = params:get("amp_min"..i)
            local max_max_val = params:lookup_param("amp_min"..i).controlspec.maxval
            x = util.clamp(x,min_val,max_max_val)
          else
            local max_param = params:lookup_param("frequency_max"..i)
            local min_val = params:get("frequency_min"..i)
            local max_max_val = params:lookup_param("frequency_min"..i).controlspec.maxval
            x = util.clamp(x,min_val,max_max_val)
          end
        end
        params:set(afd_id..i,x,true)
        afd_fn(i-1,x)
      end)
    end
  end

  function parameters.create_amp_freq_params(af_params)

    for i=1,#af_params,1
    do
      parameters.add_amp_freq_params(4,af_params[i][1],af_params[i][2],af_params[i][3],af_params[i][4],af_params[i][5],af_params[i][6])
      parameters.set_amp_freq_param_actions(4,af_params[i][1],af_params[i][4])
    end
  end

  amp_params = {
    {"amp_min","amp min",controlspec.AMP:copy(),engine.set_detect_amp_min,0.01,},
    {"amp_max","amp max",controlspec.AMP:copy(),engine.set_detect_amp_max,0.99,},
  }

  freq_params = {
    {"frequency_min","freq min",controlspec.FREQ:copy(),engine.set_detect_frequency_min,40,true},
    {"frequency_max","freq max",controlspec.FREQ:copy(),engine.set_detect_frequency_max,800,true},
  }

  params:add_group("amp detection",8)
  parameters.create_amp_freq_params(amp_params)
  params:add_group("freq detection",8)
  parameters.create_amp_freq_params(freq_params)



  --------------------------------
  -- inputs/outputs/midi params
  --------------------------------
  params:add_separator("inputs/outputs")
  -- params:add_group("inputs/outputs",17+14)
  -- params:add{type = "option", id = "output_bandsaw", name = "bandsaw (eng)",
  -- options = {"off","engine", "midi", "engine + midi"},
  -- default = 2,
  -- }

  -- midi

  params:add_group("midi",8)

  --[[
  params:add{type = "option", id = "midi_engine_control", name = "midi engine control",
    options = {"off","on"},
    default = 2,
    -- action = function(value)
    -- end
  }
  ]]

  local midi_devices = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}

  params:add_separator("midi in")

  midi_in_device = {}
  params:add{
    type = "option", id = "midi_in_device", name = "in device", options = midi_devices, 
    min = 1, max = 16, default = 1, 
    action = function(value)

      print("set midi in",value)
      midi_in_device.event = nil
      midi_in_device = midi.connect(value)
      midi_in_device.event = midi_event
    end
  }

  params:add{
    type = "number", id = "midi_in_channel1", name = "midi_in channel1",
    min = 1, max = 16, default = midi_in_channel1_default,
    action = function(value)
      -- all_notes_off()
      midi_in_command1 = value + 143
    end
  }
    
  -- params:add{type = "number", id = "plant2_cc_channel", name = "plant 2:midi in channel",
  --   min = 1, max = 16, default = plant2_cc_channel,
  --   action = function(value)
  --     -- all_notes_off()
  --     midi_in_command2 = value + 143
  --   end
  -- }

  params:add{
    type = "number", id = "envelope1_cc_channel", name = "env 1:midi cc channel",
    min = 1, max = 16, default = envelope1_cc_channel,
    action = function(value)
      -- all_notes_off()
      envelope1_cc_channel = value
    end
  }

  params:add{
    type = "number", id = "envelope2_cc_channel", name = "env 2:midi cc channel",
    min = 1, max = 16, default = envelope2_cc_channel,
    action = function(value)
      -- all_notes_off()
      envelope2_cc_channel = value
    end
  }

  -- params:add{
  --   type = "number", id = "water_cc_channel", name = "water:midi cc channel",
  --   min = 1, max = 16, default = water_cc_channel,
  --   action = function(value)
  --     -- all_notes_off()
  --     water_cc_channel = value
  --   end
  -- }

  params:add_separator("midi out")

  params:add{type = "option", id = "output_midi", name = "midi out",
    options = {"off","engine", "midi", "engine + midi"},
    default = 1,
  }

  params:add{
    type = "option", id = "midi_out_device", name = "out device", options = midi_devices,
    min = 1, max = 16, default = 1,
    action = function(value) 
      midi_out_device = midi.connect(value) 
    end
  }

  -- params:add{
  --   type = "number", id = "midi_out_channel1", name = "plant 1:midi out channel",
  --   min = 1, max = 16, default = midi_out_channel1,
  --   action = function(value)
  --     -- all_notes_off()
  --     midi_out_channel1 = value
  --   end
  -- }
    
  -- params:add{type = "number", id = "midi_out_channel2", name = "plant 2:midi out channel",
  --   min = 1, max = 16, default = midi_out_channel2,
  --   action = function(value)
  --     -- all_notes_off()
  --     midi_out_channel2 = value
  --   end
  -- }

  get_midi_devices()

  -- crow
  params:add_group("crow",4)

  -- params:add{type = "option", id = "crow_clock", name = "crow clock out",
  -- options = {"off","on"},
  -- action = function(value)
  --   if value == 2 then
  --     crow.output[1].action = "{to(5,0),to(5,0.05),to(0,0)}"
  --   end
  -- end}

  params:add{type = "option", id = "output_crow1", name = "crow out1 mode",
    -- options = {"off","on"},
    options = {"off","engine", "midi", "engine + midi", "clock"},
    default = 2,
    action = function(value)
      if value == 5 then 
        crow.output[1].action = "{to(5,0),to(5,0.05),to(0,0)}"
      end
    end
  }

  params:add{type = "option", id = "output_crow2", name = "crow out2 mode",
    options = {"off","envelope","trigger","gate","clock"},
    default = 2,
    action = function(value)
      if value == 3 then 
        crow.output[2].action = "{to(5,0),to(0,0.25)}"
      elseif value == 5 then
        crow.output[2].action = "{to(5,0),to(5,0.05),to(0,0)}"
      end
    end
  }

  params:add{type = "option", id = "output_crow3", name = "crow out3 mode",
    -- options = {"off","on"},
    options = {"off","engine", "midi", "engine + midi", "clock"},
    default = 2,
    action = function(value)
      if value == 5 then 
        crow.output[3].action = "{to(5,0),to(5,0.05),to(0,0)}"
      end
    end
  }

  params:add{type = "option", id = "output_crow4", name = "crow out4 mode",
    options = {"off","envelope","trigger","gate", "clock"},
    default = 2,
    action = function(value)
      if value == 3 then 
        crow.output[4].action = "{to(5,0),to(0,0.25)}"
      elseif value == 5 then 
        crow.output[4].action = "{to(5,0),to(5,0.05),to(0,0)}"
      end
    end
  }

  -- just friends
  params:add_group("just friends",2)
  params:add{type = "option", id = "output_jf", name = "just friends",
    options = {"off","engine", "midi", "engine + midi"},
    default = 3,
    action = function(value)
      if value > 1 then 
        -- crow.output[2].action = "{to(5,0),to(0,0.25)}"
        crow.ii.pullup(true)
        crow.ii.jf.mode(1)
      else
        crow.ii.jf.mode(0)
        -- crow.ii.pullup(false)
      end
    end
  }

  params:add{type = "option", id = "jf_mode", name = "just friends mode",
    options = {"mono","poly"},
    default = 2,
    action = function(value)
      -- if value == 2 then 
      --   -- crow.output[2].action = "{to(5,0),to(0,0.25)}"
      --   crow.ii.pullup(true)
      --   crow.ii.jf.mode(1)
      -- else 
      --   crow.ii.jf.mode(0)
      --   -- crow.ii.pullup(false)
      -- end
    end
  }


  params:add_group("w/syn",14)
  w_slash.wsyn_add_params()
  -- w_slash.wsyn_v2_add_params()

  params:add_group("w/del",15)
  w_slash.wdel_add_params()

  params:add_group("w/tape",17)
  w_slash.wtape_add_params()



  --------------------------------
  -- envelope parameters
  --------------------------------
  params:add_group("envelopes",2+(num_envelopes*(MAX_ENVELOPE_NODES*3)))
  -- params:add_group("envelopes",2+4+(num_envelopes*(MAX_ENVELOPE_NODES*3))+19)
  params:add_separator("env controls")  
  -- params:add_separator("envelope")
  
  get_node_time = function(env_id, node_id)
    local node_time = envelopes[env_id].get_envelope_arrays().times[node_id]
    return node_time 
  end

  get_node_level = function(env_id, node_id)
    return envelopes[env_id].get_envelope_arrays().levels[node_id]
  end

  get_node_curve = function(env_id, node_id)
    return envelopes[env_id].get_envelope_arrays().curves[node_id]
  end

  reset_envelope_control_params = function(envelope_id, delay)
    -- if delay == true then clock.sleep(0.1) end
    local env_nodes = envelopes[envelope_id].graph_nodes
    -- local envelope_times = envelope_id == 1 and envelope1_times or envelope2_times
    for i=1,MAX_ENVELOPE_NODES,1
    do
      local param_id_name, param_name, get_control_value_fn, min_val, max_val

      -- update time
      param_id_name = "envelope".. envelope_id.."_time" .. i
      param_name = "envelope".. envelope_id.."-control" .. i .. "-time"
      get_control_value_fn = get_node_time
      local control_value = get_control_value_fn(envelope_id,i) or 1
      local param = params:lookup_param(param_id_name)
      local prev_val = (env_nodes[i-1] and env_nodes[i-1].time) or 0
      local next_val = env_nodes[i+1] and env_nodes[i+1].time or envelopes[envelope_id].env_time_max
      local controlspec = cs.new(prev_val,next_val,'lin',0,control_value,'')
      if env_nodes[i] then
        param.controlspec = controlspec
        if env_nodes[i].time ~= params:get(param.id)  then 
          params:set(param.id, control_value) 
        end
      end

      -- update level 
      param_id_name = "envelope".. envelope_id.."_level" .. i
      param_name = "envelope".. envelope_id.."-control" .. i .. "-level"
      get_control_value_fn = get_node_level
      local control_value = get_control_value_fn(envelope_id,i) or 1
      local param = params:lookup_param(param_id_name)
      local max_val = envelopes[envelope_id].env_level_max
      local controlspec = cs.new(0,max_val,'lin',0,control_value,'')
      if env_nodes[i] then
        param.controlspec = controlspec
        if (i == 1 or i == #envelopes[envelope_id].graph_nodes) and param:get() ~= 0 then
          params:set(param.id, 0) 
        elseif env_nodes[i].level ~= params:get(param.id)  then
          params:set(param.id, control_value) 
        end
      end
      
      -- update curve 
      param_id_name = "envelope".. envelope_id.."_curve" .. i
      param_name = "envelope".. envelope_id.."-control" .. i .. "-curve"
      get_control_value_fn = get_node_curve
      local control_value = get_control_value_fn(envelope_id,i) or 1
      local param = params:lookup_param(param_id_name)
      if env_nodes[i] then
        if env_nodes[i].curve ~= params:get(param.id)  then
          params:set(param.id, control_value) 
        end
      end
    end

    local time_param = params:lookup_param("time_modulation"..envelope_id)
    time_param.max = params:get("envelope"..envelope_id.."_max_time") * 0.1
    local level_param = params:lookup_param("level_modulation"..envelope_id)
    level_param.max = params:get("envelope"..envelope_id.."_max_level") * 0.1

    update_envelope_controls(envelope_id, x)
  end  

  update_envelope_controls = function (envelope_id, x)
    local num_envelope_controls = envelopes[1].get_envelope_arrays().segments or envelopes[2].get_envelope_arrays().segments
    -- local num_envelope_controls = envelope_id == 1 and envelopes[1].get_envelope_arrays().segments or envelopes[2].get_envelope_arrays().segments
    local envelope_times = envelope_id == 1 and envelope1_times or envelope2_times
    local envelope_levels = envelope_id == 1 and envelope1_levels or envelope2_levels
    local envelope_curves = envelope_id == 1 and envelope1_curves or envelope2_curves
    for i=1,MAX_ENVELOPE_NODES,1
    do
      if i <= num_envelope_controls then
        params:show(envelope1_times[i])
        if i > 1 then
          if i~=num_envelope_controls then 
            params:show(envelope_levels[i]) 
          else 
            params:hide(envelope_levels[i]) 
          end
          params:show(envelope_curves[i])
        end 
      else
        params:hide(envelope_times[i])
        params:hide(envelope_levels[i])
        params:hide(envelope_curves[i])
      end
    end
  end

  params:add_number("num_envelope1_controls", "num envelope1 controls", 3, MAX_ENVELOPE_NODES, 5)
  -- params:hide("num_envelope1_controls")

  params:set_action("num_envelope1_controls", 
    function(x)
      if initializing == false then
        add_remove_nodes(1, x)
      end
    end
  )

  params:add_number("num_envelope2_controls", "num envelope2 controls", 3, MAX_ENVELOPE_NODES, 5)
  -- params:hide("num_envelope2_controls")

  params:set_action("num_envelope2_controls", 
    function(x)
      if initializing == false then
        add_remove_nodes(2, x)
      end
    end
  )

  add_remove_nodes = function(envelope_id, num_nodes)
    if num_nodes < envelopes[envelope_id].get_num_nodes() then
      local num_controls_to_remove = #envelopes[envelope_id].graph_nodes - num_nodes
      for i=1,num_controls_to_remove,1
      do
        if envelopes[envelope_id].active_node < 2 or envelopes[envelope_id].active_node >= #envelopes[envelope_id].graph_nodes then 
          envelopes[envelope_id].set_active_node(2)
        end
        envelopes[envelope_id].remove_node()
        reset_envelope_control_params(envelope_id)
      end
    else
      local num_controls_to_add = num_nodes - #envelopes[envelope_id].graph_nodes
      for i=1,num_controls_to_add,1
      do
        if envelopes[envelope_id].active_node < 1 or envelopes[envelope_id].active_node >= #envelopes[envelope_id].graph_nodes then 
          envelopes[envelope_id].set_active_node(1)
        end
        envelopes[envelope_id].add_node()
        reset_envelope_control_params(envelope_id)
      end
    end
    
    local num_envelope_controls = envelope_id == 1 and "num_envelope1_controls" or "num_envelope2_controls"
    local num_env_nodes = #envelopes[envelope_id].graph_nodes
    params:set(num_envelope_controls,num_env_nodes)
  end

  local PLOW_LEVEL = cs.new(0.0,MAX_AMPLITUDE,'lin',0,AMPLITUDE_DEFAULT,'')
  local PLOW_TIME = cs.new(0.0,MAX_ENV_LENGTH,'lin',0,ENV_TIME_MAX,'')

  parameters.init_envelope_controls = function(envelope_id)
    -- set the values of the individual envelope nodes 
    local env = envelopes[1].graph_nodes
    -- local env = envelope_id == 1 and envelopes[1].graph_nodes or envelopes[2].graph_nodes
    local num_envelope1_controls =  envelopes[1].get_envelope_arrays().segments
    -- local num_envelope2_controls = envelopes[2].get_envelope_arrays().segments
    local num_envelope_controls = envelope_id == 1 and num_envelope1_controls or num_envelope2_controls
    local envelope_times = envelope_id == 1 and envelope1_times or envelope2_times
    local envelope_levels = envelope_id == 1 and envelope1_levels or envelope2_levels
    local envelope_curves = envelope_id == 1 and envelope1_curves or envelope2_curves
    
    
    -- set the envelope's overall max level
    params:add{
      type="control",
      id = envelope_id == 1 and "envelope1_max_level" or "envelope2_max_level",
      name = envelope_id == 1 and "envelope 1 max level" or "envelope 2 max level",
      controlspec=PLOW_LEVEL,
      action=function(x) 
        if initializing == false then envelopes[envelope_id].set_env_level(x) end
      end
    }
  
    -- set the envelope's overall max time
    params:add{
      type="control",
      id = envelope_id == 1 and "envelope1_max_time" or "envelope2_max_time",
      name = envelope_id == 1 and "envelope 1 max time" or "envelope 2 max time",
      controlspec=PLOW_TIME,
      action=function(x) 
        if initializing == false then envelopes[envelope_id].set_env_time(x) end
      end
    }  
    for i=1, MAX_ENVELOPE_NODES, 1
    do
      for j=1, 3, 1
      do
        local param_id_name, param_name, envelope_control_type, get_control_value_fn, min_val, max_val
        if j == 1 then
          envelope_control_type = "time"
          param_id_name = "envelope".. envelope_id.."_time" .. i
          param_name = "envelope ".. envelope_id.." control " .. i .. " time"
          get_control_value_fn = get_node_time
          min_val = 0
          max_val = MAX_ENV_LENGTH
        elseif j == 2 then
          envelope_control_type = "level"
          param_id_name = "envelope".. envelope_id.."_level" .. i
          param_name = "envelope ".. envelope_id.." control " .. i .. " level"
          get_control_value_fn = get_node_level
          min_val = 0.0
          max_val = MAX_AMPLITUDE
        else 
          envelope_control_type = "curve"
          param_id_name = "envelope".. envelope_id.."_curve" .. i
          param_name = "envelope ".. envelope_id.." control " .. i .. " curve"
          get_control_value_fn = get_node_curve
          min_val = CURVE_MIN
          max_val = CURVE_MAX
        end        
        
        params:add{
          type = "control", 
          id = param_id_name,
          name = param_name,
          controlspec = cs.new(min_val,max_val,'lin',0,control_value,''),
          action=function(x) 
            local control_value = get_control_value_fn(envelope_id,i) or 1
            local param = params:lookup_param(param_id_name)
            local new_val = x
            local env_nodes = envelopes[envelope_id].graph_nodes
            if envelope_control_type == "time" and initializing == false then
              local prev_val = (env_nodes[i-1] and env_nodes[i-1][envelope_control_type]) or 0
              local next_val = (env_nodes[i+1] and env_nodes[i+1][envelope_control_type]) or envelopes[envelope_id].get_env_time()
              new_val = util.clamp(new_val, prev_val, next_val)
              if env_nodes[i] and x ~= control_value then
                env_nodes[i][envelope_control_type] = new_val
                param.controlspec.minval = prev_val
                param.controlspec.maxval = next_val
              end
            elseif initializing == false then
              if envelope_control_type == "level" and env_nodes[i] then
                if (i ~= 1 and i ~= #envelopes[envelope_id].graph_nodes) then
                  env_nodes[i][envelope_control_type] = new_val
                end
              elseif env_nodes[i] then
                env_nodes[i][envelope_control_type] = new_val
              end
            end
            envelopes[envelope_id].graph:edit_graph(env_nodes)
            local num_envelope_controls = envelope_id == 1 and "num_envelope1_controls" or "num_envelope2_controls"
            local num_env_nodes = #envelopes[envelope_id].graph_nodes
            params:set(num_envelope_controls,num_env_nodes)
          end

        }
      end
    end
    
    
    for i=num_envelope_controls+1,MAX_ENVELOPE_NODES,1
    do
      params:hide(envelope_times[i])
      params:hide(envelope_levels[i])
      params:hide(envelope_curves[i])
    end
    params:hide(envelope_levels[1])
    params:hide(envelope_curves[1])
    params:hide(envelope_levels[num_envelope_controls])
  end



  -- init_envelope_controls(2)

  -- params:add_separator("env mod params")
  -- params:add{type = "option", id = "show_env_mod_params", name = "show env mod params",
  -- options = {"off","on"}, default = 1,
  -- action = function(x)
  --   if x == 1 then show_env_mod_params = false else show_env_mod_params = true end
  -- end}

  -- params:add_taper("randomize_env_probability1", "1: env mod probability", 0, 100, 100, 0, "%")
  -- params:add_taper("time_probability1", "1: time mod probability", 0, 100, 0, 0, "%")
  -- params:add_taper("level_probability1", "1: level mod probability", 0, 100, 0, 0, "%")
  -- params:add_taper("curve_probability1", "1: curve mod probability", 0, 100, 0, 0, "%")
  -- params:add_taper("time_modulation1", "1: time modulation", 0, params:get("envelope1_max_time"), 0, 0, "")
  -- params:add_taper("level_modulation1", "1: level modulation", 0, params:get("envelope1_max_level"), 0, 0, "")
  -- params:add_taper("curve_modulation1", "1: curve modulation", 0, 5, 0, 0, "")

  -- params:add_number("env_nav_active_control1", "1: env mod nav", 1, #env_mod_param_labels)
  -- params:set_action("env_nav_active_control1", function(x) 
  --   if initializing == false then
  --     envelopes[1].set_env_nav_active_control(x-envelopes[1].env_nav_active_control) 
  --   end
  -- end )

  -- params:add_taper("randomize_env_probability2", "2: env probability", 0, 100, 100, 0, "%")
  -- params:add_taper("time_probability2", "2: time probability", 0, 100, 0, 0, "%")
  -- params:add_taper("level_probability2", "2: level probability", 0, 100, 0, 0, "%")
  -- params:add_taper("curve_probability2", "2: curve probability", 0, 100, 0, 0, "%")
  -- params:add_taper("time_modulation2", "2: time modulation", 0, params:get("envelope1_max_time") * 0.1, 0, 0, "")
  -- params:add_taper("level_modulation2", "2: level modulation", 0, params:get("envelope1_max_level"), 0, 0, "")
  -- params:add_taper("curve_modulation2", "2: curve modulation", 0, 5, 0, 0, "")
  
  -- params:add_number("env_nav_active_control2", "2: env mod nav", 1, #env_mod_param_labels)
  -- params:set_action("env_nav_active_control2", function(x) 
  --   if initializing == false then
  --     envelopes[2].set_env_nav_active_control(x-envelopes[2].env_nav_active_control) 
  --   end  
  -- end )

  parameters.init_envelope_controls(1)

  params:add_separator("save_samples")
  params:add_trigger("set_", "save samples")
  params:set_action("set_", function(x)
    if Namesizer ~= nil then
      textentry.enter(pre_save,Namesizer.phonic_nonsense().."_"..Namesizer.phonic_nonsense())
    else
      textentry.enter(sample_recorder.save_samples)
    end
  end)

end

return parameters