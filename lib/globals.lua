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
  local result = {}
  if delimiter then
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
  else
    print("no delimiter")
    return 1
  end
end

function fn.fraction_to_decimal(fraction)
  local fraction_tab = fn.get_table_from_string(fraction,"/")
  if #fraction_tab == 2 then
    return fraction_tab[1]/fraction_tab[2]
  else
    return fraction
  end
end

-- morphing function
-- note: the last two parameters are "private" to the function and don't need to included in the inital call to the function
-- example: `morph(my_callback_function,1,10,2,10,"log")`
function fn.morph(callback,s_val,f_val,duration,steps,shape, steps_remaining, next_val)
  local start_val = s_val < f_val and s_val or f_val
  local finish_val = s_val < f_val and f_val or s_val
  local increment = (finish_val-start_val)/steps
  if next_val and steps_remaining < steps then
    local delay = duration/steps
    clock.sleep(delay)
    local return_val = next_val
    if s_val ~= f_val then
      callback(return_val)
    else
      callback(s_val)
    end
  end
  local steps_remaining = steps_remaining and steps_remaining - 1 or steps 
  
  if steps_remaining >= 0 then
    local value_to_convert
    if next_val == nil then
      value_to_convert = start_val
    elseif s_val < f_val then
      -- value_to_convert = next_val and s_val + ((steps-steps_remaining) * increment) 
      value_to_convert = next_val and start_val + ((steps-steps_remaining) * increment) 
    else
      value_to_convert = next_val and finish_val - ((steps-steps_remaining) * increment) 
    end 

    if shape == "exp" then
      next_val = util.linexp(start_val,finish_val,start_val,finish_val, value_to_convert)
    elseif shape == "log" then
      next_val = util.explin(start_val,finish_val,start_val,finish_val, value_to_convert)
    else
      next_val = util.linlin(start_val,finish_val,start_val,finish_val, value_to_convert)
    end
    clock.run(fn.morph,callback,s_val,f_val,duration,steps,shape, steps_remaining,next_val)
  end
end



-- scale/note/quantize functions
SCALE_LENGTH_DEFAULT = 45 
ROOT_NOTE_DEFAULT = 33 --(A0)
NOTE_OFFSET_DEFAULT = 33 --(A0)
scale_names = {}
notes = {}
current_note_indices = {}

for i= 1, #MusicUtil.SCALES do
  table.insert(scale_names, string.lower(MusicUtil.SCALES[i].name))
end

fn.build_scale = function()
  notes = {}
  notes = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), params:get("scale_length"))
  -- local num_to_add = SCALE_LENGTH_DEFAULT - #notes
  local scale_length = params:get("scale_length") and params:get("scale_length") or SCALE_LENGTH_DEFAULT
  -- for i = 1, num_to_add do
  for i = 1, scale_length do
    table.insert(notes, notes[scale_length])
    -- table.insert(notes, notes[SCALE_LENGTH_DEFAULT - num_to_add])
  end
  -- engine.update_scale(table.unpack(notes))
end

fn.get_num_notes_per_octave = function()
  -- local num_notes_per_octave
  if initializing == false and params:get("scale_length") < 12 then
    return params:get("scale_length") 
  else
    local starting_note = notes[1]
    for i=2,#notes,1 do
      if notes[i]-starting_note < 12 then
        -- do nothing
      else
        return i-1
      end
    end
  end
end

fn.quantize = function(note_num)
  local new_note_num
  for i=1,#notes-1,1 do
    if note_num >= notes[i] and note_num <= notes[i+1] then
      if note_num - notes[i] < notes[i+1] - note_num then
        new_note_num = notes[i]
      else
        new_note_num = notes[i+1]
      end
      break
    end
  end
  -- if new_note_num == nil then 
  --   if note_num < notes[1] then 
  --     new_note_num = notes[1]
  --   else
  --     new_note_num = notes[#notes]
  --   end
  -- end
  return new_note_num
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

MAX_CUTTERS = 10
MIN_CUT_SPACING = 1
OUTPUT_TYPES = {"softcut","devices","effects","time"}
PPQN_OPTIONS = {12,24,36,48,60,72,84,96,108}
TIME_OPTIONS = {"1/8","1/4","1/3","1/2","3/4","1","4/3","3/2","2"}
MORPH_DURATIONS = {"1/4","1/3","1/2","1","3/2","2","3","4","5"}
MORPH_SHAPES = {"lin","exp","log"}

g = grid.connect()
grid_mode = "filter"
grid_long_press_length = 0.5
NUM_PAGES = (g.cols ~= nil and g.cols >= 16) and 3 or 2
show_instructions = false
updating_controls = false
OUTPUT_DEFAULT = 4
SCREEN_FRAMERATE = 1/30
menu_status = false
pages = 0

alt_key_active = false
screen_level_graphics = 15
screen_size = {x=127,y=64}

menu_status = norns.menu.status()
clear_subnav = true
screen_dirty = true
show_instructions = false

initializing = true
saving = false
saving_elipses = ""
pre_save_play_mode = false

sequencer_playing = false
SEQUIN_GROUP_OFF_LEVEL = 3
DEFAULT_SUB_SEQUINS_TAB = {"","","","",""}
num_sub_steps = #DEFAULT_SUB_SEQUINS_TAB
starting_sub_step = 1

max_sub_seq_repeats = 3

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
--      set by DEFAULT_GRAPH_NODES and DEFAULT_GRAPH_NODES_P2
--      do not exceed the settings for AMPLITUDE_DEFAULT and ENV_LENGTH_DEFAULT
-----------------------------------------
envelopes = {}
active_envelope = 1
num_envelopes = 2

envelope1_times = {"envelope1_time1","envelope1_time2","envelope1_time3","envelope1_time4","envelope1_time5","envelope1_time6","envelope1_time7","envelope1_time8"}
envelope1_levels = {"envelope1_level1","envelope1_level2","envelope1_level3","envelope1_level4","envelope1_level5","envelope1_level6","envelope1_level7","envelope1_level8"}
envelope1_curves = {"envelope1_curve1","envelope1_curve2","envelope1_curve3","envelope1_curve4","envelope1_curve5","envelope1_curve6","envelope1_curve7","envelope1_curve8"}

envelope2_times = {"envelope2_time1","envelope2_time2","envelope2_time3","envelope2_time4","envelope2_time5","envelope2_time6","envelope2_time7","envelope2_time8"}
envelope2_levels = {"envelope2_level1","envelope2_level2","envelope2_level3","envelope2_level4","envelope2_level5","envelope2_level6","envelope2_level7","envelope2_level8"}
envelope2_curves = {"envelope2_curve1","envelope2_curve2","envelope2_curve3","envelope2_curve4","envelope2_curve5","envelope2_curve6","envelope2_curve7","envelope2_curve8"}


MAX_AMPLITUDE = 10
MAX_ENV_LENGTH = 2
CURVE_MIN = -10 -- -50
CURVE_MAX = 10 --50
MAX_ENVELOPE_NODES = 8
ENV_TIME_MAX = 2 -- DO NOT CHANGE

AMPLITUDE_DEFAULT = 9
ENV_LENGTH_DEFAULT = 0.2

DEFAULT_GRAPH_NODES = {}
DEFAULT_GRAPH_NODES[1] = {}
DEFAULT_GRAPH_NODES[1].time = 0.00
DEFAULT_GRAPH_NODES[1].level = 0.00
DEFAULT_GRAPH_NODES[1].curve = 0.00
DEFAULT_GRAPH_NODES[2] = {}
DEFAULT_GRAPH_NODES[2].time = 0.01
DEFAULT_GRAPH_NODES[2].level = 5
DEFAULT_GRAPH_NODES[2].curve = -10
DEFAULT_GRAPH_NODES[3] = {}
DEFAULT_GRAPH_NODES[3].time = 0.15
DEFAULT_GRAPH_NODES[3].level = 0.00
DEFAULT_GRAPH_NODES[3].curve = -10

-- for envelope mods
show_env_mod_params = false
env_nav_active_control = 1

env_mod_param_labels = {
  "set mod prob",
  "time prob",
  "time mod amt",
  "level prob",
  "level mod amt",
  "curve prob",
  "curve mod amt",
}

env_mod_param_ids = {
   "randomize_env_probability", 
   "time_probability", 
   "time_modulation", 
   "level_probability", 
   "level_modulation",
   "curve_probability",
   "curve_modulation", 
}