local softcut_processor = {}

softcut_processor.controls = {}

function softcut_processor.init()
  softcut_processor.controls = {
    cutter = softcut_processor.update_cutter_assignment,
    v_mode = softcut_processor.update_voice_mode,
    rate = softcut_processor.update_rate,
    direction = softcut_processor.update_direction,
    level = softcut_processor.update_level
  }
end

function softcut_processor.process(output_table)
  --print("process softcut control_id, control_name:",output_table.control_id,output_table.control_name)
  -- tab.print(output_table)
  -- local voice = output_table.value_heirarchy
  -- tab.print(output_table.value_heirarchy)
  local control_to_update = softcut_processor.controls[output_table.control_id]
  local voice = output_table.value_heirarchy.out
  
  -- sub sequin gets called here--
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  --print("control_to_update, voice, value",control_to_update, voice, value)
  control_to_update(voice,value) -- update control
end

-- function sample_pattern1_event()
  -- params:set("play_sequencer",2)
--   if params:get("play_sequencer") == 2 then 
--     -- softcut.loop (1, 0)
--     local seq_num = seq1()
--     -- local start = ((seq_num-1)*20)+(120 + math.random(2))
--     -- local start = ((seq_num-1)*5)+((ur_position*length))
--     local start = seq_num
--     sample_pattern1.division = 1/(seq_num*2)
--     softcut.loop_start(1,start)
--     softcut.loop_end(1,start + (0.3))
--     softcut.play(1, 1)
--     --print("sample_pattern1_event",start)  
--   end
-- end


function softcut_processor.update_cutter_assignment(voice, cutter_assignment)
  -- if cutter_assignment > 0 and params:get("play_sequencer") == 2 then
  if cutter_assignment > 0 then
    -- if params:get("play_sequencer") ~= 2  then
    if sample_player.get_cutter_assignment(voice) ~= cutter_assignment then
      -- params:set("play_sequencer", 2)
      sample_player.set_cutter_assignment(voice, cutter_assignment)
      -- sample_player.selected_cutter_group = cutter_assignment
      
      if sample_player.play_modes[voice] < 3 then
        sample_player.set_play_mode(voice, 3) -- TODO: move into a parameter
        sample_player.set_cutter_assignment(voice, cutter_assignment)
      end
    end
  else 
    sample_player.set_play_mode(sample_player.selected_voice, 0) -- TODO: move into a parameter
  end

end

function softcut_processor.update_rate(voice, rate)
  sample_player.play_check(voice)
  sample_player.set_rate(voice,rate)
end

function softcut_processor.update_voice_mode(voice, mode)
  sample_player.set_play_mode(voice,mode-1)
  if sample_player.play_modes[voice] == 4 then -- 1-shot
    print("1-shot")
    local cutter_assignment = sample_player.get_cutter_assignment(voice) 
    sample_player.set_cutter_assignment(voice, cutter_assignment)
  end

end

function softcut_processor.update_direction(voice, direction)
  sample_player.play_check(voice)
  direction = direction == 1 and -1 or 1
  sample_player.set_direction(voice,direction)
end

function softcut_processor.update_level(voice, level)
  sample_player.play_check(voice)
  sample_player.set_level(voice,level)
end



return softcut_processor