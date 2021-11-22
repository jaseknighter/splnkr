local sequin_processor = {}


-- sc.sequencers[5].seq:step(2)
sequin_processor.processors = {
  softcut_processor,
  devices_processor, 
  effects_processor,
  time_processor,
}
function sequin_processor.init()
  softcut_processor.init()
  devices_midi_processor.init()
  sequin_processor.active_sub_sequins = {}
end

function sequin_processor.process(sequin_to_process,sub_seq_leader_ix, ssid)
  if(#sequin_to_process.active_outputs)>0 then
    sequin_processor.gather_outputs(ssid,sequin_to_process.active_outputs, sequin_to_process.id, sub_seq_leader_ix)
  end
end


--[[
control_name    pitch
value_type      notes
seq     table: 0x22bf6e8
control_id    pitch
value_heirarchy table: 0x22bf890
value   1
]]
function sequin_processor.get_active_sub_sequins()
  return sequin_processor.active_sub_sequins
end

function sequin_processor.gather_outputs(ssid,output_table, sequin_id, sub_seq_leader_ix, num_outputs)
  local num_outputs = num_outputs or nil
  sub_seq_leader_ix = sub_seq_leader_ix > 1 and sub_seq_leader_ix or 1
  
  for k, v in pairs(output_table) do 
    if k == "num_outputs" then
      num_outputs = v
    end
    if k == "output_data" then
      local selected_sequin = v.value_heirarchy.sqn
      if selected_sequin == sequin_id then
        local selected_sequin_output_group = sequencer_controller.get_active_sequinset_id()
        local sequin_output_group = v.value_heirarchy.sgp
        local sequin_output_type = v.value_heirarchy.typ
        local sequin_output_type_processor = sequin_processor.processors[sequin_output_type]
        if selected_sequin_output_group == sequin_output_group then

          -- get the next value set in the output table's sequins
          -- however, if the select function is nil, define the sequin with its data because a deep_copy function has been performed (long story...)
          if v.seq then
            if type(v.seq.select) ~= 'function' then
              v.seq = Sequins{table.unpack(v.seq.data)}
            end
            local type = v.value_heirarchy.typ
            if sequin_processor.active_sub_sequins[OUTPUT_TYPES[type]] == nil then
              sequin_processor.active_sub_sequins[OUTPUT_TYPES[type]] = {}
            end

            local control_name = v.control_name
            local control_name_found = false
            local outputs = sequin_processor.active_sub_sequins[OUTPUT_TYPES[type]]
            for i=1,#outputs,1 do
              if outputs[i].control_name == control_name then
                control_name_found = true
              end
            end
            if control_name_found == false then
              table.insert(sequin_processor.active_sub_sequins[OUTPUT_TYPES[type]],v)
            end
              --------------------------------------
            -- THIS IS WHERE THE SUB SEQUINS GET INCREMENTED 
            v.seq:select(sub_seq_leader_ix)
            -- v.ix_repeats = v.ix_repeats == nil and 0
            if v.last_ix and v.last_ix == sub_seq_leader_ix then
              v.ix_repeats = v.ix_repeats + 1
              if v.ix_repeats > max_sub_seq_repeats then
                params:set("sequin_step",params:get("sequin_step")-1)
                params:set("sub_sequin_step",params:get("sequin_step")-1)
                params:set("num_sequin",params:get("num_sequin")+1)
                params:set("num_sub_sequin",params:get("num_sub_sequin")+1)
              end
            else
              v.ix_repeats = 0
            end
            v.last_ix = sub_seq_leader_ix
            local next_output_value = v.seq() 
            local sub_sequin_data = {
              output_table=v,
              sequin_output_type_processor=sequin_output_type_processor,
              next_output_value = next_output_value,
              ssid=ssid
            } 

            sequin_processor.process_sub_sequins(sub_sequin_data, ssid,sub_seq_leader_ix, v.value_heirarchy)
            --
            --------------------------------------
          end
        end
      else
        --print("didn't find matching id",sequin_id, selected_sequin)
        break
      end
    elseif type(v) == "table" then
      sequin_processor.gather_outputs(ssid, v, sequin_id, sub_seq_leader_ix, num_outputs)
    end
  end  
  
  return num_outputs
end

sequin_processor.previous_absolute_values = {}
sequin_processor.previous_relative_values = {}

function sequin_processor.process_sub_sequins(sub_sequins, ssid, sub_seq_leader_ix,vh)
  local output_table = sub_sequins.output_table
  local sequin_output_type_processor = sub_sequins.sequin_output_type_processor
  
  local typ = vh.typ
  local out = vh.out
  local mod = vh.mod
  local par = vh.par
  print(typ,out,par,mod)
  local pav
  
  if sequin_processor.previous_absolute_values[typ] == nil then sequin_processor.previous_absolute_values[typ] = {} end
  if sequin_processor.previous_absolute_values[typ][out] == nil then sequin_processor.previous_absolute_values[typ][out] = {} end
  if par then
    if sequin_processor.previous_absolute_values[typ][out][mod] == nil then sequin_processor.previous_absolute_values[typ][out][mod] = {} end
    if  sequin_processor.previous_absolute_values[typ][out][mod][par] == nil then sequin_processor.previous_absolute_values[typ][out][mod][par] = 0 end
  else
    if sequin_processor.previous_absolute_values[typ][out][mod] == nil then sequin_processor.previous_absolute_values[typ][out][mod] = 0 end
  end  
  
  if par then
    pav = sequin_processor.previous_absolute_values[typ][out][mod][par]
  else
    pav = sequin_processor.previous_absolute_values[typ][out][mod]
  end

  if sequin_processor.previous_relative_values[typ] == nil then sequin_processor.previous_relative_values[typ] = {} end
  if sequin_processor.previous_relative_values[typ][out] == nil then sequin_processor.previous_relative_values[typ][out] = {} end
  if sequin_processor.previous_relative_values[typ][out][mod] == nil then sequin_processor.previous_relative_values[typ][out][mod] = {} end
  if par and sequin_processor.previous_relative_values[typ][out][mod][par] == nil then sequin_processor.previous_relative_values[typ][out][mod][par] = {} end
  -- if par then
  --   prv = sequin_processor.previous_relative_values[typ][out][mod][par]
  -- else
  --   prv = sequin_processor.previous_relative_values[typ][out][mod]
  -- end

  sequin_processor.previous_relative_values[typ] = sequin_processor.previous_relative_values[typ] and sequin_processor.previous_relative_values[typ] or {}
  local next_output_value = sub_sequins.next_output_value
  
  local value_type = output_table.value_type
  if sequin_output_type_processor and next_output_value ~= nil and next_output_value ~= "" then
    local process_mode = string.find(next_output_value,"r") == nil and "absolute" or "relative"
    if process_mode == "absolute" or (value_type ~= "number" and value_type ~= "notes" ) then 
      output_table.value = next_output_value 
      output_table.calculated_absolute_value = nil
      if par then
        sequin_processor.previous_absolute_values[typ][out][mod][par] = next_output_value
        sequin_processor.previous_relative_values[typ][out][mod][par] = {}
      else 
        sequin_processor.previous_absolute_values[typ][out][mod] = next_output_value
        sequin_processor.previous_relative_values[typ][out][mod] = {}
      end
      if output_table.value ~= "nil" then
        output_table.ssid = ssid
        sequin_output_type_processor.process(output_table,sub_seq_leader_ix)
      end
    elseif process_mode == "relative" and (value_type == "number" or value_type == "notes") then
      if par then
        local calculated_absolute_value = sequin_processor.previous_absolute_values[typ][out][mod][par]
        for i=1,#sequin_processor.previous_relative_values[typ][out][mod][par],1 do
          calculated_absolute_value = calculated_absolute_value + sequin_processor.previous_relative_values[typ][out][mod][par][i]
        end

        local number_end = string.find(next_output_value,"r") - 1
        local val = string.sub(next_output_value,1,number_end)
        if tonumber(calculated_absolute_value) and tonumber(val) then
          calculated_absolute_value = tonumber(calculated_absolute_value) + tonumber(val)
        else 
          print("sequin_processor.lua 151: can't find calculated_absolute_value or val",calculated_absolute_value, val)
        end
        table.insert(sequin_processor.previous_relative_values[typ][out][mod][par],val)
        output_table.value = next_output_value 
        output_table.calculated_absolute_value = calculated_absolute_value
        if output_table.value ~= "nil" then
          output_table.ssid = ssid
          sequin_output_type_processor.process(output_table,sub_seq_leader_ix)
        end
      else
        local calculated_absolute_value = sequin_processor.previous_absolute_values[typ][out][mod]
        for i=1,#sequin_processor.previous_relative_values[typ][out][mod],1 do
          calculated_absolute_value = calculated_absolute_value + sequin_processor.previous_relative_values[typ][out][mod][i]
        end

        local number_end = string.find(next_output_value,"r") - 1
        local val = string.sub(next_output_value,1,number_end)
        if tonumber(calculated_absolute_value) and tonumber(val) then
          calculated_absolute_value = tonumber(calculated_absolute_value) + tonumber(val)
        else 
          print("sequin_processor.lua 151: can't find calculated_absolute_value or val",calculated_absolute_value, val)
        end
        table.insert(sequin_processor.previous_relative_values[typ][out][mod],val)
        output_table.value = next_output_value 
        output_table.calculated_absolute_value = calculated_absolute_value
        if output_table.value ~= "nil" then
          output_table.ssid = ssid
          sequin_output_type_processor.process(output_table,sub_seq_leader_ix)
        end
      end
    end
  else 
    if sequin_output_type_processor == nil then
      -- print("ERROR, can't find processor for sequin output type")
    else
      --print("no value defined at sequin step")
    end
  end
end

return sequin_processor