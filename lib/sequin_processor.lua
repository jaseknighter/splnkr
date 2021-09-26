local sequin_processor = {}

sequin_processor.processors = {
  softcut_processor,
  devices_processor, 
  effects_processor,
  enveloper_processor,
  pattern_processor,
  lattice_processor
}

function sequin_processor.init()
  softcut_processor.init()
end

function sequin_processor.process(sequin_to_process)
  if(#sequin_to_process.active_outputs)>0 then
    -- print("process sequin for active sequin group",sequencer_controller.get_active_sequin_groups())
    sequin_processor.find_outputs(sequin_to_process.active_outputs,sequin_to_process.id)
  end
end

function sequin_processor.find_outputs(output_table, sequin_id)
  if sequin_id then
    for k, v in pairs(output_table) do 
      -- print("find outputs", k,v)
      if k == "output_data" then
        local selected_sequin = v.value_heirarchy.sqn
        if selected_sequin == sequin_id then
          local selected_sequin_output_group = sequencer_controller.get_active_sequin_groups()
          local sequin_output_group = v.value_heirarchy.sgp
          local sequin_output_type  = v.value_heirarchy.typ
          local sequin_output_type_processor = sequin_processor.processors[sequin_output_type]
          if selected_sequin_output_group == sequin_output_group then
            if sequin_output_type_processor then
              local process_mode = string.find(v.value,"r") == nil and "absolute" or "relative"
              if process_mode == "absolute" then 
                sequin_output_type_processor.process(v)
              else
                local active_output_values = sequencer_controller.get_active_output_values()
                
                -- find the last occurrance of an absolute value
                local previous_absolute_value = 0
                local previous_absolute_value_index = 1
                for i=selected_sequin-1,1,-1 do
                  if (active_output_values and active_output_values[i] and active_output_values[i][1] ~= nil and active_output_values[i][1] ~= "nil") and string.find(active_output_values[i][1],"r") == nil then
                    previous_absolute_value = active_output_values[i][1]
                    previous_absolute_value_index = i
                    break
                  end
                end

                -- starting from the previous absolute value (or the start of the output values table),
                -- figure out the current relative value to output
                local calculated_absolute_value = previous_absolute_value
                for i=previous_absolute_value_index,selected_sequin,1 do
                  if active_output_values[i][1] then
                    local val
                    if string.find(active_output_values[i][1],"r") then
                      local number_end = string.find(active_output_values[i][1],"r") - 1
                      val = string.sub(active_output_values[i][1],1,number_end)
                      calculated_absolute_value = calculated_absolute_value + tonumber(val)
                    end
                  end
                end
                v.calculated_absolute_value = calculated_absolute_value
                -- provide relative value and calculated absolute value ()
                sequin_output_type_processor.process(v)
              end
            else 
              print("ERROR, can't find processor for sequin output type", sequin_output_type)
            end
          end
        else
          -- print("didn't find matching id",sequin_id, selected_sequin)
        end
      elseif type(v) == "table" then
        sequin_processor.find_outputs(v, sequin_id)
      end
    end
  end
  -- sequin_processor.processors[]
end

return sequin_processor