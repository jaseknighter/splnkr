---splnkr

-- <version> @jaseknighter
-- lines: llllllll.co/t/<lines thread id>
--
-- <script description>

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

issues:
* sound cuts out if env length is too long when enveloper is activated
* pan_type and pan_max params don't do anything (issue with the `Out` statement in sc I think)
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
  else
    print("no grid found")
  end
  

  

  --[[
  lattice_sequencer = Lattice:new{
    auto = true,
    meter = 4,
    ppqn = 96
  }

  sequencers = {}
  sequencers[1] = Sequencer:new()
  
  lattice_sample_sequencer = Lattice:new{
    auto = true,
    meter = 4,
    ppqn = 96
  }
  
  sample_pattern1 = lattice_sample_sequencer:new_pattern{
    action = function(t) 
      sample_pattern1_event()
    end,
    division = 1/4, --1/16,
    enabled = true
  }

  seq1 = Sequins{ 1,  1, 1, 5, 5, 4,  5,  3, 1, -2, 4}

    -- sample pattern params:
      -- start: time
      -- end: time, start + duration, note length
      -- rate: -5,5

  function sample_pattern1_event()

    -- params:set("play_sequencer",2)
    if params:get("play_sequencer") == 2 then 
      -- softcut.loop (1, 0)
      local seq_num = seq1()
      -- local start = ((seq_num-1)*20)+(120 + math.random(2))
      -- local start = ((seq_num-1)*5)+((ur_position*length))
      local start = seq_num
      sample_pattern1.division = 1/(seq_num*2)
      softcut.loop_start(1,start)
      softcut.loop_end(1,start + (0.3))
      softcut.play(1, 1)
      -- print("sample_pattern1_event",start)  
    end
  end
  ]]


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
  parameters.init_envelope_controls(1)


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
  local detect_level, note_num
  local last_note_num = 0

  amplitude_detect_poll1 = poll.set("amplitudeDetect1", function(value)
    detect_level = tonumber(value)
    print("amplitudeDetect1",value)
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
      clock.run(externals1.note_on,1, note_num, note_num, 1, nil,"engine")
    end
  end)
  frequency_detect_poll2 = poll.set("frequencyDetect2", function(value)
    note_num = value ~= 0 and MusicUtil.freq_to_note_num (value) or last_note_num
    if note_num ~= last_note_num then 
      clock.run(externals1.note_on,1, note_num, note_num, 1, nil,"engine")
    end
  end)
  frequency_detect_poll3 = poll.set("frequencyDetect3", function(value)
    note_num = value ~= 0 and MusicUtil.freq_to_note_num (value) or last_note_num
    if note_num ~= last_note_num then 
      clock.run(externals1.note_on,1, note_num, note_num, 1, nil,"engine")
    end
  end)
  frequency_detect_poll4 = poll.set("frequencyDetect4", function(value)
    note_num = value ~= 0 and MusicUtil.freq_to_note_num (value) or last_note_num
    if note_num ~= last_note_num then 
      clock.run(externals1.note_on,1, note_num, note_num, 1, nil,"engine")
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
      -- print("anim",g,g.cols)
      -- if g and g.cols > 0 then 
        grid_filter:animate() 
      -- end
    end,
    division = 1/32, --1/16,
    enabled = true
  }
 

  
  clock.run(finish_init)
end

function new_sample_load_completed()
  -- envelopes[1].update_envelope()
end

function finish_init()
  engine.start_splnkring(0)

  clock.sleep(0.2)
  
  amplitude_detect_poll1:start()
  amplitude_detect_poll2:start()
  amplitude_detect_poll3:start()
  amplitude_detect_poll4:start()
  frequency_detect_poll1:start()
  frequency_detect_poll2:start()
  frequency_detect_poll3:start()
  frequency_detect_poll4:start()

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

------------------------------
-- global functions
------------------------------
fn = {}
function fn.deep_copy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == "table" then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
        copy[fn.deep_copy(orig_key)] = fn.deep_copy(orig_value)
    end
    setmetatable(copy, fn.deep_copy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end


function cleanup ()
  if _print then print = _print end
  os.execute("jack_disconnect softcut:output_1 SuperCollider:in_1;")  
  os.execute("jack_disconnect softcut:output_2 SuperCollider:in_2;")
  os.execute("jack_connect crone:output_5 SuperCollider:in_1;")  
  os.execute("jack_connect crone:output_6 SuperCollider:in_2;")
end

