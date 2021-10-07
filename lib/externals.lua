-- external sounds and outputs

local externals = {}
externals.__index = externals

function externals:new(active_notes)
  local ext = {}
  ext.index = 1
  setmetatable(ext, externals)

  


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
    --   print("note location is out of bounds!!!", note_location, #active_notes)
    end
    midi_out_device:note_off(note_num, nil, channel)
  end
 
  ext.note_on = function(voice_id, note_to_play, pitch_frequency, beat_frequency, envelope_time_remaining, note_source, note_target)
    -- print("note_on:",voice_id, note_to_play, pitch_frequency, beat_frequency, envelope_time_remaining, note_source)
    -- local output_bandsaw = params:get("output_bandsaw")
    local note_offset = params:get("note_center_frequency") - root_note_default
    note_to_play = notes[note_to_play+note_offset]
    if note_to_play == nil then
      -- print("no note to play")
      return
    end
    -- print("note_to_play",note_to_play)
    
    local output_midi = params:get("output_midi")

    local output_crow1 = params:get("output_crow1")
    local output_crow3 = params:get("output_crow3")
    local output_crow2 = params:get("output_crow2")
    local output_crow4 = params:get("output_crow4")
    
    local output_jf = params:get("output_jf")
    local jf_mode = params:get("jf_mode")
    -- local midi_thru_jf = params:get("midi_thru_jf")

    local output_wsyn = params:get("output_wsyn")
    local output_wdel_ks = params:get("output_wdel_ks")
    
    local midi_out_channel = voice_id == 1 and midi_out_channel1 or midi_out_channel2
    -- local envelope_length = envelopes[voice_id].get_env_time()
    local envelope_length = envelopes[1].get_env_time()

    -- MIDI out
    -- if (note_source == "engine" and output_bandsaw == 4) or output_midi > 1 then
    if (note_source == "engine" and (output_midi == 2 or output_midi == 4)) or
      (note_source == "midi" and (output_midi == 3 or output_midi == 4))  then
      local level = voice_id == 1 and params:get("envelope1_max_level") or params:get("envelope2_max_level")
      level = math.floor(util.linlin(0,10,0,127,level))
      midi_out_device:note_on(note_to_play, level, midi_out_channel)
      table.insert(active_notes, note_to_play)
      -- Note off timeout
      local note_duration_param = voice_id == 1 and "voice_1_note_duration" or "voice_2_note_duration"
      clock.run(ext.midi_note_off, envelope_length, note_to_play, midi_out_channel, voice_id, #active_notes)
    end
    
    -- crow out
    local asl_generator = function(env_length)
      local envelope_data = envelopes[1].get_envelope_arrays()
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
      -- print(asl_envelope)
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
    -- voice_id, note_to_play, pitch_frequency, beat_frequency, envelope_time_remaining, note_source
    if (voice_id == 1 and 
        (
          (
            ( note_source == "sequencer" and note_target == "crow") or 
              note_source == "engine"
          ) and 
          (output_crow1 == 2 or output_crow1 == 3 or output_crow1 == 4)
      )) or
      (note_source == "midi" and (output_crow1 == 4 or output_crow1 == 5)
    ) then
    -- if output_crow > 1 then
    local volts
    if note_source == "engine" then
      volts = (note_to_play-60)/12
    else
      -- volts = note_to_play/12
      volts = (note_to_play-60)/12
    end
    
    crow.output[1].volts = volts

    local output_param = params:get("output_crow2")
    if output_param == 2 then -- envelope
      local asl_envelope = asl_generator(envelopes[1].get_env_time())
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
      crow.output[2].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
    end
    if output_param > 1 then crow.output[2]() end
  end


    -- if (voice_id == 2 and (note_source == "engine" and (output_crow3 == 2 or output_crow3 == 4))) or
    -- (note_source == "midi" and (output_crow3 == 3 or output_crow3 == 4)) then

    if (voice_id == 3 and 
          (
            (
              ( note_source == "sequencer" and note_target == "crow") or 
                note_source == "engine"
            ) and 
            (output_crow1 == 2 or output_crow3 == 3 or output_crow3 == 4)
        )) or
        (note_source == "midi" and (output_crow3 == 4 or output_crow3 == 5)
    ) then
      local volts
      if note_source == "engine" then
        volts = (note_to_play-60)/12
      else
        -- volts = note_to_play/12
        volts = (note_to_play-60)/12
      end
      
      crow.output[3].volts = volts

      local output_param = params:get("output_crow2")
      if output_param == 2 then -- envelope
        local asl_envelope = asl_generator(envelopes[1].get_env_time())
        crow.output[4].action = tostring(asl_envelope)
      elseif output_param == 3 then -- trigger
        local time = 0.01 --crow_trigger_2
        local level = params:get("envelope1_max_level")
        local polarity = 1
        crow.output[4].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
      elseif output_param == 4 then -- gate
        local num_env_controls = params:get("num_envelope1_controls")
        local time = envelopes[1].get_envelope_arrays().times[num_env_controls]
        -- local time = params:get("envelope1_max_time")
        local level = params:get("envelope1_max_level")
        local polarity = 1
        crow.output[4].action = "pulse(" .. time ..",".. level .. "," .. polarity .. ")"
      end
      if output_param > 1 then crow.output[4]() end
    end  

    if (note_source == "sequencer" and note_target == "crow_drum") and 
       (output_crow1 == 2 or output_crow3 == 3 or output_crow3 == 4) then
        -- crow.output[1].action = "oscillate(440,5,'sine')"
        crow.output[1].action = "oscillate(" .. note_to_play .. "+ dyn{freq=" .. 800 .. "}:mul(" .. 0.8 .. "), dyn{lev=" .. 5 .. "}:mul(" .. 0.98 .. ") )"
        crow.output[1].execute()
    end
          
    -- just friends out
    
    if (note_source == "engine" and (output_jf == 2 or output_jf == 4)) or
    (note_source == "midi" and (output_jf == 3 or output_jf == 4)) then
      if jf_mode == 1 then
        if voice_id == 1 then
          local level = params:get("envelope1_max_level") 
          crow.ii.jf.play_voice(1,(note_to_play-60)/12,level)
        else
          local level = params:get("envelope2_max_level") 
          crow.ii.jf.play_voice(2,(note_to_play-60)/12,level)
        end
      else
        local level = params:get("envelope1_max_level") 
        -- print("jfjfjfjf", jf_mode, voice_id,level,note_to_play)
        crow.ii.jf.play_note((note_to_play-60)/12,level)
      end
    end
    
    -- wsyn out
    if (note_source == "engine" and (output_wsyn == 2 or output_wsyn == 4)) or
      (note_source == "midi" and (output_wsyn == 3 or output_wsyn == 4)) then
        local pitch = (note_to_play-48)/12
        local velocity = active_voice == 1 and params:get("envelope1_max_level") or params:get("envelope2_max_level") 
        if voice_id == 1 then
        params:set("wsyn_init",1)
        local voice = 1
        crow.send("ii.wsyn.play_voice(" .. voice .."," .. pitch .."," .. velocity .. ")")
      else
        local voice = 2
        crow.send("ii.wsyn.play_voice(" .. voice .."," .. pitch .."," .. velocity .. ")")
      end
    end

      -- wdel karplus-strong out
    if ((note_source == "engine" and (output_wdel_ks == 2 or output_wdel_ks == 3 or output_wdel_ks > 4)) or
      (note_source == "midi" and (output_wdel_ks > 3 ))) then
      local pitch = (note_to_play-48)/12
      local level = voice_id == 1 and params:get("envelope1_max_level") or params:get("envelope2_max_level") 
      crow.send("ii.wdel.pluck(" .. level .. ")")
      crow.send("ii.wdel.freq(" .. pitch .. ")")
      params:set("wdel_rate",0)
    end

    -- divide 1 over beat_frequency to translate from hertz (cycles per second) into beats per second
    if envelope_length > 1/beat_frequency then
      local time_remaining = envelope_time_remaining and envelope_time_remaining - 1/beat_frequency or envelope_length - 1/beat_frequency 
      if time_remaining > 1/beat_frequency then
        clock.sleep(1/beat_frequency)
        -- print(envelope_length,beat_frequency,time_remaining,1/beat_frequency)
        -- clock.run(ext.note_on, voice_id, note_to_play, pitch_frequency, beat_frequency, time_remaining, note_source)
      end
    end
  end
  return ext
end

return externals
