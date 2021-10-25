local dmp = {}
-- local devices_midi_processor = {}
-- local dmp = devices_midi_processor

function dmp.init()
  dmp.voice1 = {
    pitch    = 1,
    velocity = 80,
    duration = 1/4,
    channel  = 1,
  }
  dmp.voice2 = {
    pitch    = 1,
    velocity = 80,
    duration = 1/4,
    channel  = 1,
  }
  dmp.voice3 = {
    pitch    = 1,
    velocity = 80,
    duration = 1/4,
    channel  = 1,
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
    elseif param == 2 then -- update velocity
      dmp["voice"..mod].velocity = math.floor(value)
    elseif param == 3 then -- update duration
      local dur_tab = fn.get_table_from_string(MIDI_DURATIONS[value],"/")
      local duration = #dur_tab == 1 and dur_tab[1] or dur_tab[1]/dur_tab[2]
      dmp["voice"..mod].duration = duration
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

function dmp.play_note(mod)
  clock.sleep(0.0001)
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
  -- tab.print(value_tab)
  print("end note")
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


-- externals1.note_on(1,60,1,1,1,"engine")dp process