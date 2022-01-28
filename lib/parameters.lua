
local parameters = {}

function parameters.init()
  save_load.init()

  params:add_separator("RECORD PLAYER")
  params:add_trigger("set_", "record player")
  params:set_action("set_", function(x)
    if Namesizer ~= nil then
      textentry.enter(pre_save,Namesizer.phonic_nonsense().."_"..Namesizer.phonic_nonsense())
    else
      textentry.enter(sample_recorder.save_samples)
    end
  end)

    --------------------------------
  -- note params
  -- scale: the scale to use
  -- scale length: the number of notes in the scale, centered around the `note_offset`
  -- root note: the lowest note in the scale
  -- note_offset: the note to use as "1" in the sequencer
  --------------------------------

  function parameters.update_note_offset()
    local offset = params:lookup_param("note_offset")
    local offset_options = {}
    for k,v in pairs(notes) do 
      if v then
        table.insert(offset_options,MusicUtil.note_num_to_name(v,true))
      end
    end
    offset.options = offset_options
    offset.count = #offset_options
  end

  params:add_separator("SCALES, NOTES, AND TEMPO")
  -- params:add_group("scales and notes",5)

  local max_notes = fn.get_num_notes_per_octave() and fn.get_num_notes_per_octave() * 5 or SCALE_LENGTH_DEFAULT
  
  params:add{type = "number", id = "scale_length", name = "scale length",
    min = 1, max = max_notes, default = ROOT_NOTE_DEFAULT, 
    action = function(val) 
      fn.build_scale() 
      parameters.update_note_offset()
      local sl = params:lookup_param("scale_length")
      sl.maxval = fn.get_num_notes_per_octave() * 5
  end}

  params:hide("scale_length")

  params:add{type = "option", id = "scale_mode", name = "scale mode",
    options = scale_names, default = 5,
    action = function() 
      fn.build_scale() 
      if initializing == false then 
        parameters.update_note_offset()
        sc.set_sequin_output_value_controls() 
      end
  end}

  
  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = ROOT_NOTE_DEFAULT, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function() 
      fn.build_scale() 
      parameters.update_note_offset()
  end}

  params:add{type = "number", id = "note_offset", name = "note offset",
  min = -24, max = 24, default = 0, 
  action = function() 
    fn.build_scale() 
    parameters.update_note_offset()
end}

params:hide("note_offset")


  -- latice meter
  params:add{
    type = "option", id = "meter", name = "sequencer meter", default=4,
    options=TIME_OPTIONS,
    action=function(x)
      if initializing == false and sequencer_controller.selected_sequin_group then
        sequencer_controller.lattice:set_meter(fn.fraction_to_decimal(TIME_OPTIONS[x]))
      end
    end
  }

    -- pattern division for the selected sequencer (aka sequin group)
    params:add{
      type = "option", id = "division", name = "sequencer divisions", default=6,
      options=TIME_OPTIONS,
      action=function(x)
        if initializing == false and sequencer_controller.selected_sequin_group then
          local pattern = sequencer_controller.sequencers[sequencer_controller.selected_sequin_group].pattern
          pattern:set_division(fn.fraction_to_decimal(TIME_OPTIONS[x]))
        end
      end
    }
  

  ------------------------------
    -- audio routing params
    ------------------------------

  params:add_separator("AUDIO ROUTING")

  rerouting_audio = false

  function route_audio()
    clock.sleep(0.5)
    local selected_route = params:get("audio_routing")
    if rerouting_audio == true then
      rerouting_audio = false
      if selected_route == 1 then -- audio in + softcut output -> supercollider
        os.execute("jack_connect crone:output_5 SuperCollider:in_1;")  
        os.execute("jack_connect crone:output_6 SuperCollider:in_2;")
        os.execute("jack_connect softcut:output_1 SuperCollider:in_1;")  
        os.execute("jack_connect softcut:output_2 SuperCollider:in_2;")      
      elseif selected_route == 2 then --just audio in -> supercollider
        os.execute("jack_disconnect softcut:output_1 SuperCollider:in_1;")  
        os.execute("jack_disconnect softcut:output_2 SuperCollider:in_2;")
        os.execute("jack_connect crone:output_5 SuperCollider:in_1;")  
        os.execute("jack_connect crone:output_6 SuperCollider:in_2;")
      elseif selected_route == 3 then -- just softcut output -> supercollider
        os.execute("jack_disconnect crone:output_5 SuperCollider:in_1;")  
        os.execute("jack_disconnect crone:output_6 SuperCollider:in_2;")
        os.execute("jack_connect softcut:output_1 SuperCollider:in_1;")  
        os.execute("jack_connect softcut:output_2 SuperCollider:in_2;")        
      end
    end
  end

  params:add{
    type = "option", id = "audio_routing", name = "audio routing", 
    options = {"in+cut->eng","in->eng","cut->eng"},
    -- min = 1, max = 3, 
    default = 2,
    action = function(value) 
      rerouting_audio = true
      clock.run(route_audio)
    end
  }
  ------------------------------
  -- amplitude/frequency detection params
  ------------------------------
  params:add_separator("AMP/FREQ DETECTIOn")
  params:add_group("amp/freq detection",20)
  -- set the amplitude detection level
  params:add_separator("detection level/freq")
  params:add{
    type = "option", id = "quantize_freq", name = "quantize freq", 
    options = {"off","on"}, default = 2, 
  }

  -- midi detection
  params:add_separator("midi detection")
  
  params:add{
    type = "option", id = "detected_freq_to_midi", name = "freq to midi", 
    options = {"off","on"}, default = 1, 
  }

  params:add{
    type="taper", id = "amp_detect_level_midi_min", name = "min midi amp level",min=0.001, max=0.5, default = 0.01,
    action=function(x) 
    end
  }

  params:add{
    type="taper", id = "amp_detect_level_midi_max", name = "max midi amp level",min=0.001, max=0.5, default = 0.2,
    action=function(x) 
    end
  }


  params:add{
    type = "number", id = "detected_freq_to_midi_out_channel", name = "midi channel", 
    min=1,max=16,default=1, 
  }

  params:add{type = "number", id = "min_midi_note_num", name = "min midi note num",
  min = 0, max = 127, default = ROOT_NOTE_DEFAULT,
  }
  params:add{type = "number", id = "max_midi_note_num", name = "max midi note num",
  min = 0, max = 127, default = 127-ROOT_NOTE_DEFAULT,
  }
  
  -- crowdetection
  params:add_separator("crow detection")
  
  params:add{
    type = "option", id = "detected_freq_to_crow1", name = "freq to crow1", 
    options = {"off","on"}, default = 1, 
  }

  params:add{
    type = "option", id = "detected_freq_to_crow3", name = "freq to crow3", 
    options = {"off","on"}, default = 1, 
  }

  params:add{
    type="taper", id = "amp_detect_level_min_crow2", name = "min amp level crow 1/2",min=0.001, max=0.5, default = 0.01,
    action=function(x) 
    end
  }

  params:add{
    type="taper", id = "amp_detect_level_max_crow2", name = "max amp level crow 1/2",min=0.001, max=0.5, default = 0.2,
    action=function(x) 
    end
  }


  params:add{type = "number", id = "min_crow1_note_num", name = "min crow 1 note num",
  min = 0, max = 127, default = ROOT_NOTE_DEFAULT,
  }
  params:add{type = "number", id = "max_crow1_note_num", name = "max crow 1 note num",
  min = 0, max = 127, default = 127-ROOT_NOTE_DEFAULT,
  }

  params:add{
    type="taper", id = "amp_detect_level_min_crow4", name = "min amp level crow 3/4",min=0.001, max=0.5, default = 0.01,
    action=function(x) 
    end
  }

  params:add{
    type="taper", id = "amp_detect_level_max_crow4", name = "max amp level crow 3/4",min=0.001, max=0.5, default = 0.2,
    action=function(x) 
    end
  }

  
  params:add{type = "number", id = "min_crow3_note_num", name = "min crow 3 note num",
  min = 0, max = 127, default = ROOT_NOTE_DEFAULT,
  }
  params:add{type = "number", id = "max_crow3_note_num", name = "max crow 3 note num",
  min = 0, max = 127, default = 127-ROOT_NOTE_DEFAULT,
  }
  -- params:add_group("amp detection",2)
  -- parameters.create_amp_freq_params(amp_params)
  -- params:add_group("freq detection",2)
  -- parameters.create_amp_freq_params(freq_params)




  ------------------------------
  -- sequencing
  ------------------------------
  if g.cols and g.cols >= 16 then 
    params:add_separator("SEQUENCING")
    params:add_group("sequencing",6)
    
    params:add{
      type = "number", id = "step_size", name = "step size", min=1, max=8, default=1,
      action=function(x)
        if initializing == false and sequencer_controller.selected_sequin_group then
          local seq = sequencer_controller.sequencers[sequencer_controller.selected_sequin_group].seq
          seq:step(x)
        end
      end
    }

    params:add{
      type = "number", id = "num_steps", name = "num steps", min=1, max=9, default=9,
      action=function(x)
        if initializing == false then
          local starting_step = 5+params:get("starting_step")
          local last_sequin = starting_step+x-1
          last_sequin = last_sequin <= 14 and last_sequin or 14
          sequencer_controller.sequin_selector = grid_sequencer:register_ui_group("sequin_selector",starting_step,1,last_sequin,1,2,3)
        end
      end
    }
    
    params:add{
      type = "number", id = "starting_step", name = "starting step", min=1, max=9, default=1,
      action=function(x)
        if initializing == false then
          for i=1,9,1 do
            sequencer_controller.update_sequin_selector(5+i,1,"off")
            grid_sequencer:solid_off(5+i,1, 1)
            grid_sequencer:unregister_solid_at(5+i,1, 1)
          end
          local starting_step = 5+x
          local last_sequin = 5+x+params:get("num_steps")
          last_sequin = last_sequin <= 14 and last_sequin or 14
          -- for i=6,14,1 do
          --   if grid_sequencer:find_ui_group_num_by_xy(i,1) then
          --     sc:unregister_ui_group(i,1)
          --   end
          -- end
          sequencer_controller.sequin_selector = grid_sequencer:register_ui_group("sequin_selector",starting_step,1,last_sequin,1,2,3)
          
          local num_steps = params:get("num_steps")
          -- num_steps = util.clamp(1,9-x+1,num_steps)
          params:set("num_steps",num_steps+1)
          params:set("num_steps",num_steps)
        end
      end
    }

    params:add{
      type = "number", id = "sub_step_size", name = "sub step size", min=1, max=4, default=1,
      action=function(x)
        if initializing == false and sequencer_controller.selected_sequin_group then
          local seq = sequencer_controller.sequencers[sequencer_controller.selected_sequin_group].sub_seq_leader
          seq:step(x)
        end
      end
    }

    params:add{
      type = "number", id = "num_sub_steps", name = "num sub steps", min=1, max=5, default=5,
      action=function(x)
        if initializing == false and sequencer_controller.sequin_output_values then
          -- local selected_sequin = selected_sub_sequin_ix and selected_sub_sequin_ix or 1
          for i=x,5,1 do
            -- sequencer_controller.update_sequin_selector(5+selected_sequin,8,"off")
            sequencer_controller.update_sequin_output_value(5+i,8,"off")
            grid_sequencer:unregister_solid_at(5+i,8, 1)
            grid_sequencer:solid_off(5+i,8, 1)
          end
          local starting_step = 5+params:get("starting_sub_step")
          local last_sequin = starting_step+x-1
          -- last_sequin = last_sequin <= 10 and last_sequin or 10
          -- for i=6,10,1 do
          --   if grid_sequencer:find_ui_group_num_by_xy(i,8) then
          --     sc:unregister_ui_group(i,8)
          --   end
          -- end
          
          -- sequencer_controller.sequin_selector = grid_sequencer:register_ui_group("sequin_selector",starting_step,1,last_sequin,1,2,3)
          sequencer_controller.sequin_output_values = grid_sequencer:register_ui_group("sequin_output_values",starting_step,8,last_sequin,8,5,3)
          -- num_sub_steps = last_sequin - starting_step + 1
        end
      end
    }

    params:add{
      type = "number", id = "starting_sub_step", name = "starting sub step", min=1, max=5, default=1,
      action=function(x)
        if initializing == false then
          for i=1,5,1 do
            sequencer_controller.update_sequin_output_value(5+i,8,"off")
            grid_sequencer:solid_off(5+i,8, 1)
            grid_sequencer:unregister_solid_at(5+i,8, 1)
          end
          local starting_step = 5+x
          local last_sequin = 5+x+params:get("num_sub_steps")
          -- last_sequin = last_sequin <= 10 and last_sequin or 10
          -- for i=6,10,1 do
          --   if grid_sequencer:find_ui_group_num_by_xy(i,8) then
          --     sc:unregister_ui_group(i,8)
          --   end
          -- end
          
          sequencer_controller.sequin_output_values = grid_sequencer:register_ui_group("sequin_output_values",starting_step,8,last_sequin,8,5,3)
          
          local num_sub_steps = params:get("num_sub_steps")
          -- num_sub_steps = util.clamp(1,5-x+1,num_sub_steps)
          params:set("num_sub_steps",num_sub_steps+1)
          params:set("num_sub_steps",num_sub_steps)
        end
      end
    }
  end
  




  

  ------------------------------
  -- filter params
  ------------------------------


  params:add_separator("FILTERS")

  -- filter level
  params:add_group("filter levels",16)

  local filter_levelgrid_view = 1
  -- cs_level = controlspec.AMP:copy()
  -- cs_level.maxval = 5
  for i=1,16,1 do
    params:add_control("filter_level"..i,"filter level"..i,cs_level)
    -- local default_val = i<8 and (i%8) or (i<16 and 9-(i%8) or 0)
    local default_val = 0
    default_val = util.linlin(1,9,0,cs_level.maxval,default_val)
    params:set("filter_level"..i,default_val, false)
    params:set_action("filter_level"..i,function(x) 
      -- update engine
        engine.set_filter_level(i-1,x)

      -- update grid
      if grid_filter and grid_filter.last_known_height then
        local j = i
        local l =math.floor(util.linlin(cs_level.minval,cs_level.maxval,8,1,x))
        grid_filter.solids[filter_levelgrid_view][j] = {}
        for k=7,l,-1
        do
          grid_filter:register_solid_at(j, k, l, filter_levelgrid_view)
        end
      end
    end)  
  end

  -- reciprocal quality
  params:add_group("reciprocal quality",16)
  local filter_rqgrid_view = 2
  cs_rq = controlspec.AMP:copy()
  for i=1,16,1 do
    params:add_control("reciprocal_quality"..i,"reciprocal q"..i,cs_rq)
    local default_val = 1
    params:set("reciprocal_quality"..i,default_val)
    params:set_action("reciprocal_quality"..i,function(x) 
      if x <= 0 and initializing == false then 
        x = 0.1
        params:set("reciprocal_quality"..i,0.1, false)
      end
        engine.set_reciprocal_quality(i-1,x)

        -- update grid
      if grid_filter.last_known_height then
          local j = i
        local l =math.floor(util.linlin(cs_rq.minval,cs_rq.maxval,1,8,x))

        grid_filter.solids[filter_rqgrid_view][j] = {}
        for k=7,l,-1
        do
          grid_filter:register_solid_at(j, k, l, filter_rqgrid_view)
        end
      end
    end)  
  end

  -- center frequency
  params:add_group("center frequency",16)
  local filter_cfgrid_view = 3
  cs_cf = controlspec.MIDFREQ:copy()
  cs_cf.maxval = 9600
  for i=1,16,1 do
    params:add_control("filter_center_frequency"..i,"center freq"..i,cs_cf)
    params:set_action("filter_center_frequency"..i,function(x) 
      -- update engine
      engine.set_center_frequency(i-1,x)

      -- update grid
      if grid_filter.last_known_height then
        local j = i
        -- local l =math.floor(util.linexp(cs_cf.minval,cs_cf.maxval,8,1,x))
        local l = 
          x < 50 and 8 or
          x < 100 and 7 or 
          x < 200 and 6 or 
          x < 300 and 5 or
          x < 400 and 4 or
          x < 600 and 3 or
          x < 900 and 2 or
          1

        grid_filter.solids[filter_cfgrid_view][j] = {}
        for k=7,l,-1
        do
          grid_filter:register_solid_at(j, k, l, filter_cfgrid_view)
        end
      end
    end)  
    local c_freq = util.linexp(20,cs_cf.maxval,20,cs_cf.maxval,(i/16)*cs_cf.maxval)
    params:set("filter_center_frequency"..i, c_freq, false)
  end

  ------------------------------
  -- effect params
  ------------------------------
  params:add_separator("EFFECTS")

  params:add_group("effects",21)

  AMP_SPEC = controlspec.def{
    min=0.0,
    max=10.0,
    warp='linear',
    step=0.1,
    default=1,
    quantum=0.01,
    wrap=false,
    -- units='khz'
  }

  DELAY_SPEC = controlspec.def{
    min=0.0,
    max=5.0,
    warp='linear',
    step=0.01,
    default=1,
    quantum=0.001,
    wrap=false,
    -- units='khz'
  }

  BITCRUSH_RATE_SPEC = controlspec.def{
    min=100,
    max=10000,
    warp='log',
    -- step=1,
    default=1000,
    -- quantum=1,
    wrap=false,
    -- units='khz'
  }

  TRIG_SPEC = controlspec.def{
    min=-0.0,
    max=50.0,
    warp='linear',
    step=0.1,
    default=5,
    quantum=0.001,
    wrap=false,
    -- units='khz'
  }
  
  local effect_params = {
    -- {vinyl,vinyl,0,10,0,engine.vinyl}
    -- effect_name,effect_id,effect_min,effect_max,effect_default, effect_fn, effect_type

    {"drywet","drywet",0,1,1,engine.drywet,"control",},
    {"effects amp","amp",0,10,1,engine.amp,"control",},
    -- {"phaser","phaser",0,1,0,engine.phaser,"control",},
    {"delay","delay",0,1,0,engine.delay,"control",},
    {"  delay time","delay_time",0,5,0.25,engine.delaytime,"control",},
    {"  delay decay","delay_decay",0,5,4.0,engine.delaydecaytime,"control",},
    {"  delay amp","delay_amp",0,5,1,engine.delaymul,"control",},
    {"bitcrush","bitcrush",0,1,0,engine.bitcrush,"control",},
    {"  bitcrush bits","bitcrush_bits",1,16,8,engine.bitcrush,"number",},
    {"  bitcrush rate","bitcrush_rate",100,48000,1000,engine.bitcrush,"control",},
    -- {"strobe","strobe",0,1,0,engine.strobe,"control",},
    -- {"flutter and wow","flutter_and_wow",0,1,0,engine.flutter_and_wow,"control",},
    {"enveloper","enveloper",1,2,1,engine.enveloper,"option",{"off","on"},},
    {"  trig rate","trig_rate",1,20,5,engine.trig_rate,"number",},
    {"  overlap","overlap",0.01,0.99,0.99,engine.overlap,"control",},
    -- {"pan_type","pan type",0,1,0,engine.pan_type,"number",},
    -- {"pan_max","pan max",0,1,0.5,engine.pan_max,"control",},
    {"pitchshift","pitchshift",0,1,0,engine.pitchshift,"control",},
    {"   pitchshift freq","pitchshift_freq",1,50,1,engine.pitch_shift_trigger_frequency,"number",},
    {"   pitchshift note1","pitchshift_note1",-params:get("scale_length"),params:get("scale_length"),0,engine.pitchshift_note1,"number",},
    {"   pitchshift note2","pitchshift_note2",-params:get("scale_length"),params:get("scale_length"),0,engine.pitchshift_note2,"number",},
    {"   pitchshift note3","pitchshift_note3",-params:get("scale_length"),params:get("scale_length"),0,engine.pitchshift_note3,"number",},
    {"   pitchshift note4","pitchshift_note4",-params:get("scale_length"),params:get("scale_length"),0,engine.pitchshift_note4,"number",},
    {"   pitchshift note5","pitchshift_note5",-params:get("scale_length"),params:get("scale_length"),0,engine.pitchshift_note5,"number",},
    {"   grain size","grain_size","0.1",1,0.1,engine.grain_size,"control",},
    {"   time dispersion","time_dispersion","0.01",1,0.01,engine.time_dispersion,"control",},
  }

  function parameters.add_effect_param(effect_name,effect_id,effect_min,effect_max,effect_default, effect_fn, effect_type, effect_options)
    if effect_id == "amp" then
      params:add_control(effect_id,effect_name,AMP_SPEC)
      params:set_action(effect_id,function(x) 
        effect_fn(x)
      end)
    elseif effect_id == "bitcrush" then
      params:add{
        type = effect_type, id = effect_id, name = effect_name, default = effect_default,
        min=effect_min,max=effect_max, options=effect_options,
        action = function(x) 
          if initializing == false then
            local args = {x, params:get("bitcrush_bits"), params:get("bitcrush_rate")}
            effect_fn(table.unpack(args))
          end
        end
      }
    elseif effect_id == "bitcrush_bits" then
      params:add{
        type = effect_type, id = effect_id, name = effect_name, default = effect_default,
        min=effect_min,max=effect_max, options=effect_options,
        action = function(x) 
          if initializing == false then
            local args = {params:get("bitcrush"), x, params:get("bitcrush_rate")}
            effect_fn(table.unpack(args))
          end
        end
      }
    elseif effect_id == "bitcrush_rate" then
      params:add_control(effect_id,effect_name,BITCRUSH_RATE_SPEC)
      params:set_action(effect_id,function(x) 
        if initializing == false then
          local args = {params:get("bitcrush"), params:get("bitcrush_bits"), x}
          effect_fn(table.unpack(args))
        end
      end)
    elseif effect_id == "delay_time" or effect_id == "delay_decay" or effect_id == "delay_amp" then
        params:add_control(effect_id,effect_name,DELAY_SPEC)
        params:set_action(effect_id,function(x) 
          effect_fn(x)
        end)
    elseif effect_id == "pitchshift" or effect_id == "grain_size" or effect_id == "time_dispersion" then
      params:add{
        type = effect_type, id = effect_id, name = effect_name, default = effect_default,
        min=effect_min,max=effect_max, options=effect_options,
        action = function(x) 
          if initializing == false then
            if effect_id == "pitchshift" then
              engine.grain_size(params:get("grain_size"))  
              engine.time_dispersion(params:get("time_dispersion"))  
              engine.splnk(1)
              effect_fn(x)
            elseif effect_id == "grain_size" then
              engine.pitchshift(params:get("pitchshift"))  
              local td = params:get("time_dispersion")
              engine.time_dispersion(td)  
              if x < td then 
                params:set("grain_size",td)
              else
                engine.splnk(1)
                effect_fn(x)
              end
            elseif effect_id == "time_dispersion" then
              engine.pitchshift(params:get("pitchshift"))  
              engine.grain_size(params:get("grain_size"))  
              local gs = params:get("grain_size")
              engine.grain_size(gs)  
              if x > gs then 
                params:set("time_dispersion",gs)
              else
                engine.splnk(1)
                effect_fn(x)
              end
            end
            for i=1,5,1 do 
              engine["pitchshift_note" .. i](params:get("pitchshift_note" .. i)) 
            end
          end
        end
      }
    elseif effect_id ~= "trig_rate" and effect_type ~= "option" then
      params:add{
        type = effect_type, id = effect_id, name = effect_name, default = effect_default,
        min=effect_min,max=effect_max,
        action = function(x) 
          effect_fn(x)
        end
      }
    elseif effect_id == "trig_rate" then
      params:add_control(effect_id,effect_name,TRIG_SPEC)
      params:set_action(effect_id,function(x) 
        effect_fn(x)
      end)
    else
      params:add{
        type = effect_type, id = effect_id, name = effect_name, default = effect_default,
        min=effect_min,max=effect_max, options=effect_options,
        action = function(x) 
          x = x - 1
          effect_fn(x)
        end
      }
    end
    params:set(effect_id,effect_default)
  end


  -- for i=1,10,1
  for i=1,#effect_params,1
  do
    parameters.add_effect_param(
    effect_params[i][1],
    effect_params[i][2],
    effect_params[i][3],
    effect_params[i][4],
    effect_params[i][5],
    effect_params[i][6],
    effect_params[i][7],
    effect_params[i][8])
  end

  
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

  params:add_group("midi",11)

  -- params:add{type = "option", id = "midi_engine_control", name = "midi engine control",
  --   options = {"off","on"},
  --   default = 2,
  --   -- action = function(value)
  --   -- end
  -- }

  local midi_devices = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}

  params:add_separator("midi in")

  midi_in_device = {}
  params:add{
    type = "option", id = "midi_in_device", name = "in device", options = midi_devices, 
    min = 1, max = 16, default = 1, 
    action = function(value)
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
    options = {"off","sequencer", "midi", "sequencer + midi"},
    default = 2,
  }

  params:add{
    type = "option", id = "midi_out_device", name = "out device", options = midi_devices,
    default = 1,
    action = function(value) 
      midi_out_device = midi.connect(value) 
    end
  }

  params:add{
    type = "option", id = "midi_note1_mode", name = "midi note 1 mode", 
    options = {"quant","unquant"},
    default = 1,
    action = function(value) 
      if initializing == false then
        sequencer_controller.refresh_output_control_specs_map()
      end
    end
  }

  params:add{
    type = "option", id = "midi_note2_mode", name = "midi note 2 mode", 
    options = {"quant","unquant"},
    default = 1,
    action = function(value) 
      if initializing == false then
        sequencer_controller.refresh_output_control_specs_map()
      end
    end
  }

  params:add{
    type = "option", id = "midi_note3_mode", name = "midi note 3 mode", 
    options = {"quant","unquant"},
    default = 1,
    action = function(value) 
      if initializing == false then
        sequencer_controller.refresh_output_control_specs_map()
      end
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
    options = {"off","engine", "sequencer", "midi", "engine + midi", "clock"},
    default = 3,
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
    options = {"off","engine", "sequencer", "midi", "clock"},
    default = 3,
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
    default = 1,
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


  params:add_group("w/syn",13)
  w_slash.wsyn_add_params()
  -- w_slash.wsyn_v2_add_params()

  params:add_group("w/del",15)
  w_slash.wdel_add_params()

  params:add_group("w/tape",17)
  w_slash.wtape_add_params()



  --------------------------------
  -- envelope parameters
  --------------------------------
  
  -- params:add_group("envelopes",2+(num_envelopes*(MAX_ENVELOPE_NODES*3)))
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

    -- local time_param = params:lookup_param("time_modulation"..envelope_id)
    -- time_param.max = params:get("envelope"..envelope_id.."_max_time") * 0.1
    -- local level_param = params:lookup_param("level_modulation"..envelope_id)
    -- level_param.max = params:get("envelope"..envelope_id.."_max_level") * 0.1
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
    envelopes[envelope_id].update_envelope()
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
      end
      reset_envelope_control_params(envelope_id)
    end
    
    local num_envelope_controls = envelope_id == 1 and "num_envelope1_controls" or "num_envelope2_controls"
    local num_env_nodes = #envelopes[envelope_id].graph_nodes
    params:set(num_envelope_controls,num_env_nodes)
  end

  local ENV_LEVEL = cs.new(0.0,MAX_AMPLITUDE,'lin',0,AMPLITUDE_DEFAULT,'')
  local ENV_TIME = cs.new(0.0,MAX_ENV_LENGTH,'lin',0,ENV_TIME_MAX,'')

  parameters.init_envelope_controls = function(envelope_id)
    local num_envelope_controls = envelopes[envelope_id].get_envelope_arrays().segments 
    local envelope_times = envelope_id == 1 and envelope1_times or envelope2_times
    local envelope_levels = envelope_id == 1 and envelope1_levels or envelope2_levels
    local envelope_curves = envelope_id == 1 and envelope1_curves or envelope2_curves
    
    
    params:add{
      type="control",
      id = envelope_id == 1 and "envelope1_max_level" or "envelope2_max_level",
      name = envelope_id == 1 and "envelope 1 max level" or "envelope 2 max level",
      controlspec=ENV_LEVEL,
      action=function(x) 
        if initializing == false then envelopes[envelope_id].set_env_level(x) end
        screen_dirty = true
      end
    }
  
    params:add{
      type="control",
      id = envelope_id == 1 and "envelope1_max_time" or "envelope2_max_time",
      name = envelope_id == 1 and "envelope 1 max time" or "envelope 2 max time",
      controlspec=ENV_TIME,
      action=function(x) 
        if initializing == false then envelopes[envelope_id].set_env_time(x) end
        screen_dirty = true
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
            if envelopes[envelope_id].active_node == i then
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
              reset_envelope_control_params(envelope_id)
              params:set(num_envelope_controls,num_env_nodes)
            end
            screen_dirty = true
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
  
  
    params:add_separator("env mod params")
    params:add{type = "option", id = "show_env_mod_params", name = "show env mod params",
    options = {"off","on"}, default = 1,
    action = function(x)
      if x == 1 then show_env_mod_params = false else show_env_mod_params = true end
    end}


    if envelope_id == 1 then 
      params:add_taper("randomize_env_probability1", "1: env mod probability", 0, 100, 100, 0, "%")
      params:add_taper("time_probability1", "1: time mod probability", 0, 100, 0, 0, "%")
      params:add_taper("level_probability1", "1: level mod probability", 0, 100, 0, 0, "%")
      params:add_taper("curve_probability1", "1: curve mod probability", 0, 100, 0, 0, "%")
      params:add_taper("time_modulation1", "1: time modulation", 0, params:get("envelope1_max_time"), 0, 0, "")
      params:add_taper("level_modulation1", "1: level modulation", 0, params:get("envelope1_max_level"), 0, 0, "")
      params:add_taper("curve_modulation1", "1: curve modulation", 0, 5, 0, 0, "")

      params:add_number("env_nav_active_control1", "1: env mod nav", 1, #env_mod_param_labels)
      params:set_action("env_nav_active_control1", function(x) 
        if initializing == false then
          envelopes[1].set_env_nav_active_control(x-envelopes[1].env_nav_active_control) 
        end
      end )
    else
      params:add_taper("randomize_env_probability2", "2: env probability", 0, 100, 100, 0, "%")
      params:add_taper("time_probability2", "2: time probability", 0, 100, 0, 0, "%")
      params:add_taper("level_probability2", "2: level probability", 0, 100, 0, 0, "%")
      params:add_taper("curve_probability2", "2: curve probability", 0, 100, 0, 0, "%")
      params:add_taper("time_modulation2", "2: time modulation", 0, params:get("envelope2_max_time") * 0.1, 0, 0, "")
      params:add_taper("level_modulation2", "2: level modulation", 0, params:get("envelope2_max_level"), 0, 0, "")
      params:add_taper("curve_modulation2", "2: curve modulation", 0, 5, 0, 0, "")
      
      params:add_number("env_nav_active_control2", "2: env mod nav", 1, #env_mod_param_labels)
      params:set_action("env_nav_active_control2", function(x) 
        if initializing == false then
          envelopes[2].set_env_nav_active_control(x-envelopes[2].env_nav_active_control) 
        end  
      end )
    end  
  end

  -- params:add_separator("ENVELOPE CONTROLS")
  parameters.init_envelope_controls(1)
  parameters.init_envelope_controls(2)

end

return parameters