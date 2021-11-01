local effects_processor = {}


function effects_processor.init()
  
end

function effects_processor.process(output_table)
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  if output_table.value_heirarchy.out == 1 then -- amp
    params:set("amp",value)
  elseif output_table.value_heirarchy.out == 2 then -- drywet
    params:set("drywet",value)
  else
    local mod = output_table.value_heirarchy.mod
    if output_table.value_heirarchy.out == 3 then -- delay
      if mod == 1 then -- delay amt
        params:set("delay",value)
      elseif mod == 2 then -- delay time
        params:set("delay_time",value)
      elseif mod == 3 then -- delay decay time
        params:set("delay_decay",value)
      elseif mod == 4 then -- delay amp
        params:set("delay_amp",value)
      end
    elseif output_table.value_heirarchy.out == 4 then -- bitcrush
      if mod == 1 then -- bitcrush amt
        params:set("bitcrush",value)
      elseif mod == 2 then -- bitcrush bits
        params:set("bitcrush_bits",value)
      elseif mod == 3 then -- bitcrush rate
        params:set("bitcrush_rate",value)
      end
    elseif output_table.value_heirarchy.out == 5 then -- enveloper
      if mod == 1 then -- enveloper amt
        params:set("enveloper",value)
      elseif mod == 2 then -- trigger rate
        params:set("trig_rate",value)
      elseif mod == 3 then -- overlap amout
        params:set("overlap",value)
      end
    elseif output_table.value_heirarchy.out == 6 then -- pitchshift
      if mod == 1 then -- pitchshift amt
        params:set("pitchshift",value)
      elseif mod == 2 then -- pitchshift freq
        params:set("pitchshift_freq",value)
      elseif mod == 3 then -- pitchshift note1
        params:set("pitchshift_note1",value)
      elseif mod == 4 then -- pitchshift note2
        params:set("pitchshift_note2",value)
      elseif mod == 5 then -- pitchshift note3
        params:set("pitchshift_note3",value)
      elseif mod == 6 then -- pitchshift note4
        params:set("pitchshift_note4",value)
      elseif mod == 7 then -- pitchshift note5
        params:set("pitchshift_note5",value)
      elseif mod == 8 then -- pitchshift grain size
        params:set("grain_size",value)
      elseif mod == 9 then -- time_dispersion
        params:set("time_dispersion",value)
      end
    end
  end
end

function effects_processor.process_w_syn(output_table)
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

function effects_processor.process_w_del_ks(output_table)
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

function effects_processor.process_w_del(output_table)
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

return effects_processor
