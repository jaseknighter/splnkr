---splnkr

-- <version> @jaseknighter
-- lines: llllllll.co/t/<lines thread id>
--
-- <script description>

-- CREDITS: CATFACT, SPIKE, INFINITE, MATTLOWERY, AND OTHERS?!?!?!
-- crossfading from: https://schollz.com/blog/sampler/
-- before running the script, execute this code:
-- ~/norns/stop.sh; sleep 1; ~/norns/start.sh; sleep 9; jack_disconnect crone:output_5 SuperCollider:in_1; jack_disconnect crone:output_6 SuperCollider:in_2; jack_connect softcut:output_1 SuperCollider:in_1; jack_connect softcut:output_2 SuperCollider:in_2


--[[

[dev note] to start repl see: https://monome.org/docs/norns/maiden/#terminal-repl

ideas:
* add a cv recorder/splicer: https://discord.com/channels/879560807954911263/879560808575692845/883765421914873877
* add slew to the sequencer
* track parameter history 
  * turn the history into a sequence 
  * replay according to the time of changes or by meter
  * delete individual events

issues/todos:
* consolidate filter and sequencer lattices
* sound cuts out if env length is too long when enveloper is activated
* pan_type and pan_max params don't do anything (issue with the `Out` statement in sc I think)
* sub-sequins are not kept in sync with each other (maybe a feature?)
]]


include "lib/includes"

engine.name = 'Splnkr'

alt_key_active = false

pitchshift = 1
vinyl = 1
phaser = 1
delay = 1
strobe = 1
drywet = 1

  ----------------------------

function override_print()
  _print = print
  function print(print_me)
    -- if debug == 1 then 
      _print(print_me)
    -- end
  end
end

------------------------------
-- init
------------------------------

function init()
  -- debug = 0
  -- override_print()
  -- ~/norns/stop.sh; sleep 1; ~/norns/start.sh; sleep 9; jack_disconnect crone:output_5 SuperCollider:in_1; jack_disconnect crone:output_6 SuperCollider:in_2; jack_connect softcut:output_1 SuperCollider:in_1; jack_connect softcut:output_2 SuperCollider:in_2
  
  --
  -- os.execute("jack_disconnect crone:output_5 SuperCollider:in_1;")  
  -- os.execute("jack_disconnect crone:output_6 SuperCollider:in_2;")
  

  
  os.execute("jack_connect softcut:output_1 SuperCollider:in_1;")  
  os.execute("jack_connect softcut:output_2 SuperCollider:in_2;")
  -- os.execute("sleep 9;")

  audio.level_eng_cut(0)
  crow.reset()
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
  
  if g.cols > 0 then

    grid_dirty, screen_dirty, splash_break = true, true, false
    -- graphics.init()
    grid_filter.init()
  
    sequencer_controller.init()
    grid_sequencer.init()
  
    -- -- NOTE: fn parameters: group_name,x1,y1,x2, y2, off_level, selection_mode
    grid_sequencer:register_ui_group("sequin_groups1",1,1,1,1,7,3)
    grid_sequencer:register_ui_group("sequin_groups2",2,1,2,1,7,3)
    grid_sequencer:register_ui_group("sequin_groups3",3,1,3,1,7,3)
    grid_sequencer:register_ui_group("sequin_groups4",4,1,4,1,7,3)
    grid_sequencer:register_ui_group("sequin_groups5",5,1,5,1,7,3)
    
    
    print("grid found with " .. grid_filter.last_known_width .. " columns")
    grid_filter_clock_id = clock.run(grid_filter.grid_redraw_clock)
    grid_sequencer_clock_id = clock.run(grid_sequencer.grid_redraw_clock)
    
    
    --[[
    audio.level_cut(1.0)
    audio.level_adc_cut(1)
    audio.level_eng_cut(1)
    softcut.level(1,1.0)
    softcut.level_slew_time(1,0.25)
    softcut.level_input_cut(1, 1, 1.0)
    softcut.level_input_cut(2, 1, 1.0)
    softcut.pan(1, 0.0)
    softcut.rate(1, 1)
    softcut.rate_slew_time(1,1.0)
    softcut.loop_start(1, 10)
    softcut.loop_end(1, 12.5)
    softcut.rec_offset (1, 1.2)
    softcut.loop(1, 1)
    softcut.fade_time(1, 0.1)
    softcut.rec(1, 1)
    softcut.rec_level(1, 0.25)
    softcut.pre_level(1, 0.85) 
    softcut.position(1, 0)
    softcut.enable(1, 1)
    softcut.filter_dry(1, 0);
    softcut.filter_lp(1, 1.0);
    softcut.filter_bp(1, 1.0);
    softcut.filter_hp(1, 1.0);
    softcut.filter_fc(1, 300);
    softcut.filter_rq(1, 2.0);
    ]]
  
  else
    print("no grid found")
  end
  




  active_notes = {}
  externals1 = externals:new(active_notes)
  -- externals2 = externals:new(active_notes)

  for i=1,num_envelopes,1
  do
    envelopes[i] = envelope:new(i, num_envelopes)
    envelopes[i].init(num_envelopes)
    local active = i == 1 and true or false
    envelopes[i].set_active(active_envelope)
  end
  
  parameters.init()
  fn.build_scale()

  -- parameters.init_envelope_controls(1)


  -- startup all sc effects  
  engine.bpm(clock.get_tempo())
  engine.pitchshift(1)
  -- engine.vinyl(1)
  engine.flutter_and_wow(1)
  engine.phaser(1)
  engine.delay(1)
  engine.strobe(1)
  sample_player.init()

  
  ----------------------------
  
    -- Init polls
  --detect_level, detect_freq, note_num
  local last_note_num = 0

  amplitude_detect_poll = poll.set("amplitudeDetect", function(value)
    detect_level = fn.round_decimals(value,5,"up")
    if detect_level > 0.0002
    then 
      -- print("amplitudeDetect,detect_freq",tonumber(detect_level),detect_freq) 
    end
  end)

  last_onset_amplitude = nil
  last_onset_frequency = nil

  onset_amplitude_detect_poll = poll.set("onsetAmplitudeDetect", function(value)
    detect_level = fn.round_decimals(value,5,"up")
    if detect_level > 0.03 and (last_onset_amplitude < detect_level or math.abs(last_onset_frequency - detect_freq) > 5)
    then 
      note_num = MusicUtil.freq_to_note_num (detect_freq) 
      -- print(counter,"onsetAmplitudeDetect,detect_freq,note_num",tonumber(detect_level),last_onset_amplitude,detect_freq,note_num) 
      
      -- if params:get("detect_to_crow") > 1 then
      -- if params:get("detect_to_crow") == 2 then
      --   local value_tab = {
      --     pitch     = note_num,
      --     velocity  = util.linlin(0,0.05,1,127,detect_level),
      --     duration  = 1/4,
      --     channel   = params:get("detect_to_midi_out_channel"),
      --     mode = 1
      --   }      
      --   clock.run(externals1.note_on,1, value_tab, 1, 1,"engine","crow")
        -- clock.run(externals1.note_on,1, note_num, 1, 1,"engine","crow")
      -- end

      if params:get("detect_to_midi") == 2 then
        local value_tab = {
          pitch     = note_num,
          velocity  = util.linlin(0,0.05,1,127,detect_level),
          duration  = 1/4,
          channel   = params:get("detect_to_midi_out_channel"),
          mode = 1
        }      
        clock.run(externals1.note_on,1, value_tab, 1, 1,"engine","midi")
      end

    end
    last_onset_amplitude = detect_level
    last_onset_frequency = detect_freq
  end)
  
  frequency_detect_poll = poll.set("frequencyDetect", function(value)
    value = tonumber(value)
    detect_freq = value
    -- note_num = value ~= 0 and MusicUtil.freq_to_note_num (value) or last_note_num
    if note_num and note_num ~= last_note_num then 
      -- clock.run(externals1.note_on,1, note_num, note_num, 1, nil,"engine")
    end
  end)
  
  lattice_grid = Lattice:new{
    auto = true,
    meter = 4,
    ppqn = 96
  }
  
  grid_pattern = lattice_grid:new_pattern{
    action = function(t) 
      -- samples:play() 
      --print("anim",g,g.cols)
      -- if g and g.cols > 0 then 
        grid_filter:animate() 
      -- end
    end,
    division = 1/32, --1/16,
    enabled = true
  }
 

  
  clock.run(finish_init)
end


function finish_init()
  engine.splnk(0)

  clock.sleep(0.5)
  params:set("reverb",1)
  params:set("root_note",12)

  amplitude_detect_poll:start()
  onset_amplitude_detect_poll:start()
  frequency_detect_poll:start()
  
  sample_player.set_play_mode(1,0)
  lattice_grid:start()
  -- lattice_sample_sequencer:start()
  -- sequencer_lattice.init()
  params:bang()
  
  --[[
    -- sequins test
  mys = Sequins{0,2,4,7,9}
  myt = Sequins{1,1,1,1/2,1/2}
  crow.ii.pullup(true)
  crow.ii.jf.mode(1)

  function time_fn() 
    while true do 
      clock.sync(myt()) 
      -- crow.ii.jf.play_note(mys()/12,0.9) 
      crow.ii.wsyn.play_voice(1,mys()/12,0.9) 
    end
  end
  -- function time_fn() while true do crow.clock.sync(myt()) crow.ii.wsyn.play_note(mys()/12,0.9) end end

  clock.run(time_fn)
  ]]

  -- engine.set_numSegs(4)
  envelopes[1].update_envelope()
  initializing = false
  params:set("envelope1_max_time",0.25)
  sequencer_screen.init(16,8)
  -- sample_player.load_file("/home/we/dust/flora_wowless.wav")
  -- page_scroll(1)
  
  -- softcut.play(1, 1)

  
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

function g.key(x, y, z)
  encoders_and_keys.grid_key(x,y,z)  
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
      --print("update")
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
  if _print then print = _print end
  print("cleanup")
  metro.free_all()
  os.execute("jack_disconnect softcut:output_1 SuperCollider:in_1;")  
  os.execute("jack_disconnect softcut:output_2 SuperCollider:in_2;")
  os.execute("jack_connect crone:output_5 SuperCollider:in_1;")  
  os.execute("jack_connect crone:output_6 SuperCollider:in_2;")
end

