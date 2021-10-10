local devices_jf_processor = {}

function devices_jf_processor.init()
  devices_jf_processor.controls = {
    play_note = devices_jf_processor.play_note,
    play_voice = devices_jf_processor.play_voice,
    drum =  devices_jf_processor.play_drum
  }
end

function devices_jf_processor.process(output_table)
  -- print("process crow control_id, control_name:",output_table.control_id,output_table.control_name)
  -- tab.print(output_table)
  -- local voice = output_table.value_heirarchy
  -- tab.print(output_table.value_heirarchy)
  -- local voice = output_table.value_heirarchy.out
  -- print("control_to_update, voice",control_to_update, voice)
  
  
  local control_to_update = devices_jf_processor.controls[output_table.control_id]

  -- sub sequin gets called here--
  local value = output_table.calculated_absolute_value and output_table.calculated_absolute_value or output_table.value
  control_to_update(value) -- update control
end

function devices_jf_processor.play_note1(value)
  externals1.note_on(1,value,1,1,1,"sequencer", "crow")
  -- externals2.note_on(1,value/2,1,1,1,"sequencer", crow)
end

function devices_jf_processor.play_note3(value)
  externals1.note_on(3,value,1,1,1,"sequencer", "crow")
  -- externals2.note_on(1,value/2,1,1,1,"sequencer", crow)
end

function devices_jf_processor.play_drum(value)
  externals1.note_on(1,value,1,1,1,"sequencer", "crow_drum")
end

return devices_jf_processor


-- externals1.note_on(1,60,1,1,1,"engine")dp process