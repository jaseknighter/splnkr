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
    grid_sequencer:register_ui_group("sequin_groups1",1,1,1,1,7,SEQUIN_GROUP_OFF_LEVEL)
    grid_sequencer:register_ui_group("sequin_groups2",2,1,2,1,7,SEQUIN_GROUP_OFF_LEVEL)
    grid_sequencer:register_ui_group("sequin_groups3",3,1,3,1,7,SEQUIN_GROUP_OFF_LEVEL)
    grid_sequencer:register_ui_group("sequin_groups4",4,1,4,1,7,SEQUIN_GROUP_OFF_LEVEL)
    grid_sequencer:register_ui_group("sequin_groups5",5,1,5,1,7,SEQUIN_GROUP_OFF_LEVEL)
    
    
    print("grid found with " .. grid_filter.last_known_width .. " columns")
    grid_filter_clock_id = clock.run(grid_filter.grid_redraw_clock)
    grid_sequencer_clock_id = clock.run(grid_sequencer.grid_redraw_clock)
    
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
    envelopes[i].set_active(active)
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

  polling.init()

  lattice_grid = Lattice:new{
    auto = true,
    meter = 4,
    ppqn = 96
  }
  
  grid_pattern = lattice_grid:new_pattern{
    action = function(t) 
        grid_filter:animate() 
    end,
    division = 1/32, --1/16,
    enabled = true
  }
 
  clock.run(finish_init)
end


function finish_init()
  engine.splnk(0)
  clock.sleep(0.5)
  -- params:set("reverb",1)

  amplitude_detect_poll:start()
  onset_amplitude_detect_poll:start()
  frequency_detect_poll:start()
  
  sample_player.set_play_mode(1,0)
  lattice_grid:start()
  params:bang()

  envelopes[1].update_envelope()
  envelopes[2].update_envelope()
  initializing = false
  params:set("envelope1_max_time",0.25)
  params:set("envelope2_max_time",0.25)
  sequencer_screen.init(16,8)
end

--------------------------
-- encoders and keys
--------------------------
function enc(n, d)
  if initializing == false then
    encoders_and_keys.enc(n, d)
  -- redraw()

  end
end

function key(n,z)
  if initializing == false then
    encoders_and_keys.key(n, z)
  -- redraw()
  end

end

function g.key(x, y, z)
  encoders_and_keys.grid_key(x,y,z)  
end

--------------------------
-- redraw 
--------------------------
function set_redraw_timer()
  redrawtimer = metro.init(function() 
    if initializing == false then
      for i=1,num_envelopes,1 do
        envelopes[i].modulate_env()
      end
    end
    menu_status = norns.menu.status()
    if menu_status == false and initializing == false and sample_player.selecting == false then
      -- sample_player.update()
  
      --print("update")
      controller.update_pages()
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

