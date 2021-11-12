local time_processor = {}


function time_processor.init()
  
end

function time_processor.process(output_table)
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  local out = output_table.value_heirarchy.out
  local mod = output_table.value_heirarchy.mod
  if out == 1 then -- sequin
    if mod == 1 then -- step
      if params:get("sequin_step") ~= value then
        params:set("sequin_step",value)
      end
    elseif mod == 2 then -- num sequin
      params:set("num_sequin",value)
    elseif mod == 3 then -- starting sequin
      params:set("starting_sequin",value)
    end
  elseif out == 2 then -- sub-sequin
    if mod == 1 then -- step
      params:set("sub_sequin_step",value)
    elseif mod == 2 then -- num sequin
      params:set("num_sub_sequin",value)
    elseif mod == 3 then -- starting sequin
      params:set("starting_sub_sequin",value)
    end
  elseif out == 3 then -- clock, lattice, patterns
    local time_between_beats = sc.sequencers[5].pattern.division
    if mod == 1 then -- tempo
      -- params:set("clock_tempo",value)
      local starting_val = fn.deep_copy(params:get("clock_tempo"))
      -- print("from,to", starting_val,value)
      fn.morph(time_processor.morph_clock_tempo,starting_val,value,3,10,"log")
    elseif mod == 2 then -- delay time
      params:set("meter",value)
    elseif mod == 3 then -- delay decay time
      params:set("division",value)
    end
  end
end

function time_processor.morph_clock_tempo(morphed_val)
  if morphed_val > 33 and morphed_val < 300 then
    params:set("clock_tempo",morphed_val)
  end
end




return time_processor
