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

vector = include "splnkr/lib/vector"
globals = include "splnkr/lib/globals"
grid_filter = include "lib/grid_filter"
grid_sequencer = include "lib/grid_sequencer"
sequencer_controller = include "lib/sequencer_controller"
w_slash = include "splnkr/lib/w_slash"
include "splnkr/lib/midi_helper"

ArbGraph = include "flora/lib/ArbitraryGraph"


envelope = include "splnkr/lib/envelope"

externals = include "splnkr/lib/externals"
encoders_and_keys = include "splnkr/lib/encoders_and_keys"
controller = include "splnkr/lib/controller"
sample_player = include "splnkr/lib/sample_player"
sample_recorder = include "splnkr/lib/sample_recorder"

devices_processor = include "splnkr/lib/sequin_processors/devices_processor"
softcut_processor = include "splnkr/lib/sequin_processors/softcut_processor"
devices_midi_processor = include "splnkr/lib/sequin_processors/devices_midi_processor"
devices_crow_processor = include "splnkr/lib/sequin_processors/devices_crow_processor"
devices_jf_processor = include "splnkr/lib/sequin_processors/devices_jf_processor"
devices_w_processor = include "splnkr/lib/sequin_processors/devices_w_processor"

sequin_processor = include "splnkr/lib/sequin_processor"

Sequin = include "splnkr/lib/Sequin"
Sequinset = include "splnkr/lib/Sequinset"
Sequencer= include "splnkr/lib/Sequencer"
sequencer_screen = include "splnkr/lib/sequencer_screen"


-- sequencer_lattice = include "splnkr/lib/sequencer_lattice"

include "splnkr/lib/Cutter"
cut_detector = include "splnkr/lib/cut_detector"

save_load = include "splnkr/lib/save_load"
parameters = include "splnkr/lib/parameters"
instructions = include "splnkr/lib/instructions"

