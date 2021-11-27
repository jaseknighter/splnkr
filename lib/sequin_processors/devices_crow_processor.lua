local devices_crow_processor = {}
local dcp = devices_crow_processor
function dcp.init()
  dcp.voice_default = {
    pitch    = 1,
    repeats  = 0,
    repeat_freq = 1
  }

  for i=1,2,1 do
    dcp["voice"..i] = {}
    dcp["voice"..i].pitch = {}
    dcp["voice"..i].repeats = {}
    dcp["voice"..i].repeat_freq = {}
    for j=1,5,1 do
      dcp["voice"..i].pitch[j] = dcp.voice_default.pitch
      dcp["voice"..i].repeats[j] = dcp.voice_default.repeats
      dcp["voice"..i].repeat_freq[j] = dcp.voice_default.repeat_freq
    end
  end
end

function dcp.process(output_table, subsequin_ix)
  local ssid = output_table.ssid
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  local mod = output_table.value_heirarchy.mod

  if mod == 1 then -- update pitch
    dcp["voice1"].pitch[subsequin_ix] = value 
    clock.run(dcp.play_note,1, 1, ssid, subsequin_ix)
  elseif mod == 2 then -- update note repeats
    dcp["voice1"].repeats[subsequin_ix] = value       
  elseif mod == 3 then -- update note repeat frequency      
    value = NOTE_REPEAT_FREQUENCIES[value]
    local frac = string.find(value,"/")
    dcp["voice1"].repeat_freq[subsequin_ix] = frac and fn.fraction_to_decimal(value) or value
  elseif mod == 4 then -- update pitch
    dcp["voice2"].pitch[subsequin_ix] = value 
    clock.run(dcp.play_note,2, 2, ssid, subsequin_ix)
  elseif mod == 5 then -- update note repeats
    dcp["voice2"].repeats[subsequin_ix] = value       
  else -- update note repeat frequency      
    value = NOTE_REPEAT_FREQUENCIES[value]
    local frac = string.find(value,"/")
    dcp["voice2"].repeat_freq[subsequin_ix] = frac and fn.fraction_to_decimal(value) or value

  end
  
  -- sub sequin gets called here--
  -- local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  -- control_to_update(value) -- update control
end

dcp.ratchet_pats = {}
function dcp.init_ratchet(ssid, ratchet_data)
  local active_ssid = sequencer_controller.get_active_sequinset_id()
  if active_ssid == ssid then 
    local lattice = sequencer_controller.lattice
    local next_pat_ix = #dcp.ratchet_pats+1
    dcp.ratchet_pats[next_pat_ix] = {}
    dcp.ratchet_pats[next_pat_ix] = lattice:new_pattern({
      action = function()
        local pat = dcp.ratchet_pats[next_pat_ix]
        if active_ssid == ssid then
          pat.num_times_repeated = pat.num_times_repeated and pat.num_times_repeated + 1 or 0
          if ratchet_data.repeats - pat.num_times_repeated == 0 then
            pat:destroy()
          elseif ratchet_data.repeats > 1 then
            externals1.note_on(1,fn.deep_copy(ratchet_data),1,1,"sequencer", "crow")
          end
        end
      end,
      division = ratchet_data.repeat_freq,
      enabled = true
    })
    dcp.ratchet_pats[next_pat_ix].ix = next_pat_ix
  end

end

function dcp.play_note(output, voice_id, ssid,subsequin_ix)
  clock.sleep(0.0001)
  local value_tab = {
    pitch       = dcp["voice"..output].pitch[subsequin_ix],
    repeats     = dcp["voice"..output].repeats[subsequin_ix],
    repeat_freq = dcp["voice"..output].repeat_freq[subsequin_ix],
    mode = 1
  } 
  value_tab.repeats = type(value_tab.repeats) == 'number' and value_tab.repeats or 0

  if dcp["voice"..output].repeats[subsequin_ix] > 0 then
    dcp.init_ratchet(ssid, fn.deep_copy(value_tab))  
  end
  externals1.note_on(voice_id,fn.deep_copy(value_tab),1,1,"sequencer", "crow")
end


return dcp
