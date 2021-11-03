dmp = {}
-- local devices_midi_processor = {}
-- local dmp = devices_midi_processor

function dmp.init()
  dmp.voice1 = {
    pitch    = 1,
    velocity = 80,
    duration = 1/4,
    channel  = 1,
    repeats  = 0,
    repeat_freq = 1
  }
  dmp.voice2 = {
    pitch    = 1,
    velocity = 80,
    duration = 1/4,
    channel  = 1,
    repeats  = 0,
    repeat_freq = 1
  }
  dmp.voice3 = {
    pitch    = 1,
    velocity = 80,
    duration = 1/4,
    channel  = 1,
    repeats  = 0,
    repeat_freq = 1
  }
  dmp.cc1 = {
    cc = 1,
    value = 1,
    channel = 1
  }
  dmp.cc2 = {
    cc = 1,
    value = 1,
    channel = 1
  }
  dmp.cc3 = {
    cc = 1,
    value = 1,
    channel = 1
  }
  
end

function dmp.process(output_table)
  local ssid = output_table.ssid
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  if output_table.value_heirarchy.mod < 4 then -- play_note
    local mod = output_table.value_heirarchy.mod
    local param = output_table.value_heirarchy.par
    dmp["voice"..mod].repeats = 0
    if param == 1 then -- update pitch
      dmp["voice"..mod].pitch = value 
      clock.run(dmp.play_note,mod, ssid)
    elseif param == 2 then -- update note repeats
      dmp["voice"..mod].repeats = value       
    elseif param == 3 then -- update note repeat frequency      
      value = NOTE_REPEAT_FREQUENCIES[value]
      local frac = string.find(value,"/")
      dmp["voice"..mod].repeat_freq = frac and fn.fraction_to_decimal(value) or value
    elseif param == 4 then -- update duration
      local dur_tab = fn.get_table_from_string(MIDI_DURATIONS[value],"/")
      local duration = #dur_tab == 1 and dur_tab[1] or dur_tab[1]/dur_tab[2]
      dmp["voice"..mod].duration = duration
    elseif param == 5 then -- update velocity
      dmp["voice"..mod].velocity = math.floor(value)
    else -- update channel
      dmp["voice"..mod].channel = value 
    end
  elseif output_table.value_heirarchy.mod < 7 then -- cc val
    local mod = output_table.value_heirarchy.mod - 3
    local param = output_table.value_heirarchy.par
    if param == 1 then -- update channel
      dmp["cc"..mod].cc = value 
      dmp.set_cc(mod)
    elseif param == 2 then -- update value
      dmp["cc"..mod].value = value
      dmp.set_cc(mod)
    elseif param == 3 then -- update channel
      dmp["cc"..mod].channel = value 
      dmp.set_cc(mod)
    end
  elseif output_table.value_heirarchy.mod == 4 then -- stop/start
    -- dmp.stop_start = value
    dmp.stop_start(value)
  end
end

-- dmp.ratchet_pats = {}
-- dmp.ratchet_pat_data = {}
-- dmp.ratchet_pat_ix = 0

function dmp.init_ratchet(ssid, mod)
  print("init rachet")
  local active_ssid = sequencer_controller.get_active_sequinset_id()
  if active_ssid == ssid then 
    local lattice = sequencer_controller.lattice
    -- dmp.ratchet_pat_ix = dmp.ratchet_pat_ix + 1
    -- local pat = dmp.ratchet_pats[dmp.ratchet_pat_ix]
    local pat
    pat = lattice:new_pattern({
      action = function()
        local ratchet_data = {
          pitch       = dmp["voice"..mod].pitch,--fn.deep_copy(dmp["voice"..mod].pitch),
          velocity    = dmp["voice"..mod].velocity,--fn.deep_copy(dmp["voice"..mod].velocity),
          duration    = dmp["voice"..mod].duration,
          channel     = dmp["voice"..mod].channel,--fn.deep_copy(dmp["voice"..mod].channel),
          repeats     = dmp["voice"..mod].repeats,--fn.deep_copy(dmp["voice"..mod].repeats),
          repeat_freq = dmp["voice"..mod].repeat_freq,
          mode = 1
        }
        -- pat:set_division(dmp["voice"..mod].repeat_freq)
        -- print("run pat ratchet",ratchet_data.repeats, ratchet_data.repeat_freq, ratchet_data.pitch)
        if active_ssid == ssid then
                
          pat.num_times_repeated = pat.num_times_repeated and pat.num_times_repeated + 1 or 0
          if ratchet_data.repeats - pat.num_times_repeated == 0 then
            pat:destroy()
            -- print ("kill pat ratchet",pat)
          elseif ratchet_data.repeats > 1 then
            print("ratchet")
            externals1.note_on(1,ratchet_data,1,1,"sequencer", "midi")
          end
        end
      end,
      division = dmp["voice"..mod].repeat_freq,
      enabled = true
    })
    
        
  end

end

function dmp.play_note(mod, ssid)
  clock.sleep(0.0001)
  print("repeats", dmp["voice"..mod].repeats)
  if dmp["voice"..mod].repeats > 0 then
    dmp.init_ratchet(ssid, mod)  
  end
  local value_tab = {
    pitch     = dmp["voice"..mod].pitch,
    velocity  = dmp["voice"..mod].velocity,
    duration  = 1/4, --dmp["voice"..mod].duration,
    channel   = dmp["voice"..mod].channel,
    mode = 1
  }
  externals1.note_on(1,value_tab,1,1,"sequencer", "midi")
end

function dmp.set_cc(mod)
  local cc        = dmp["cc"..mod].cc
  local value     = dmp["cc"..mod].value
  local channel   = dmp["cc"..mod].channel

  externals1.set_midi_cc(cc,value,channel)
end


function dmp.end_note(value_tab)
  clock.sleep(0.001)
  -- print("end note")
  externals1.midi_note_off_beats(value_tab.duration,value_tab.pitch,value_tab.channel,1,value_tab.pitch)
end

function dmp.stop_start(val)
  local value_tab = {
    stop_start = val,
    mode = 2
  }
  externals1.note_on(1,value_tab,1,1,"sequencer", "midi")
end

return dmp
