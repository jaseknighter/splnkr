--------------------------
-- record samples to tape 
-- todo: set pre_save_play_mode per voice
--------------------------
sample_recorder = {}

function sample_recorder.save_samples(dir_name, incr)
  if incr == nil then incr = 1 end
  local pathname1 = _path.dust.."audio/clipper/"
  local pathname2 = incr == nil and
    _path.dust.."audio/clipper/" .. dir_name or 
    _path.dust.."audio/clipper/" .. dir_name  .. "_" .. incr
  if os.rename(pathname1, pathname1) == nil then -- create cutter dir, if neca
    os.execute("mkdir " .. pathname1)
  end
  if os.rename(pathname2, pathname2) == nil then -- create dir for new files
    print("make dir: ",  pathname2)
    os.execute("mkdir " .. pathname2)
  else -- if dir already exists, increment the directory name
    print("directory already exists, increment the directory name") 
    sample_recorder.save_samples(dir_name, incr+1)
    return
  end

  saving = true
  pre_save_play_mode = play_mode
  sample_player.set_play_mode(0)
  
  local starting_clip = pre_save_play_mode == 3 and sample_player.active_cutter or 1
  local ending_cutter = pre_save_play_mode == 3 and sample_player.active_cutter or #cutters
  sample_recorder.record_to_tape_start(starting_clip, ending_cutter, dir_name, pathname2)
end

function sample_recorder.record_to_tape_start(cutter_to_record,ending_cutter,dir_name,pathname)
  local loop_length
  local file = pathname.."/"..dir_name .. cutter_to_record .. ".wav"
  if pre_save_play_mode > 1 and cutter_to_record <= ending_cutter then
    audio.tape_record_open (file)
    local rate = sample_player.voice_rates[cutter_to_record]
    local start = (cutters[cutter_to_record]:get_start_x()/128) * length
    local finish = (cutters[cutter_to_record]:get_finish_x()/128) * length
    for i=1,2,1
    do
      softcut.rate(i,rate)
      softcut.loop_start(i,start)
      softcut.loop_end(i,finish)
    end
    softcut.position(1,0)
    softcut.play(1,1)
    loop_length = (finish - start)/rate 
    loop_length = loop_length > 0 and loop_length or loop_length * -1
    print("record clips start",cutter_to_record, ending_cutter,dir_name,pathname,loop_length)
    audio.tape_record_start()
    clock.run(sample_recorder.record_to_tape_next,loop_length, cutter_to_record+1, ending_cutter, dir_name, pathname)
  elseif pre_save_play_mode < 2 then
    audio.tape_record_open (file)
    local rate = sample_player.voice_rates[1]
    local start = 0
    local finish = length
  for i=1,2,1
    do
      softcut.rate(i,rate)
      softcut.loop_start(i,start)
      softcut.loop_end(i,finish)
    end
    softcut.position(1,0)
    softcut.play(1,1)
    loop_length = (finish - start)/rate
    loop_length = loop_length > 0 and loop_length or loop_length * -1
    print("record all start",cutter_to_record,dir_name,pathname,loop_length)
    audio.tape_record_start()
    clock.run(sample_recorder.record_to_tape_next, loop_length, cutter_to_record+1, ending_cutter, dir_name, pathname)
  else
    sample_recorder.record_to_tape_done()
  end
end

function sample_recorder.record_to_tape_next(wait, next_loop, ending_cutter, dir_name, pathname)
  clock.sleep(wait)
  -- print("loop done",next_loop,dir_name,pathname)
  -- stop the recording
  softcut.play(1,0)
  audio.tape_record_stop ()
  if pre_save_play_mode == 2 then
    clock.run(sample_recorder.record_to_tape_pause, next_loop, ending_cutter, dir_name, pathname)
  else
    sample_recorder.record_to_tape_done()
  end
end

function sample_recorder.record_to_tape_pause(next_loop, ending_cutter, dir_name, pathname)
  clock.sleep(0.1)
  sample_recorder.record_to_tape_start(next_loop, ending_cutter, dir_name,pathname)
end

function sample_recorder.record_to_tape_done()
  -- print("done. reset play mode:",pre_save_play_mode)
  saving = false
  sample_player.set_play_mode(pre_save_play_mode)
end


return sample_recorder