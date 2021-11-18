polling = {}

function polling.init()
  ----------------------------
  
  -- Init polls
  --detected_level, detected_freq, note_num
  local last_note_num = 0

  amplitude_detect_poll = poll.set("amplitudeDetect", function(value)
    detected_level = fn.round_decimals(value,5,"up")
    if detected_level > 0.0002
    then 
      -- print("amplitudeDetect,detected_freq",tonumber(detected_level),detected_freq) 
    end
  end)

  last_onset_amplitude = nil
  last_onset_frequency = nil

  onset_amplitude_detect_poll = poll.set("onsetAmplitudeDetect", function(value)
    if initializing == false then
      detected_level = fn.round_decimals(value,5,"up")
      if (detected_level and last_onset_amplitude and last_onset_frequency) and (last_onset_amplitude < detected_level or math.abs(last_onset_frequency - detected_freq) > 5)
      then 
        local note_offset = params:get("note_offset") - params:get("root_note")
        note_num = MusicUtil.freq_to_note_num (detected_freq) + note_offset 

      
        if params:get("quantize_freq") == 2 then
          -- local quantized_note = fn.quantize(note_num)
          -- print("note_num, quantized_note",note_num, quantized_note)
          note_num = fn.quantize(note_num)
        end

        if note_num and params:get("detected_freq_to_midi") == 2 and 
           note_num >= params:get("min_midi_note_num") and 
           note_num <= params:get("max_midi_note_num") and 
           detected_level >= params:get("amp_detect_level_midi_min") and 
           detected_level <= params:get("amp_detect_level_midi_max") then
          local value_tab = {
            pitch     = note_num,
            velocity  = util.linlin(0,0.05,1,127,detected_level),
            duration  = params:get("envelope1_max_time"), --1/4,
            channel   = params:get("detected_freq_to_midi_out_channel"),
            mode = 1
          }      
          clock.run(externals1.note_on,1, value_tab, 1, 1,"engine","midi")
        end

        if note_num and params:get("detected_freq_to_crow1") == 2 and 
           note_num >= params:get("min_crow1_note_num") and 
           note_num <= params:get("max_crow1_note_num") and
           detected_level >= params:get("amp_detect_level_min_crow2") and 
           detected_level <= params:get("amp_detect_level_max_crow2") then
          local value_tab = {
            pitch     = note_num,
          }      
          clock.run(externals1.note_on,1, value_tab, 1, 1,"engine","crow")
        end

        if note_num and params:get("detected_freq_to_crow3") == 2 and 
           note_num >= params:get("min_crow3_note_num") and 
           note_num <= params:get("max_crow3_note_num") and
           detected_level >= params:get("amp_detect_level_min_crow4") and 
           detected_level <= params:get("amp_detect_level_max_crow4") then
          local value_tab = {
            pitch     = note_num,
          }      
          clock.run(externals1.note_on,2, value_tab, 1, 1,"engine","crow")
        end

      end
      last_onset_amplitude = detected_level
      last_onset_frequency = detected_freq
    end
  end)
  
  frequency_detect_poll = poll.set("frequencyDetect", function(value)
    value = tonumber(value)
    detected_freq = value
  end)
  
end

return polling