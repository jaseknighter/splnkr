local softcut_processor = {}

softcut_processor.controls = {}

function softcut_processor.init()
  softcut_processor.controls = {
    cutter = softcut_processor.assign_sample_to_cutter,
    mode = softcut_processor.update_mode,
    rate = softcut_processor.update_rate,
    direction = softcut_processor.update_direction,
    level = softcut_processor.update_level
  }
end

function softcut_processor.process(output_table)
  -- print("process softcut control_id, control_name:",output_table.control_id,output_table.control_name)
  -- tab.print(output_table)
  -- local voice = output_table.value_heirarchy
  -- tab.print(output_table.value_heirarchy)
  local control_to_update = softcut_processor.controls[output_table.control_id]
  local voice = output_table.value_heirarchy.out
  -- print("control_to_update, voice",control_to_update, voice)
  
  -- sub sequin gets called here--
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
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
--     -- print("sample_pattern1_event",start)  
--   end
-- end


function softcut_processor.assign_sample_to_cutter(voice, cutter_assignment)
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
    -- cutter_assignment = cutter_assignment
    

    -- print("call: set cut assignment", voice, cutter_assignment)
    -- TODO: move into a global function shared with code in encoders_and keys
    -- local d = 0 -- DIRECTION, DON'T NEED TO CHANGE HERE!!!!!
    -- cutters[sample_player.selected_cutter_group]:set_start_x(util.clamp(cutters[sample_player.selected_cutter_group]:get_start_x()+(d*1),0,cutters[sample_player.selected_cutter_group]:get_finish_x()))
    -- cutters[sample_player.selected_cutter_group]:set_finish_x(util.clamp(cutters[sample_player.selected_cutter_group]:get_finish_x()+(d*1),cutters[sample_player.selected_cutter_group]:get_start_x(), 128))
    -- sample_player.cutters_start_finish_update()
    -- sample_player.reset() 
    -- if sample_player.play_modes[sample_player.selected_voice] > 1 then 
    -- end 

    -- softcut.play(voice, 1)
  else 
    -- params:set("play_sequencer",1)
    -- for i=1,6,1 do
    sample_player.set_play_mode(sample_player.selected_voice, 0) -- TODO: move into a parameter
    -- end
  end

end

function softcut_processor.update_rate(voice, rate)
  sample_player.set_rate(voice,rate)
end

function softcut_processor.update_mode(voice, mode)
  -- print("update mode",voice, mode)
  -- direction = direction == 1 and -1 or 1
  sample_player.set_play_mode(voice,mode-1)
  -- sample_player.set_direction(voice,direction)
end

function softcut_processor.update_direction(voice, direction)
  direction = direction == 1 and -1 or 1
  sample_player.set_direction(voice,direction)
end

function softcut_processor.update_level(voice, level)
  sample_player.set_level(voice,level)
end



return softcut_processor