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
    --print("process sequin for active sequin group",sequencer_controller.get_active_sequinset())
    sequin_processor.find_outputs(sequin_to_process.active_outputs,sequin_to_process.id)
  end
end

local previous_absolute_value = 0
local previous_relative_values = {}

function sequin_processor.find_outputs(output_table, sequin_id)
  if sequin_id then
    --print("find_outputs")
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
            --print("output_data")
            local next_output_value
            if v.seq then
              -- v.seq:reset() 
              next_output_value = v.seq() 
            end
            --print("output sequin value",sequin_output_type_processor,next_output_value)
            local value_type = v.value_type
            -- seq = v.sequins
            if sequin_output_type_processor and next_output_value ~= nil and next_output_value ~= "" then
              -- local process_mode = string.find(v.value,"r") == nil and "absolute" or "relative"
              local process_mode = string.find(next_output_value,"r") == nil and "absolute" or "relative"
              --print("next_output_value, value_type, process_mode",next_output_value,value_type,process_mode)
              
              if process_mode == "absolute" or (value_type ~= "number" and value_type ~= "notes" ) then 
                v.value = next_output_value 
                v.calculated_absolute_value = nil
                previous_absolute_value = next_output_value
                if v.value ~= "nil" then
                  sequin_output_type_processor.process(v)
                end
                previous_relative_values = {}
              elseif process_mode == "relative" and (value_type == "number" or value_type == "notes") then
                local calculated_absolute_value = previous_absolute_value
                for i=1,#previous_relative_values,1 do
                  calculated_absolute_value = calculated_absolute_value + previous_relative_values[i]
                end

                local number_end = string.find(next_output_value,"r") - 1
                val = string.sub(next_output_value,1,number_end)
                if calculated_absolute_value and val then
                  calculated_absolute_value = tonumber(calculated_absolute_value) + tonumber(val)
                else 
                  print("sequin_processor.lua 70: can't find calculated_absolute_value or val",calculated_absolute_value, val)
                end
                table.insert(previous_relative_values,val)
                v.value = next_output_value 
                

                v.calculated_absolute_value = calculated_absolute_value
                -- provide relative value and calculated absolute value ()
                -- sequin_output_type_processor.process(v)
                if v.value ~= "nil" then
                  sequin_output_type_processor.process(v)
                end

              end
            else 
              if sequin_output_type_processor == nil then
                print("ERROR, can't find processor for sequin output type", sequin_output_type)
              else
                --print("no value defined at sequin step")
              end
            end
          end
        else
          --print("didn't find matching id",sequin_id, selected_sequin)
          break
        end
      elseif type(v) == "table" then
        --print("table",k)
        sequin_processor.find_outputs(v, sequin_id)
      end
    end
  end
  -- sequin_processor.processors[]
end

return sequin_processor