-- external sounds and outputs

local externals = {}
externals.__index = externals

function externals:new(active_notes)
  local ext = {}
  ext.index = 1
  setmetatable(ext, externals)

  

  function ext.set_midi_cc(cc,value,channel)
    -- print("cc",cc,value,channel)
    midi_out_device:cc (cc, value, channel)
  end

  ext.midi_note_off = function(delay, note_num, channel, voice_id, note_location)
    local note_off_delay
    if voice_id == 1 then
      note_off_delay = midi_out_envelope_override1 or delay
    elseif voice_id == 2 then
      note_off_delay = midi_out_envelope_override2 or delay
    end
    clock.sleep(note_off_delay)
    if note_location <= #active_notes then
      table.remove(active_notes, note_location)
    else
    --print("note location is out of bounds!!!", note_location, #active_notes)
    end
    midi_out_device:note_off(note_num, nil, channel)
  end

  ext.midi_note_off_beats = function(delay, note_num, channel, voice_id, note_location)
    clock.sync(delay)
    if note_location <= #active_notes then
      table.remove(active_notes, note_location)
    else
    --print("note location is out of bounds!!!", note_location, #active_notes)
    end
    midi_out_device:note_off(note_num, nil, channel)
  end

  -- externals1.note_on(1, note_num, 1, 1, nil,"engine")
  ext.note_on = function(voice_id, value, beat_frequency, envelope_time_remaining, note_source, note_target)
    -- local note_offset = params:get("note_center_frequency") - params:get("root_note")
    local value = fn.deep_copy(value)
    -- if type(value) == "table" then
      -- hack!!! figure out when notes[value.pitch+note_offset] would be nil
      -- if note_source ~= "engine" and notes[value.pitch+note_offset] then
      --   value.pitch = notes[value.pitch+note_offset]
      -- end
    -- else
      -- value = notes[value+note_offset]
    -- end
    
    local output_midi = params:get("output_midi")

    local output_crow1 = params:get("output_crow1")
    local output_crow2 = params:get("output_crow2")
    local output_crow3 = params:get("output_crow3")
    local output_crow4 = params:get("output_crow4")
    
    local output_jf = params:get("output_jf")
    local jf_mode = params:get("jf_mode")
    -- local midi_thru_jf = params:get("midi_thru_jf")

    local output_wsyn = params:get("output_wsyn")
    local output_wdel_ks = params:get("output_wdel_ks")
    
    -- local midi_out_channel = voice_id == 1 and midi_out_channel1 or midi_out_channel2
    local envelope_length = envelopes[voice_id].get_env_time()
    -- local envelope_length = envelopes[1].get_env_time()

    -- MIDI out
    -- midi out (sequencer)
    if (note_target == "midi") then
      -- if (output_jf ~= 2 and output_jf ~= 4) then params:set("output_jf",2) end
      local mode = value.mode
      if mode == 1 then -- play_voice
        local channel = value.channel
        local pitch = value.pitch
        local velocity = value.velocity
        local duration = value.duration 
        duration = tonumber(duration) and duration or fn.fraction_to_decimal(duration)      
        midi_out_device:note_on(pitch, velocity, channel)
        table.insert(active_notes, pitch)
        -- print("duration",duration)
        clock.run(ext.midi_note_off_beats, duration, pitch, channel, 1, #active_notes)
      elseif mode == 2 then -- stop/start
        if value.stop_start == 1 then -- stop
          midi_out_device:stop()
        else -- start
          midi_out_device:start()
        end
      end
    end
    


    -- crow out
    local asl_generator = function(env_length, env_id)
      local envelope_data = envelopes[env_id].get_envelope_arrays()
      local asl_envelope = ""
      for i=2, envelope_data.segments, 1
      do
        local to_env 
        if envelope_data.curves[i] > 0 then to_env = 'exponential'
        elseif envelope_data.curves[i] < 0 then to_env = 'logarithmic'
        else to_env = 'linear'
        end
        
        local to_string =  "to(" .. 
                           (envelope_data.levels[i]) .. "," ..
                           (envelope_data.times[i]-envelope_data.times[i-1]) .. 
                           "," .. to_env .. 
                           "),"
                           asl_envelope = asl_envelope .. to_string

        if i == envelope_data.segments then
          local to_string = "to(" .. 
                            (envelope_data.levels[i]) .. "," ..
                            (env_length-envelope_data.times[i]) .. 
                            "," .. to_env .. 
                            "),"
                            asl_envelope = asl_envelope .. to_string
        end
      end
    
      asl_envelope = "{" .. asl_envelope .. "}"
      --print(asl_envelope)
      return asl_envelope 
    end

    -- clock out check
    if output_crow1 == 5 then 
      crow.output[1]:execute() 
    elseif output_crow2 == 5 then 
      crow.output[2]:execute() 
    elseif output_crow3 == 5 then 
      crow.output[3]:execute() 
    elseif output_crow4 == 5 then 
      crow.output[4]:execute() 
    end

    -- note, trigger, envelope, gate check
    -- voice_id, value, pitch_frequency, beat_frequency, envelope_time_remaining, note_source
    if (voice_id == 1 and 
        ((note_target == "crow" and (note_source == "sequencer" or note_source == "engine")) 
          and 
         (output_crow1 == 2 or output_crow3 == 3 or output_crow3 == 4)) or
        (note_source == "midi" and (output_crow3 == 4 or output_crow3 == 5))
    ) then
      local volts
      local mode = value.mode
      -- if note_source == "engine" and value then
      if note_source == "engine" and value.pitch then
        volts = (value.pitch-60)/12
      elseif mode == 1 and value.pitch then -- play_voice
          local pitch = value.pitch
          volts = pitch/12
      elseif note_source =="midi" then
        volts = (value.pitch-60)/12
      else 
        print("NO CROW VOLTS VALUE VALUE: externals ~166")
      end
      
      crow.output[1].volts = volts
      local output_param = params:get("output_crow2")
      if output_param == 2 then -- envelope
        local asl_envelope = asl_generator(envelopes[1].get_env_time(),1)
        crow.output[2].action = tostring(asl_envelope)
      elseif output_param == 3 then -- trigger
        local time = 0.01 --crow_trigger_2
        local level = params:get("envelope1_max_level")
        local polarity = 1
        crow.output[2].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
      elseif output_param == 4 then -- gate
        local num_env_controls = params:get("num_envelope1_controls")
        local time = envelopes[1].get_envelope_arrays().times[num_env_controls]
        -- local time = params:get("envelope1_max_time")
        local level = params:get("envelope1_max_level")
        local polarity = 1
        if (time and level and polarity) then 
          crow.output[2].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
        end
      end
      if output_param > 1 then crow.output[2]() end
      crow.output[1].execute()

    end


    -- if (voice_id == 2 and (note_source == "engine" and (output_crow3 == 2 or output_crow3 == 4))) or
    -- (note_source == "midi" and (output_crow3 == 3 or output_crow3 == 4)) then

    if (voice_id == 2 and 
    ((note_target == "crow" and ( note_source == "sequencer" or note_source == "engine")) 
      and 
     (output_crow1 == 2 or output_crow3 == 3 or output_crow3 == 4)) or
    (note_source == "midi" and (output_crow3 == 4 or output_crow3 == 5))
    ) then
      local volts
      local mode = value.mode
      if note_source == "engine" and value then
        volts = (value-60)/12
      elseif mode == 1 and value.pitch then -- play_voice
          local pitch = value.pitch
          volts = pitch/12
      else 
        print("NO CROW VOLTS VALUE VALUE: externals 166")
      end
      
      crow.output[3].volts = volts
      local output_param = params:get("output_crow4")
      if output_param == 2 then -- envelope
        local asl_envelope = asl_generator(envelopes[2].get_env_time(),2)
        crow.output[4].action = tostring(asl_envelope)
      elseif output_param == 3 then -- trigger
        local time = 0.01 --crow_trigger_2
        local level = params:get("envelope1_max_level")
        local polarity = 1
        crow.output[4].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
      elseif output_param == 4 then -- gate
        local num_env_controls = params:get("num_envelope1_controls")
        local time = envelopes[2].get_envelope_arrays().times[num_env_controls]
        -- local time = params:get("envelope1_max_time")
        local level = params:get("envelope1_max_level")
        local polarity = 1
        if (time and level and polarity) then 
          crow.output[4].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
        end
      end
      if output_param > 1 then crow.output[4]() end
      crow.output[3].execute()

    end

    if (note_source == "sequencer" and note_target == "crow_drum") and 
       (output_crow1 == 2 or output_crow3 == 3 or output_crow3 == 4) then
        -- crow.output[1].action = "oscillate(440,5,'sine')"
        crow.output[1].action = "oscillate(" .. value .. "+ dyn{freq=" .. 800 .. "}:mul(" .. 0.8 .. "), dyn{lev=" .. 5 .. "}:mul(" .. 0.98 .. ") )"
        crow.output[1].execute()
    end
          
    -- just friends out (engine)
    if (note_source == "engine" and note_target == "jf" and (output_jf == 2 or output_jf == 4)) or
    (note_source == "midi" and (output_jf == 3 or output_jf == 4)) then
      if jf_mode == 1 then
        if voice_id == 1 then
          local level = params:get("envelope1_max_level") 
          crow.ii.jf.play_voice(1,(value-60)/12,level)
        else
          local level = params:get("envelope2_max_level") 
          crow.ii.jf.play_voice(2,(value-60)/12,level)
        end
      else
        local level = params:get("envelope1_max_level") 
        crow.ii.jf.play_note((value-60)/12,level)
      end
    end
    
    -- just friends out (sequencer)
    if (note_source == "sequencer" and note_target == "jf") then
      if (output_jf ~= 2 and output_jf ~= 4) then params:set("output_jf",2) end
      
      mode = value.mode
      if mode == 1 then -- play_note
        local pitch = value.pitch
        local level = value.level
        crow.ii.jf.play_note((pitch-60)/12,level)
      elseif mode == 2 then -- play_voice
        local channel = value.channel
        local pitch = value.pitch
        local level = value.level
        crow.ii.jf.play_voice(channel,(pitch-60)/12,level)
      else
        crow.ii.jf.pitch(1,(value-60)/12)
      end
    end

    -- wsyn out
    if (note_source == "engine" and (output_wsyn == 2 or output_wsyn == 4)) or
      (note_source == "midi" and (output_wsyn == 3 or output_wsyn == 4)) then
      local pitch = (value-48)/12
      local velocity = active_voice == 1 and params:get("envelope1_max_level") or params:get("envelope2_max_level") 
      params:set("wsyn_init",1)
      if voice_id == 1 then
        local voice = 1
        crow.send("ii.wsyn.play_voice(" .. voice .."," .. pitch .."," .. velocity .. ")")
      else
        local voice = 2
        crow.send("ii.wsyn.play_voice(" .. voice .."," .. pitch .."," .. velocity .. ")")
      end
    end

    -- wsyn out (sequencer)
    if (note_source == "sequencer" and  note_target == "wsyn") then
      if value then
        local pitch = (value-60)/12
        local velocity = params:get("envelope1_max_level") 
        -- params:set("wsyn_init",1)
        local voice = voice_id
        crow.send("ii.wsyn.play_voice(" .. voice .."," .. pitch .."," .. velocity .. ")")
      else
        print("ERROR externals.lua, value not defined externals.lua line 271")
      end
    end

      -- wdel karplus-strong out
    if ((note_source == "engine" and (output_wdel_ks == 2 or output_wdel_ks == 3 or output_wdel_ks > 4)) or
      (note_source == "midi" and (output_wdel_ks > 3 ))) then
      local pitch = (value-48)/12
      local level = voice_id == 1 and params:get("envelope1_max_level") or params:get("envelope2_max_level") 
      crow.send("ii.wdel.pluck(" .. level .. ")")
      crow.send("ii.wdel.freq(" .. pitch .. ")")
      params:set("wdel_rate",0)
    end

    if (note_source == "sequencer" and  note_target == "wdel_ks") then

      if params:get("output_wdel_ks") ~= 2 then
        params:set("output_wdel_ks",2)
      end
      local pitch = (value-60)/12
      -- local level = voice_id == 1 and params:get("envelope1_max_level") or params:get("envelope2_max_level") 
      local level = params:get("envelope1_max_level") 
      crow.send("ii.wdel.pluck(" .. level .. ")")
      crow.send("ii.wdel.freq(" .. pitch .. ")")
      params:set("wdel_rate",0)
    end


    -- divide 1 over beat_frequency to translate from hertz (cycles per second) into beats per second
    
    if envelope_length > 1/beat_frequency then
      local time_remaining = envelope_time_remaining and envelope_time_remaining - 1/beat_frequency or envelope_length - 1/beat_frequency 
      if time_remaining > 1/beat_frequency then
        clock.sleep(1/beat_frequency)
      end
    end
  end
  return ext
end

return externals
