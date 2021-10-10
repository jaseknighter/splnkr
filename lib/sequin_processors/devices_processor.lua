local devices_processor = {}

-- devices_processor.controls = {}

-- function devices_processor.init()
--   devices_processor.controls = {

--   }
-- end

function devices_processor.process(output_table)
  -- tab.print(output_table.value_heirarchy)
  if output_table.value_heirarchy.out == 1 then -- midi
  elseif output_table.value_heirarchy.out == 2 then -- crow
    devices_crow_processor.process(output_table)
  elseif output_table.value_heirarchy.out == 3 then -- just friends
    devices_jf_processor.process(output_table)
  elseif output_table.value_heirarchy.out == 4 then -- w/
  end
end

return devices_processor