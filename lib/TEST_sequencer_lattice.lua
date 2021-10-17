-- from tyler etter's *hearts_in_need_make_symphonies.lua*: https://gist.github.com/tyleretters/a62a27e22dc7021248401f8572287544

-- @author tyleretters & ezra & zack & jaseknighter

--- learning jf
lattice_sequins = {}

function lattice_sequins.init()
  example_data = {}
  a = 1/2
  b = 1/4
  c = 1/8
  d = 1/16
  e = 3/4

  time_crystal        = crow.sequins{ 1,  2,  1,  2}
  chord_crystal       = crow.sequins{ 1,  2,  3,  4}
  ennui_crystal       = crow.sequins{ b,  b,  b,  1,  1,  1,  1,  a,  a,  e,  b}
  stable_crystal      = crow.sequins{ 1,  1,  a,  1,  a}

  --print("ennui_crystal...",ennui_crystal)
  hearts_in_need_make_syphonies = {}
  hearts_in_need_make_syphonies[1] = {0, 3, 7}
  hearts_in_need_make_syphonies[2] = {0, 3, 5}
  hearts_in_need_make_syphonies[3] = {0, 5, 7}
  hearts_in_need_make_syphonies[4] = {0, 5, 9}

  chimes_on_the_forests_edge = crow.sequins{7, 7, 3, 3, 0, 0, 0}
  lost_in_the_smoke = crow.sequins{2, 2, 5, 3, 2, 2, 5, 7}

  example_data.switch = 1
  example_data.root = -1
  example_data.octave = 0
  example_data.default_level = 5
  example_data.semitone = 0.08333333
  crow.output[1].slew = 0
  crow.output[2].slew = 0
  crow.output[3].slew = 0 
  crow.output[4].slew = 0
  crow.tempo = 80
  crow.ii.pullup(true)
  crow.ii.jf.mode(1)


  clock_of_lost_dreams = Lattice:new{
      auto = true,
      meter = 4,
      ppqn = 96
  }
  chord_lattice = clock_of_lost_dreams:new_pattern{
      action = function(t) chord_event() end,
      division = 1,
      enabled = true
  }
  ennui_lattice = clock_of_lost_dreams:new_pattern{
      action = function(t) ennui_event() end,
      division = 1/4,
      enabled = true
  }

  clock_of_lost_dreams:start()

end

function chord_event()
    chord_lattice:set_division(time_crystal())
    play_chord(hearts_in_need_make_syphonies[chord_crystal()])
end

function ennui_event()
    ennui_lattice:set_division(ennui_crystal())
    crow.output[1].volts = (get_ennui_event() * example_data.semitone) + example_data.octave + example_data.root
    crow.output[2].action = pulse()
    crow.output[2]()
end

function get_ennui_event()
    if example_data.switch == 1 then
        return chimes_on_the_forests_edge()
    else
        return lost_in_the_smoke()
    end
end

function set_root(r)
    example_data.root = r
end

function set_octave(o)
    example_data.octave = o
end

function jf(semitone, level)
    l = level and level or example_data.default_level
    crow.ii.jf.play_note((semitone * example_data.semitone) + example_data.octave + example_data.root, l)
end

function play_chord(t)
    for k, v in pairs(t) do
      crow.ii.jf(v)
    end
end

return lattice_sequins