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
    -- print("process sequin for active sequin group",sequencer_controller.get_active_sequinset())
    sequin_processor.find_outputs(sequin_to_process.active_outputs,sequin_to_process.id)
  end
end

otab = {}
function sequin_processor.find_outputs(output_table, sequin_id)
  otab[sequin_id] = output_table
  if sequin_id then
    -- print("find_outputs")
    for k, v in pairs(output_table) do 
      -- print("find outputs", k,v)
      if k == "output_data" then
        local selected_sequin = v.value_heirarchy.sqn
        if selected_sequin == sequin_id then
          local selected_sequin_output_group = sequencer_controller.get_active_sequinset()
          local sequin_output_group = v.value_heirarchy.sgp
          local sequin_output_type  = v.value_heirarchy.typ
          local sequin_output_type_processor = sequin_processor.processors[sequin_output_type]
          if selected_sequin_output_group == sequin_output_group then

            -- get the next value set in the output table's sequins
            -- print("output_data")
            local next_output_value = v.seq and v.seq() or nil
            -- print("output sequin value",sequin_output_type_processor,next_output_value)
            local value_type = v.value_type
            -- seq = v.sequins
            if sequin_output_type_processor and next_output_value ~= nil and next_output_value ~= "" then
              -- local process_mode = string.find(v.value,"r") == nil and "absolute" or "relative"
              local process_mode = string.find(next_output_value,"r") == nil and "absolute" or "relative"
              -- print("next_output_value, value_type, process_mode",next_output_value,value_type,process_mode)
              
              if process_mode == "absolute" or (value_type ~= "number" and value_type ~= "notes" ) then 
                v.value = next_output_value 
                v.calculated_absolute_value = nil
                sequin_output_type_processor.process(v)
              elseif process_mode == "relative" and (value_type == "number" or value_type == "notes") then
                -- local active_output_values = sequencer_controller.get_output_values(v.value_heirarchy)
                -- find the last occurrance of an absolute value
                local previous_absolute_value = 0
                local previous_absolute_value_index = 1
                
                for i=selected_sequin,1,-1 do
                 if (output_table and 
                      output_table[i] and 
                      output_table[i][1] ~= nil and 
                      output_table[i][1] ~= "nil") and 
                      string.find(output_table[i][1],"r") == nil 
                  then
                    previous_absolute_value = output_table[i][1]
                    -- print("previous_absolute_value",previous_absolute_value)
                    previous_absolute_value_index = i
                    -- break
                  end
                end
                
                -- starting from the previous absolute value (or the start of the output values table),
                -- figure out the current relative value to output
                local calculated_absolute_value = previous_absolute_value
                for i=previous_absolute_value_index,selected_sequin,1 do
                  if output_table[i][1] ~= "nil" then
                    local val
                    if string.find(next_output_value,"r") then
                      local number_end = string.find(next_output_value,"r") - 1
                      val = string.sub(next_output_value,1,number_end)
                      -- print("previous_absolute_value, calculated_absolute_value,val",previous_absolute_value, calculated_absolute_value, val)
                      calculated_absolute_value = previous_absolute_value + tonumber(val)
                      v.value = next_output_value 
                    end
                  end
                end
                v.calculated_absolute_value = calculated_absolute_value
                -- provide relative value and calculated absolute value ()
                sequin_output_type_processor.process(v)
              end
            else 
              if sequin_output_type_processor == nil then
                print("ERROR, can't find processor for sequin output type", sequin_output_type)
              else
                -- print("no value defined at sequin step")
              end
            end
          end
        else
          -- print("didn't find matching id",sequin_id, selected_sequin)
          break
        end
      elseif type(v) == "table" then
        -- print("table",k)
        sequin_processor.find_outputs(v, sequin_id)
      end
    end
  end
  -- sequin_processor.processors[]
end

return sequin_processor