---splnkr
-- <version> @jaseknighter
-- lines: llllllll.co/t/<lines thread id>
--
-- <script description>

-- before running the script, execute this code:
-- ~/norns/stop.sh; sleep 1; ~/norns/start.sh; sleep 9; jack_disconnect crone:output_5 SuperCollider:in_1; jack_disconnect crone:output_6 SuperCollider:in_2; jack_connect softcut:output_1 SuperCollider:in_1; jack_connect softcut:output_2 SuperCollider:in_2


--[[

ideas:
* implement a bandbass filterbank 
* preview changes in 1 channel before committing them (like dj's do...auditioning?)
* track parameter history 
  * turn the history into a sequence 
  * reply according to the time of changes or by meter
  * delete individual events
]]


include "lib/includes"

engine.name = 'Splnkr'

  ----------------------------
  -- from softcut studies 5. filter
  -- file = _path.dust.."/code/softcut-studies/lib/whirl1.aif"
  --[[
  file = _path.dust.."/code/splnkr/lib/minutemen_we_can_do_this.wav"
  rate = 1.0
  low = 15000
  band = 2000
  loop_start = 17
  loop_end = 20
  loop_length = loop_end - loop_start
  ]]

  alt_pressed = false

  pitchshift = 1
  vinyl = 1
  phaser = 1
  delay = 1
  strobe = 1
  drywet = 1

  ----------------------------

------------------------------
-- init
------------------------------
function init()
  -- ~/norns/stop.sh; sleep 1; ~/norns/start.sh; sleep 9; jack_disconnect crone:output_5 SuperCollider:in_1; jack_disconnect crone:output_6 SuperCollider:in_2; jack_connect softcut:output_1 SuperCollider:in_1; jack_connect softcut:output_2 SuperCollider:in_2
  
  --
  -- os.execute("jack_disconnect crone:output_5 SuperCollider:in_1;")  
  -- os.execute("jack_disconnect crone:output_6 SuperCollider:in_2;")
  os.execute("jack_connect softcut:output_1 SuperCollider:in_1;")  
  os.execute("jack_connect softcut:output_2 SuperCollider:in_2;")
  -- os.execute("sleep 9;")

  audio.level_eng_cut(0)
  crow.output[1].action = "{to(5,0),to(0,0.25)}"
  crow.output[2].action = "{to(5,0),to(0,0.25)}"
  crow.output[3].action = "{to(5,0),to(0,0.25)}"
  crow.output[4].action = "{to(5,0),to(0,0.25)}"
  -- set sensitivity of the encoders
  norns.enc.sens(1,6)
  norns.enc.sens(2,6)
  norns.enc.sens(3,6)

  pages = UI.Pages.new(0, 5)
    
  set_redraw_timer()
  page_scroll(1)
  
  
  grid_dirty, screen_dirty, splash_break = true, true, false
  -- graphics.init()
  _grid.init()
  if g.cols > 0 then
    print("grid found with " .. _grid.last_known_width .. " columns")
    grid_clock_id = clock.run(_grid.grid_redraw_clock)
  else
    print("no grid found")
  end
  
  
  active_notes = {}
  externals1 = externals:new(active_notes)
  externals2 = externals:new(active_notes)

  for i=1,num_envelopes,1
  do
    envelopes[i] = envelope:new(i, num_envelopes)
    envelopes[i].init(num_envelopes)
    local active = i == 1 and true or false
    envelopes[i].set_active(active_envelope)
  end



  parameters.init()
  -- parameters.set_params()

  parameters.init_envelope_controls(1)
  -- startup all sc effects
  engine.bpm(clock.get_tempo())
  -- engine.pitchshift(1)
  -- engine.vinyl(1)
  -- engine.phaser(1)
  -- engine.delay(1)
  -- engine.strobe(1)
  sample_player.init()

  
  ----------------------------
  -- from softcut studies 5. filter
  --[[
  audio.level_adc_cut(1)
  softcut.level_input_cut(1,2,1.0)
  softcut.level_input_cut(2,2,1.0)

  softcut.buffer_clear()
  softcut.buffer_read_mono(file,0,1,-1,1,1)

  waveform_loaded = true
  print("file",file)
  local ch, samples = audio.file_info(file)
  length = samples/48000

  for i=1,2 do
    softcut.enable(i,1)
    softcut.buffer(i,i)
    softcut.level(i,1.0)
    softcut.rate(i,rate)
    softcut.loop(i,1)
    -- softcut.loop_start(i,17)
    softcut.loop_start(i,loop_start)
    softcut.position(i,1)
    softcut.play(i,1)
  end

  -- softcut.loop_end(1,3.42)
  -- softcut.loop_end(2,1.25)
  -- softcut.loop_end(1,20)
  -- softcut.loop_end(2,20)
  softcut.loop_end(1,loop_end)
  softcut.loop_end(2,loop_end)

  softcut.rec(2,1)
  softcut.rec_level(2,0.5)
  softcut.pre_level(2,0.75)

  -- set voice 1 (sample playback) post-filter
  -- set voice 1 dry level to 0.0
  softcut.post_filter_dry(1,0.0)
  -- set voice 1 low pass level to 1.0 (full wet)
  softcut.post_filter_lp(1,1.0)
  -- set voice 1 filter cutoff
  softcut.post_filter_fc(1,low)
  -- set voice 1 filter rq (flattish)
  softcut.post_filter_rq(1,10)

  -- set voice 2 (echo recorder) pre-filter
  -- set voice 2 dry level to 0.0
  softcut.pre_filter_dry(2,0.0)
  -- set voice 2 band pass level to 1.0 (full wet)
  softcut.pre_filter_bp(2,1.0)
  -- set voice 2 filter cutoff
  softcut.pre_filter_fc(2,band)
  -- set voice 2 filter rq (peaky)
  softcut.pre_filter_rq(2,1)

  softcut.event_render(on_render)
  ]]
  ----------------------------
  
    -- Init polls
  
  local detect_level, note_num
  local last_note_num = 0

  amplitude_detect_poll1 = poll.set("amplitudeDetect1", function(value)
    detect_level = tonumber(value)
    -- print("amplitudeDetect1",value)
  end)
  amplitude_detect_poll2 = poll.set("amplitudeDetect2", function(value)
    -- print("amplitudeDetect2",value)
    detect_level = tonumber(value)
  end)
  amplitude_detect_poll3 = poll.set("amplitudeDetect3", function(value)
    -- print("amplitudeDetect3",value)
    detect_level = tonumber(value)
  end)
  amplitude_detect_poll4 = poll.set("amplitudeDetect4", function(value)
    -- print("amplitudeDetect4",value)
    detect_level = tonumber(value)
  end)

  frequency_detect_poll1 = poll.set("frequencyDetect1", function(value)
    note_num = value ~= 0 and MusicUtil.freq_to_note_num (value) or last_note_num
    -- if note_num ~= last_note_num and detect_level >= 0.05 and (value > 200 and value < 1800) then 
    if note_num ~= last_note_num then 
      externals1.note_on(1, note_num, note_num, 1, nil,"engine")
    end
  end)
  frequency_detect_poll2 = poll.set("frequencyDetect2", function(value)
    note_num = value ~= 0 and MusicUtil.freq_to_note_num (value) or last_note_num
    if note_num ~= last_note_num then 
      externals1.note_on(1, note_num, note_num, 1, nil,"engine")
    end
  end)
  frequency_detect_poll3 = poll.set("frequencyDetect3", function(value)
    note_num = value ~= 0 and MusicUtil.freq_to_note_num (value) or last_note_num
    if note_num ~= last_note_num then 
      externals1.note_on(1, note_num, note_num, 1, nil,"engine")
    end
  end)
  frequency_detect_poll4 = poll.set("frequencyDetect4", function(value)
    note_num = value ~= 0 and MusicUtil.freq_to_note_num (value) or last_note_num
    if note_num ~= last_note_num then 
      externals1.note_on(1, note_num, note_num, 1, nil,"engine")
    end
  end)

  splnkr_lattice = lattice:new()
  p = splnkr_lattice:new_pattern{
    action = function(t) 
      -- samples:play() 
      _grid:animate() 
    end,
    division = 1/16,
    enabled = true
  }

  clock.run(finish_init)
end

function finish_init()
  clock.sleep(0.2)
  amplitude_detect_poll1:start()
  amplitude_detect_poll2:start()
  amplitude_detect_poll3:start()
  amplitude_detect_poll4:start()
  frequency_detect_poll1:start()
  frequency_detect_poll2:start()
  frequency_detect_poll3:start()
  frequency_detect_poll4:start()

  splnkr_lattice:start()
    

  params:bang()
  initializing = false
end

--------------------------
-- encoders and keys
--------------------------
function enc(n, d)
  encoders_and_keys.enc(n, d)
  -- redraw()

end

function key(n,z)
  encoders_and_keys.key(n, z)
  
  -- redraw()

end


--------------------------
-- redraw 
--------------------------
function set_redraw_timer()
  redrawtimer = metro.init(function() 
  
    menu_status = norns.menu.status()
    if menu_status == false and initializing == false and selecting == false then
      -- sample_player.update()
  
      controller.update_pages()
      -- print("update")
      screen_dirty = false
      clear_subnav = true
      
    elseif menu_status == true and clear_subnav == true then
      screen_dirty = true
      clear_subnav = false
    end
  end, SCREEN_FRAMERATE, -1)
  redrawtimer:start()  
  
  -- screen.clear()
  -- controller.update_pages()
  -- screen.update()

end


function cleanup ()
  -- add cleanup code
  -- os.execute("sleep 1;")
  os.execute("jack_disconnect softcut:output_1 SuperCollider:in_1;")  
  os.execute("jack_disconnect softcut:output_2 SuperCollider:in_2;")
  os.execute("jack_connect crone:output_5 SuperCollider:in_1;")  
  os.execute("jack_connect crone:output_6 SuperCollider:in_2;")
  
  print("cleanupupup")
  
end

