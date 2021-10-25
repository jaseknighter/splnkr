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
  -- print(value_tab.pitch,value_tab.velocity,value_tab.duration,value_tab.channel)

  -- tab.print(value_tab)
  externals1.note_on(1,value_tab,1,1,"sequencer", "midi")
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