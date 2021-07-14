---splnkr
-- <version> @jaseknighter
-- lines: llllllll.co/t/<lines thread id>
--
-- <script description>

--[[
questions for zack:

* jack: detecting setup and reconfiguring on startup and exit

]]


include "lib/includes"

engine.name = 'Splnkr'

  ----------------------------
  -- from softcut studies 5. filter
  -- file = _path.dust.."/code/softcut-studies/lib/whirl1.aif"
  file = _path.dust.."/code/splnkr/lib/minutemen_we_can_do_this.wav"
  rate = 1.0
  low = 15000
  band = 2000
  loop_start = 17
  loop_end = 20
  loop_length = loop_end - loop_start
  alt_pressed = false

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
    
  redraw()
  page_scroll(1)
  
  initializing = false

  -- startup all sc effects
  engine.bpm(clock.get_tempo())
  engine.vinyl(1)
  engine.phaser(1)
  engine.delay(1)
  engine.strobe(1)

  ----------------------------
  -- from softcut studies 5. filter
  audio.level_adc_cut(1)
  softcut.level_input_cut(1,2,1.0)
  softcut.level_input_cut(2,2,1.0)

  softcut.buffer_clear()
  softcut.buffer_read_mono(file,0,1,-1,1,1)

  waveform_loaded = true
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

  ----------------------------
  
    -- Init polls
  
    local amplitude_detect_poll = poll.set("amplitudeDetect", function(value)
      -- if tonumber(value)>0.001 then print(value) end
      local detect_level = tonumber(value)
      local pulse_length = 0.01
      local polarity = 1
      local pulse_level1 = 5
      local pulse_level2 = 5
      local pulse_level3 = 5
      local pulse_level4 = 5

      -- sent triggers to crow outputs 1-4 depending on the amplitude level of the sample 
      if detect_level >= 0.001 then
        -- print(1)
        crow.output[1].action = "pulse(" .. pulse_length ..",".. pulse_level1 .. "," .. polarity .. ")"
        crow.output[1]() 
      end
      if detect_level >= 0.001 and detect_level < 0.05 then
        print(2)
        crow.output[2].action = "pulse(" .. pulse_length ..",".. pulse_level2 .. "," .. polarity .. ")"
        crow.output[2]() 
      end
      if detect_level >= 0.05 and detect_level < 0.1 then
        print(3)
        crow.output[3].action = "pulse(" .. pulse_length ..",".. pulse_level3 .. "," .. polarity .. ")"
        crow.output[3]() 
      end
      if detect_level >= 0.1 then
        print(4)
        crow.output[4].action = "pulse(" .. pulse_length ..",".. pulse_level4 .. "," .. polarity .. ")"
        crow.output[4]() 
      end
    end)
    amplitude_detect_poll:start()
  
  -- os.execute(" ~/norns/stop.sh; sleep 1;  ~/norns/start.sh; sleep 9;  ")
  -- os.execute(" jack_disconnect crone:output_5 SuperCollider:in_1;  jack_disconnect crone:output_6 SuperCollider:in_2;  ")
  -- os.execute(" jack_connect softcut:output_1 SuperCollider:in_1;  jack_connect softcut:output_2 SuperCollider:in_2; ") 
end

--------------------------
-- encoders and keys
--------------------------
function enc(n, d)
  encoders_and_keys.enc(n, d)
  redraw()

end

function key(n,z)
  -- encoders_and_keys.key(n, z)
  if n==1 then
    if z == 1 then alt_pressed = true else alt_pressed = false end
  elseif n==2 then

  elseif n==3 then

  end

  redraw()

end

--------------------------
-- redraw 
--------------------------
function redraw()
  --[[
  redrawtimer = metro.init(function() 
    local menu_status = norns.menu.status()
    if menu_status == false and initializing == false then
      -- bball_pages.update_pages()
      splnkr_pages.update_pages()
    end
  end, SCREEN_FRAMERATE, -1)
  redrawtimer:start()  
  ]]
  screen.clear()
  splnkr_pages.update_pages()
  -- screen.update()

end


function cleanup ()
  -- add cleanup code
  print("cleanupupup")
  -- os.execute(" ~/norns/stop.sh; sleep 1;  ~/norns/start.sh; sleep 9;  jack_disconnect softcut:output_1 SuperCollider:in_1;  jack_disconnect softcut:output_2 SuperCollider:in_2; jack_connect crone:output_5 SuperCollider:in_1;  jack_connect crone:output_6 SuperCollider:in_2;  ")
end

