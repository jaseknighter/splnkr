dmp = {}
-- local devices_midi_processor = {}
-- local dmp = devices_midi_processor

function dmp.init()
  dmp.voice_default = {
    pitch    = 1,
    velocity = 80,
    duration = 1/4,
    channel  = 1,
    repeats  = 0,
    repeat_freq = 1
  }

  for i=1,3,1 do
    dmp["voice"..i] = {}
    dmp["voice"..i].pitch = {}
    dmp["voice"..i].repeats = {}
    dmp["voice"..i].repeat_freq = {}
    dmp["voice"..i].duration = {}
    dmp["voice"..i].velocity = {}
    dmp["voice"..i].channel = {}
    for j=1,5,1 do
      dmp["voice"..i].pitch[j] = dmp.voice_default.pitch
      dmp["voice"..i].repeats[j] = dmp.voice_default.repeats
      dmp["voice"..i].repeat_freq[j] = dmp.voice_default.repeat_freq
      dmp["voice"..i].duration[j] = dmp.voice_default.duration
      dmp["voice"..i].velocity[j] = dmp.voice_default.velocity
      dmp["voice"..i].channel[j] = dmp.voice_default.channel
    end
  end

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

function dmp.process(output_table, subsequin_ix)
  local ssid = output_table.ssid
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  if output_table.value_heirarchy.mod < 4 then -- play_note
    local mod = output_table.value_heirarchy.mod
    local param = output_table.value_heirarchy.par
    -- dmp["voice"..mod].repeats = 0
    if param == 1 then -- update pitch
      dmp["voice"..mod].pitch[subsequin_ix] = value 
      clock.run(dmp.play_note,mod, ssid, subsequin_ix)
    elseif param == 2 then -- update note repeats
      dmp["voice"..mod].repeats[subsequin_ix] = value       
    elseif param == 3 then -- update note repeat frequency      
      value = NOTE_REPEAT_FREQUENCIES[value]
      local frac = string.find(value,"/")
      dmp["voice"..mod].repeat_freq[subsequin_ix] = frac and fn.fraction_to_decimal(value) or value
    elseif param == 4 then -- update duration
      local dur_tab = fn.get_table_from_string(MIDI_DURATIONS[value],"/")
      local duration = #dur_tab == 1 and dur_tab[1] or dur_tab[1]/dur_tab[2]
      dmp["voice"..mod].duration[subsequin_ix] = duration
    elseif param == 5 then -- update velocity
      dmp["voice"..mod].velocity[subsequin_ix] = math.floor(value)
    else -- update channel
      dmp["voice"..mod].channel[subsequin_ix] = value 
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
    dmp.stop_start(value)
  end
end

dmp.ratchet_pats = {}
function dmp.init_ratchet(ssid, ratchet_data)
  local active_ssid = sequencer_controller.get_active_sequinset_id()
  if active_ssid == ssid then 
    local lattice = sequencer_controller.lattice
    local next_pat_ix = #dmp.ratchet_pats+1
    dmp.ratchet_pats[next_pat_ix] = {}
    -- local ratchet_data = value_tab
    -- print("ratchet", ratchet_data.pitch, ratchet_data.repeats)
    dmp.ratchet_pats[next_pat_ix] = lattice:new_pattern({
      action = function()
        local pat = dmp.ratchet_pats[next_pat_ix]
        if active_ssid == ssid then
          pat.num_times_repeated = pat.num_times_repeated and pat.num_times_repeated + 1 or 0
          -- print(pat.ix,ratchet_data.repeats,pat.num_times_repeated)
          if ratchet_data.repeats - pat.num_times_repeated == 0 then
            pat:destroy()
          elseif ratchet_data.repeats > 1 then
            externals1.note_on(1,ratchet_data,1,1,"sequencer", "midi")
          end
        end
      end,
      division = ratchet_data.repeat_freq,
      enabled = true
    })
    dmp.ratchet_pats[next_pat_ix].ix = next_pat_ix
    -- dmp.ratchet_pats[next_pat_ix].ratchet_data = fn.deep_copy(ratchet_data)
  end

end

function dmp.play_note(mod, ssid,subsequin_ix)
  clock.sleep(0.0001)
  local value_tab = {
    pitch       = dmp["voice"..mod].pitch[subsequin_ix],
    velocity    = dmp["voice"..mod].velocity[subsequin_ix],
    duration    = dmp["voice"..mod].duration[subsequin_ix],
    channel     = dmp["voice"..mod].channel[subsequin_ix],
    repeats     = dmp["voice"..mod].repeats[subsequin_ix],
    repeat_freq = dmp["voice"..mod].repeat_freq[subsequin_ix],
    mode = 1
  }
  value_tab.repeats = type(value_tab.repeats) == 'number' and value_tab.repeats or 0

  if dmp["voice"..mod].repeats[subsequin_ix] > 0 then
    dmp.init_ratchet(ssid, value_tab)  
  end
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
