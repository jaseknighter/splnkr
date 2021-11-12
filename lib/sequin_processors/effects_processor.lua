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

return effects_processor
