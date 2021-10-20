local dmp = {}
-- local devices_midi_processor = {}
-- local dmp = devices_midi_processor

function dmp.init()
  dmp.voice1 = {
    pitch    = 1,
    velocity = 80,
    channel  = 1,  
  }
  dmp.voice2 = {
    pitch    = 1,
    velocity = 80,
    channel  = 1,  
  }
  dmp.voice3 = {
    pitch    = 1,
    velocity = 80,
    channel  = 1,  
  }
  
end

function dmp.process(output_table)
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  if output_table.value_heirarchy.mod < 4 then -- play_note
    local mod = output_table.value_heirarchy.mod
    local param = output_table.value_heirarchy.par
    -- print("process",mod,param)
    -- print("pitch",dmp["voice"..mod].pitch,value)
    if param == 1 then -- update pitch
      dmp["voice"..mod].pitch = value 
      local value_tab = {
        channel   = dmp["voice"..mod].channel,
        pitch     = dmp["voice"..mod].pitch,
        velocity  = dmp["voice"..mod].velocity,
        mode = 1
    
      }
    
      clock.run(dmp.play_note,value_tab)
    elseif param == 2 then -- update velocity
      -- print("velocity",value)
      dmp["voice"..mod].velocity = math.floor(value)
    else -- update channel
      dmp["voice"..mod].channel = value 
    end
  elseif output_table.value_heirarchy.mod == 4 then -- stop/start
    dmp.stop_start = value
    dmp.stop_start()
  end
end

function dmp.play_note(value_tab)
  clock.sleep(0.001)
  -- tab.print(value_tab)
  externals1.note_on(1,value_tab,1,1,"sequencer", "midi")
end

function dmp.end_note(value_tab)
  clock.sleep(0.001)
  -- tab.print(value_tab)
  externals1.note_off(1,value_tab,1,1,"sequencer", "midi")
end

function dmp.stop_start()
  local value_tab = {
    stop_start = dmp.stop_start,
    mode = 2
  }
  externals1.note_on(1,value_tab,1,1,"sequencer", "midi")
end

return dmp


-- externals1.note_on(1,60,1,1,1,"engine")dp process