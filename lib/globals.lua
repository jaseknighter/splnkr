------------------------------
-- global functions
------------------------------

-- here's a version that handles recursive tables here:
--  http://lua-users.org/wiki/CopyTable
fn = {}

-- from: https://stackoverflow.com/questions/132397/get-back-the-output-of-os-execute-in-lua
function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ',')
  return s
end

function fn.deep_copy(orig, copies)
  copies = copies or {}
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      if copies[orig] then
          copy = copies[orig]
      else
          copy = {}
          copies[orig] = copy
          for orig_key, orig_value in next, orig, nil do
              copy[fn.deep_copy(orig_key, copies)] = fn.deep_copy(orig_value, copies)
          end
          setmetatable(copy, fn.deep_copy(getmetatable(orig), copies))
      end
  else -- number, string, boolean, etc
      copy = orig
  end
  return copy
end

function fn.round_decimals (value_to_round, num_decimals, rounding_direction)
  local rounded_val
  local mult = 10^num_decimals
  if rounding_direction == "up" then
    rounded_val = math.floor(value_to_round * mult + 0.5) / mult
  else
    rounded_val = math.floor(value_to_round * mult + 0.5) / mult
  end
  return rounded_val
end


function fn.get_table_from_string(str,delimiter)
  local result = {};
  for match in (str..delimiter):gmatch("(.-)"..delimiter) do
      table.insert(result, match);
  end
  return result;
end

function fn.fraction_to_decimal(fraction)
  local fraction_tab = fn.get_table_from_string(fraction,"/")
  if #fraction_tab == 2 then
    return fraction_tab[1]/fraction_tab[2]
  else
    return fraction
  end
end



-- scale/note functions
scale_length = 35 --128
root_note_default = 33 --(A0)
note_center_frequency_default = 43 --45
scale_names = {}
notes = {}
current_note_indices = {}

for i= 1, #MusicUtil.SCALES do
  table.insert(scale_names, string.lower(MusicUtil.SCALES[i].name))
end

fn.build_scale = function()
  notes = {}
  notes = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), scale_length)
  local num_to_add = scale_length - #notes
  for i = 1, num_to_add do
    table.insert(notes, notes[scale_length - num_to_add])
  end
  -- engine.update_scale(table.unpack(notes))
end

fn.set_scale_length = function()
  scale_length = params:get("scale_length")
end

fn.get_num_notes_per_octave = function()
  -- local num_notes_per_octave
  local starting_note = notes[1]
  for i=2,#notes,1 do
    if notes[i]-starting_note < 12 then
      -- do nothing
    else
      return i-1
    end
  end
end

fn.round_decimals = function (value_to_round, num_decimals, rounding_direction)
  local rounded_val
  local mult = 10^num_decimals
  if rounding_direction == "up" then
    rounded_val = math.floor(value_to_round * mult + 0.5) / mult
  else
    rounded_val = math.floor(value_to_round * mult + 0.5) / mult
  end
  return rounded_val
end

-------------------------------------------
-- global variables
-------------------------------------------

MAX_CUTTERS = 12

g = grid.connect()
grid_mode = "filter"
grid_long_press_length = 0.5
NUM_PAGES = 3
show_instructions = false
updating_controls = false
OUTPUT_DEFAULT = 4
SCREEN_FRAMERATE = 1/10
menu_status = false
pages = 0

alt_key_active = false
screen_level_graphics = 15
screen_size = vector:new(127,64)
center = vector:new(screen_size.x/2, screen_size.y/2)

menu_status = norns.menu.status()
clear_subnav = true
screen_dirty = true
show_instructions = false

initializing = true
saving = false
saving_elipses = ""
pre_save_play_mode = false

sequencer_playing = false
DEFAULT_SUB_SEQUINS_TAB = {"","","","",""}

midi_in_channel1_default = 1
midi_in_command1 = 144
midi_devices = nil
MIDI_DURATIONS = {"0","1","1/2","1/4","1/8","1/16"}
-- NOTE_REPEAT_FREQUENCIES = {'1','1/2','1/4','1/8','1/16','1/3','2/3','3/8','5/8'}
NOTE_REPEAT_FREQUENCIES = {'0','1','2','3','4','5','6','7','8'}


cs_level = controlspec.AMP:copy()
cs_level.maxval = 5


-----------------------------------------
-- ENVELOPES
-- IMPORTANT NOTE: when changing AMPLITUDE_DEFAULT or ENV_LENGTH_DEFAULT
--    Make sure the 'level' and 'time' variables for each envelope node 
--      set by DEFAULT_GRAPH_NODES_P1 and DEFAULT_GRAPH_NODES_P2
--      do not exceed the settings for AMPLITUDE_DEFAULT and ENV_LENGTH_DEFAULT
-----------------------------------------
envelopes = {}
active_envelope = 1
num_envelopes = 1

envelope1_times = {"envelope1_time1","envelope1_time2","envelope1_time3","envelope1_time4","envelope1_time5","envelope1_time6","envelope1_time7","envelope1_time8"}
envelope1_levels = {"envelope1_level1","envelope1_level2","envelope1_level3","envelope1_level4","envelope1_level5","envelope1_level6","envelope1_level7","envelope1_level8"}
envelope1_curves = {"envelope1_curve1","envelope1_curve2","envelope1_curve3","envelope1_curve4","envelope1_curve5","envelope1_curve6","envelope1_curve7","envelope1_curve8"}

-- envelope1_times = {"envelope1_time1","envelope1_time2","envelope1_time3","envelope1_time4","envelope1_time5","envelope1_time6","envelope1_time7","envelope1_time8","envelope1_time9","envelope1_time10","envelope1_time11","envelope1_time12","envelope1_time13","envelope1_time14","envelope1_time15","envelope1_time16","envelope1_time17","envelope1_time18","envelope1_time19","envelope1_time20"}
-- envelope1_levels = {"envelope1_level1","envelope1_level2","envelope1_level3","envelope1_level4","envelope1_level5","envelope1_level6","envelope1_level7","envelope1_level8","envelope1_level9","envelope1_level10","envelope1_level11","envelope1_level12","envelope1_level13","envelope1_level14","envelope1_level15","envelope1_level16","envelope1_level17","envelope1_level18","envelope1_level19","envelope1_level20"}
-- envelope1_curves = {"envelope1_curve1","envelope1_curve2","envelope1_curve3","envelope1_curve4","envelope1_curve5","envelope1_curve6","envelope1_curve7","envelope1_curve8","envelope1_curve9","envelope1_curve10","envelope1_curve11","envelope1_curve12","envelope1_curve13","envelope1_curve14","envelope1_curve15","envelope1_curve16","envelope1_curve17","envelope1_curve18","envelope1_curve19","envelope1_curve20"}

-- plow2_times = {"plow2_time1","plow2_time2","plow2_time3","plow2_time4","plow2_time5","plow2_time6","plow2_time7","plow2_time8","plow2_time9","plow2_time10","plow2_time11","plow2_time12","plow2_time13","plow2_time14","plow2_time15","plow2_time16","plow2_time17","plow2_time18","plow2_time19","plow2_time20"}
-- plow2_levels = {"plow2_level1","plow2_level2","plow2_level3","plow2_level4","plow2_level5","plow2_level6","plow2_level7","plow2_level8","plow2_level9","plow2_level10","plow2_level11","plow2_level12","plow2_level13","plow2_level14","plow2_level15","plow2_level16","plow2_level17","plow2_level18","plow2_level19","plow2_level20"}
-- plow2_curves = {"plow2_curve1","plow2_curve2","plow2_curve3","plow2_curve4","plow2_curve5","plow2_curve6","plow2_curve7","plow2_curve8","plow2_curve9","plow2_curve10","plow2_curve11","plow2_curve12","plow2_curve13","plow2_curve14","plow2_curve15","plow2_curve16","plow2_curve17","plow2_curve18","plow2_curve19","plow2_curve20"}


MAX_AMPLITUDE = 10
MAX_ENV_LENGTH = 2
CURVE_MIN = -10 -- -50
CURVE_MAX = 10 --50
MAX_ENVELOPE_NODES = 8
ENV_TIME_MAX = 2 -- DO NOT CHANGE

AMPLITUDE_DEFAULT = 9
ENV_LENGTH_DEFAULT = 0.2

DEFAULT_GRAPH_NODES_P1 = {}
DEFAULT_GRAPH_NODES_P1[1] = {}
DEFAULT_GRAPH_NODES_P1[1].time = 0.00
DEFAULT_GRAPH_NODES_P1[1].level = 0.00
DEFAULT_GRAPH_NODES_P1[1].curve = 0.00
DEFAULT_GRAPH_NODES_P1[2] = {}
DEFAULT_GRAPH_NODES_P1[2].time = 0.1
DEFAULT_GRAPH_NODES_P1[2].level = 5
DEFAULT_GRAPH_NODES_P1[2].curve = -10
DEFAULT_GRAPH_NODES_P1[3] = {}
DEFAULT_GRAPH_NODES_P1[3].time = 0.15
DEFAULT_GRAPH_NODES_P1[3].level = 0.00
DEFAULT_GRAPH_NODES_P1[3].curve = -10

-- DEFAULT_GRAPH_NODES_P1 = {}
-- DEFAULT_GRAPH_NODES_P1[1] = {}
-- DEFAULT_GRAPH_NODES_P1[1].time = 0.00
-- DEFAULT_GRAPH_NODES_P1[1].level = 0.00
-- DEFAULT_GRAPH_NODES_P1[1].curve = 0.00
-- DEFAULT_GRAPH_NODES_P1[2] = {}
-- DEFAULT_GRAPH_NODES_P1[2].time = 0.00
-- DEFAULT_GRAPH_NODES_P1[2].level = 4.0
-- DEFAULT_GRAPH_NODES_P1[2].curve = -10
-- DEFAULT_GRAPH_NODES_P1[3] = {}
-- DEFAULT_GRAPH_NODES_P1[3].time = 0.50
-- DEFAULT_GRAPH_NODES_P1[3].level = 0.50
-- DEFAULT_GRAPH_NODES_P1[3].curve = -10
-- DEFAULT_GRAPH_NODES_P1[4] = {}
-- DEFAULT_GRAPH_NODES_P1[4].time = 1.00
-- DEFAULT_GRAPH_NODES_P1[4].level = 1.5
-- DEFAULT_GRAPH_NODES_P1[4].curve = -10
-- DEFAULT_GRAPH_NODES_P1[5] = {}
-- DEFAULT_GRAPH_NODES_P1[5].time = 1.5
-- DEFAULT_GRAPH_NODES_P1[5].level = 0.00
-- DEFAULT_GRAPH_NODES_P1[5].curve = -10

-- DEFAULT_GRAPH_NODES_P2 = {}
-- DEFAULT_GRAPH_NODES_P2[1] = {}
-- DEFAULT_GRAPH_NODES_P2[1].time = 0.00
-- DEFAULT_GRAPH_NODES_P2[1].level = 0.00
-- DEFAULT_GRAPH_NODES_P2[1].curve = 0.00
-- DEFAULT_GRAPH_NODES_P2[2] = {}
-- DEFAULT_GRAPH_NODES_P2[2].time = 0.00
-- DEFAULT_GRAPH_NODES_P2[2].level = 4.0
-- DEFAULT_GRAPH_NODES_P2[2].curve = -10
-- DEFAULT_GRAPH_NODES_P2[3] = {}
-- DEFAULT_GRAPH_NODES_P2[3].time = 1.5
-- DEFAULT_GRAPH_NODES_P2[3].level = 0.00
-- DEFAULT_GRAPH_NODES_P2[3].curve = -10