local livsamp_processor = {}

livsamp_processor.controls = {}

function livsamp_processor.init()
  livsamp_processor.controls = {
    cutter = livsamp_processor.update_cutter_assignment,
    v_mode = livsamp_processor.update_voice_mode,
    rate = livsamp_processor.update_rate,
    direction = livsamp_processor.update_direction,
    level = livsamp_processor.update_level
  }
end

function livsamp_processor.process(output_table)
  local control_to_update = livsamp_processor.controls[output_table.control_id]
  local voice = output_table.value_heirarchy.out
  
  -- sub sequin gets called here--
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  control_to_update(voice,value) -- update control
end

function livsamp_processor.update_cutter_assignment(voice, cutter_assignment)
  voice = voice + 3
  if cutter_assignment > 0 then
    if spl.get_cutter_assignment(voice) ~= cutter_assignment then
      spl.set_cutter_assignment(voice, cutter_assignment)
      
      if spl.play_modes[voice] < 3 then
        spl.set_play_mode(voice, 3) -- TODO: move into a parameter
        spl.set_cutter_assignment(voice, cutter_assignment)
      end
    end
  else 
    spl.set_play_mode(spl.selected_voice, 0) -- TODO: move into a parameter
  end

end

function livsamp_processor.update_rate(voice, rate)
  voice = voice + 3
  spl.play_check(voice)
  spl.set_rate(voice,rate)
end

function livsamp_processor.update_voice_mode(voice, mode)
  voice = voice + 3
  spl.set_play_mode(voice,mode-1)
  if spl.play_modes[voice] == 4 then -- 1-shot
    local cutter_assignment = spl.get_cutter_assignment(voice) 
    spl.set_cutter_assignment(voice, cutter_assignment)
  end

end

function livsamp_processor.update_direction(voice, direction)
  voice = voice + 3
  spl.play_check(voice)
  direction = direction == 1 and -1 or 1
  spl.set_direction(voice,direction)
end

function livsamp_processor.update_level(voice, level)
  voice = voice + 3
  spl.play_check(voice)
  spl.set_level(voice,level)
end



return livsamp_processor