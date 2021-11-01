local dmp = {}
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
  -- tab.print(output_table)
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  if output_table.value_heirarchy.mod < 4 then -- play_note
    local mod = output_table.value_heirarchy.mod
    local param = output_table.value_heirarchy.par
    if param == 1 then -- update pitch
      dmp["voice"..mod].pitch = value 
      clock.run(dmp.play_note,mod)
    elseif param == 2 then -- update note repeats
      dmp["voice"..mod].repeats = value       
    elseif param == 3 then -- update note repeat frequency      
      dmp["voice"..mod].repeat_freq = value 
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

function dmp.repeat_note(repeat_data)
  local sync_time = tonumber(repeat_data.repeat_freq)
  clock.sync(sync_time)
  local value_tab = {
    pitch     = repeat_data.pitch,
    velocity  = repeat_data.velocity,
    duration  = repeat_data.duration,
    channel   = repeat_data.channel,
    mode = 1
  }
  externals1.note_on(1,value_tab,1,1,"sequencer", "midi")
  if repeat_data.repeats >= 1 then
    repeat_data.repeats = repeat_data.repeats - 1
    clock.run(dmp.repeat_note,repeat_data)
  end

end

function dmp.play_note(mod)
  clock.sleep(0.0001)
  if dmp["voice"..mod].repeats > 0 then
    local repeat_freq = NOTE_REPEAT_FREQUENCIES[dmp["voice"..mod].repeat_freq]
    repeat_freq = fn.fraction_to_decimal(repeat_freq)
    local repeat_data = {
      pitch     = fn.deep_copy(dmp["voice"..mod].pitch),
      velocity  = fn.deep_copy(dmp["voice"..mod].velocity),
      duration  = fn.deep_copy(tonumber(dmp["voice"..mod].duration)),
      channel   = fn.deep_copy(dmp["voice"..mod].channel),
      repeats   = fn.deep_copy(dmp["voice"..mod].repeats),
      repeat_freq   = fn.deep_copy(tonumber(repeat_freq)),
      mode = 1
    }
    clock.run(dmp.repeat_note,repeat_data)
    
  end
  local value_tab = {
    pitch     = dmp["voice"..mod].pitch,
    velocity  = dmp["voice"..mod].velocity,
    duration  = tonumber(dmp["voice"..mod].duration),
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
