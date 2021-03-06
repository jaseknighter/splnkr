-- required and included files

MusicUtil = require "musicutil"
tabutil = require "tabutil"
UI = require "ui"
fileselect = require "fileselect"
textentry= require "textentry"
cs = require "controlspec"
Lattice = require "lattice"
Sequins = require "sequins"
-- Sequins = include "splnkr/lib/Sequins"

globals = include "splnkr/lib/globals"
grid_filter = include "lib/grid_filter"
grid_sequencer = include "lib/grid_sequencer"
sequencer_controller = include "lib/sequencer_controller"
w_slash = include "splnkr/lib/w_slash"
include "splnkr/lib/midi_helper"

ArbGraph = include "splnkr/lib/ArbitraryGraph"


envelope = include "splnkr/lib/envelope"

polling = include "splnkr/lib/polling"

externals = include "splnkr/lib/externals"
encoders_and_keys = include "splnkr/lib/encoders_and_keys"
controller = include "splnkr/lib/controller"
sample_player = include "splnkr/lib/sample_player"
sample_player_live = include "splnkr/lib/sample_player_live"
sample_recorder = include "splnkr/lib/sample_recorder"
recsamp_processor = include "splnkr/lib/sequin_processors/recsamp_processor"
livsamp_processor = include "splnkr/lib/sequin_processors/livsamp_processor"
devices_processor = include "splnkr/lib/sequin_processors/devices_processor"
devices_midi_processor = include "splnkr/lib/sequin_processors/devices_midi_processor"
devices_crow_processor = include "splnkr/lib/sequin_processors/devices_crow_processor"
devices_jf_processor = include "splnkr/lib/sequin_processors/devices_jf_processor"
devices_w_processor = include "splnkr/lib/sequin_processors/devices_w_processor"
effects_processor = include "splnkr/lib/sequin_processors/effects_processor"
time_processor = include "splnkr/lib/sequin_processors/time_processor"

sequin_processor = include "splnkr/lib/sequin_processor"

Sequin = include "splnkr/lib/Sequin"
Sequinset = include "splnkr/lib/Sequinset"
Sequencer= include "splnkr/lib/Sequencer"
sequencer_screen = include "splnkr/lib/sequencer_screen"


-- sequencer_lattice = include "splnkr/lib/sequencer_lattice"

include "splnkr/lib/Cutter"
CutDetector = include "splnkr/lib/CutDetector"

save_load = include "splnkr/lib/save_load"
parameters = include "splnkr/lib/parameters"
instructions = include "splnkr/lib/instructions"

