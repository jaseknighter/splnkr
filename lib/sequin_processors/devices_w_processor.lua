local devices_w_processor = {}


function devices_w_processor.init()
  
end

function devices_w_processor.process(output_table)
  local control_to_update
  if output_table.value_heirarchy.mod < 4 then -- w_syn
    devices_w_processor.process_w_syn(output_table)
  elseif output_table.value_heirarchy.mod == 4 then -- w_delay karplus strong
    devices_w_processor.process_w_del_ks(output_table)
  elseif output_table.value_heirarchy.mod == 4 then -- w_delay
    devices_w_processor.process_w_del(output_table)
  end
end

function devices_w_processor.process_w_syn(output_table)
  local param = output_table.value_heirarchy.par
  local voice = output_table.value_heirarchy.mod
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value

  -- print("param,voice",param,voice)    
  params:set('wsyn_voc',voice)
  if param == 1 then -- update pitch
    externals1.note_on(voice,value,1,1,"sequencer", "wsyn")
  elseif param == 2 then -- update ar_velocity
    params:set("wsyn_vel",value)
  elseif param == 3 then -- update ar_curve
    print("curv val",value)
    params:set("wsyn_curve",value)
  elseif param == 4 then -- update ar_ramp
    params:set("wsyn_ramp",value)
  elseif param == 5 then -- update fm index
    params:set("wsyn_fm_index",value)
  elseif param == 6 then -- update fm envelope
    params:set("wsyn_fm_env",value)
  elseif param == 7 then -- update fm ratio
    params:set("wsyn_fm_ratio",value)
  elseif param == 8 then -- update lpg time
    params:set("wsyn_lpg_time",value)
  elseif param == 9 then -- update lpg symmetry 
    params:set("wsyn_lpg_symmetry",value)
  end  
end

function devices_w_processor.process_w_del_ks(output_table)
  local param = output_table.value_heirarchy.par
  local voice = output_table.value_heirarchy.mod
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value

  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  if param == 1 then     -- w_del: pitch
    externals1.note_on(voice,value,1,1,"sequencer", "wdel_ks")
  elseif param == 2 then -- -- w_del: mix
    params:set("wdel_mix",value)
  elseif param == 3 then -- w_del: feedback
    params:set("wdel_feedback",value)
  elseif param == 4 then -- w_del: filter
    params:set("wdel_filter",value*1000)
  end  
end

function devices_w_processor.process_w_del(output_table)
  local param = output_table.value_heirarchy.par

  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  if param == 1 then     -- w_del: mix
    params:set("wdel_mix",value)
  elseif param == 2 then -- w_del: delay time
    value = util.clamp (value,0.1,10)
    params:set("wdel_time_long",value)
  elseif param == 3 then -- w_del: feedback
    params:set("wdel_feedback",value)
  elseif param == 4 then -- w_del: filter
    params:set("wdel_filter",value*1000)
  elseif param == 5 then -- w_del: rate
    params:set("wdel_rate",value)
  elseif param == 6 then -- w_del: frq (pitch)
    value = (value-60)/12
    params:set("wdel_freq",value)
  elseif param == 7 then -- w_del: mod rate
    params:set("wdel_mod_rate",value)
  elseif param == 8 then -- w_del: mod amount
    params:set("wdel_mod_amount",value)
  elseif param == 9 then -- w_del: freeze
    params:set("wdel_freeze",value)
  end  

end

return devices_w_processor
