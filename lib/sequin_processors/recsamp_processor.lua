local recsamp_processor = {}

recsamp_processor.controls = {}

function recsamp_processor.init()
  recsamp_processor.controls = {
    cutter = recsamp_processor.update_cutter_assignment,
    v_mode = recsamp_processor.update_voice_mode,
    rate = recsamp_processor.update_rate,
    direction = recsamp_processor.update_direction,
    level = recsamp_processor.update_level
  }
end

function recsamp_processor.process(output_table)
  local control_to_update = recsamp_processor.controls[output_table.control_id]
  local voice = output_table.value_heirarchy.out
  
  -- sub sequin gets called here--
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  --print("control_to_update, voice, value",control_to_update, voice, value)
  control_to_update(voice,value) -- update control
end

function recsamp_processor.update_cutter_assignment(voice, cutter_assignment)
  if cutter_assignment > 0 then
    if sample_player.get_cutter_assignment(voice) ~= cutter_assignment then
      sample_player.set_cutter_assignment(voice, cutter_assignment)      
      if sample_player.play_modes[voice] < 3 then
        sample_player.set_play_mode(voice, 3) -- TODO: move into a parameter
        sample_player.set_cutter_assignment(voice, cutter_assignment)
      end
    end
  else 
    sample_player.set_play_mode(sample_player.selected_voice, 0) -- TODO: move into a parameter
  end

end

function recsamp_processor.update_rate(voice, rate)
  sample_player.play_check(voice)
  sample_player.set_rate(voice,rate)
end

function recsamp_processor.update_voice_mode(voice, mode)
  sample_player.set_play_mode(voice,mode-1)
  if sample_player.play_modes[voice] == 4 then -- 1-shot
    local cutter_assignment = sample_player.get_cutter_assignment(voice) 
    sample_player.set_cutter_assignment(voice, cutter_assignment)
  end

end

function recsamp_processor.update_direction(voice, direction)
  sample_player.play_check(voice)
  direction = direction == 1 and -1 or 1
  sample_player.set_direction(voice,direction)
end

function recsamp_processor.update_level(voice, level)
  sample_player.play_check(voice)
  sample_player.set_level(voice,level)
end



return recsamp_processor