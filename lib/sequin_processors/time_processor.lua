local time_processor = {}


function time_processor.init()
  
end

time_processor.steps = nil
time_processor.shape = nil
time_processor.duration = nil

function time_processor.process(output_table)
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  local out = output_table.value_heirarchy.out
  local mod = output_table.value_heirarchy.mod
  local par = output_table.value_heirarchy.par
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
      params:set("clock_tempo",value)
    elseif mod == 2 then -- time morph
      if par == 1 then -- target tempo
        clock.run(time_processor.clock_morph_start, value)
      elseif par == 1 then -- morph duration
        time_processor.duration = value
      elseif par == 2 then -- morph steps
        time_processor.steps = value
      elseif par == 3 then -- morph shape
        time_processor.shape = fn.fraction_to_decimal(MORPH_SHAPES[value])
      end
    elseif mod == 3 then -- delay time
      params:set("meter",value)
    elseif mod == 4 then -- delay decay time
      params:set("division",value)
    end
  end
end

function time_processor.clock_morph_start(target_tempo)
  clock.sleep(0.0001)
  local starting_val = fn.deep_copy(params:get("clock_tempo"))
  local duration = time_processor.duration or 2
  local steps = time_processor.steps or 10
  local shape = time_processor.shape or "lin"
  print("par1: start time morph", starting_val, duration, steps, shape)
  fn.morph(time_processor.clock_morph,starting_val,target_tempo,duration,steps,shape)
end

function time_processor.clock_morph(morphed_val)
  if morphed_val > 33 and morphed_val < 300 then
    params:set("clock_tempo",morphed_val)
  end
end




return time_processor
