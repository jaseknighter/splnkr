local devices_crow_processor = {}

function devices_crow_processor.init()
  devices_crow_processor.controls = {
    crow1_pitch = devices_crow_processor.play_note1,
    crow3_pitch = devices_crow_processor.play_note3,
    drum =  devices_crow_processor.play_drum
  }
end

function devices_crow_processor.process(output_table)
  -- print("process crow control_id, control_name:",output_table.control_id,output_table.control_name)
  -- tab.print(output_table)
  -- local voice = output_table.value_heirarchy
  -- tab.print(output_table.value_heirarchy)
  -- local voice = output_table.value_heirarchy.out
  -- print("control_to_update, voice",control_to_update, voice)
  
  
  local control_to_update = devices_crow_processor.controls[output_table.control_id]

  -- sub sequin gets called here--
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  control_to_update(value) -- update control
end

function devices_crow_processor.play_note1(value)
  externals1.note_on(1,value,1,1,1,"sequencer", "crow")
  -- externals2.note_on(1,value/2,1,1,1,"sequencer", crow)
end

function devices_crow_processor.play_note3(value)
  externals1.note_on(3,value,1,1,1,"sequencer", "crow")
  -- externals2.note_on(1,value/2,1,1,1,"sequencer", crow)
end

function devices_crow_processor.play_drum(value)

end

return devices_crow_processor


-- externals1.note_on(1,60,1,1,1,"engine")dp process