local devices_jf_processor = {}


function devices_jf_processor.init()
  -- devices_jf_processor.play_note_controls = {
  --   pitch = devices_jf_processor.play_voice_pitch,
  --   level = devices_jf_processor.play_voice_level,
  -- }
  -- devices_jf_processor.play_voice_controls = {
  --   channel = devices_jf_processor.play_voice_channel,
  --   pitch = devices_jf_processor.play_voice_pitch,
  --   level = devices_jf_processor.play_voice_level,
  -- }
  -- devices_jf_processor.portamento_controls = {
  --   pitch_portamento = devices_jf_processor.portamento_pitch,
  -- }
  devices_jf_processor.play_note_pitch      = 1
  devices_jf_processor.play_note_level      = 5
  devices_jf_processor.play_voice_channel   = 1  
  devices_jf_processor.play_voice_pitch     = 1
  devices_jf_processor.play_voice_level     = 5
  -- devices_jf_processor.repeats           = 5
  -- devices_jf_processor.repeat_freq       = 5
  devices_jf_processor.portamento           = 1    
end

function devices_jf_processor.process(output_table)
  
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  local control_to_update
  if output_table.value_heirarchy.mod == 1 then -- play_note
    -- control_to_update = devices_jf_processor.play_note_controls[output_table.control_id]
    local param = output_table.value_heirarchy.par
    if param == 1 then -- update pitch
      devices_jf_processor.play_note_pitch = value
    else -- update level
      devices_jf_processor.play_note_level = value
    end
    devices_jf_processor.play_note()
    --print("play_note",param, output_table.control_id, control_to_update,value)
  elseif output_table.value_heirarchy.mod > 1 then -- play_voice
    -- control_to_update = devices_jf_processor.play_voice_controls[output_table.control_id]
    local param = output_table.value_heirarchy.par
    --update channel
    local channel = output_table.value_heirarchy.mod - 1
    devices_jf_processor.play_voice_channel = channel
    if param == 1 then 
      devices_jf_processor.play_voice_pitch = value
    elseif param == 2 then -- update level
      devices_jf_processor.play_voice_level = value
    end
    devices_jf_processor.play_voice()
    --print("play_voice",param, output_table.control_id, control_to_update,value)
  elseif output_table.value_heirarchy.mod == 3 then -- play_portamento
    -- control_to_update = devices_jf_processor.portamento_controls[output_table.control_id]
    --print("portamento",output_table.control_id, control_to_update)
    devices_jf_processor.portamento = value
    devices_jf_processor.portamento()
  end
end

function devices_jf_processor.play_note()
  
  local value_tab = {
    pitch = devices_jf_processor.play_note_pitch,
    level = devices_jf_processor.play_note_level,
    mode = 1
  }
  externals1.note_on(1,value_tab,1,1,"sequencer", "jf")
end

function devices_jf_processor.play_voice()
  local value_tab = {
    channel = devices_jf_processor.play_voice_channel,
    pitch = devices_jf_processor.play_voice_pitch,
    level = devices_jf_processor.play_voice_level,
    mode = 2
  }
  externals1.note_on(1,value_tab,1,1,"sequencer", "jf")
end

function devices_jf_processor.portamento()
  local value_tab = {
    portamento = devices_jf_processor.portamento,
    mode = 3
  }
  externals1.note_on(1,value_tab,1,1,"sequencer", "jf")
end

return devices_jf_processor
