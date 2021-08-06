-- required and included files

MusicUtil = require "musicutil"
tabutil = require "tabutil"
UI = require "ui"
fileselect = require 'fileselect'
textentry= require 'textentry'
cs = require 'controlspec'

_grid = include("lib/_grid")

w_slash = include "flora/lib/w_slash"
include("splnkr/lib/midi_helper")

vector = include("flora/lib/vector")
ArbGraph = include("flora/lib/ArbitraryGraph")


envelope = include "splnkr/lib/envelope"

externals = include "splnkr/lib/externals"
globals = include "splnkr/lib/globals"
encoders_and_keys = include "splnkr/lib/encoders_and_keys"
controller = include("splnkr/lib/controller")

sample_player = include "splnkr/lib/sample_player"
sample_recorder = include "splnkr/lib/sample_recorder"
include "clipper/lib/Cutter"

parameters = include("splnkr/lib/parameters")
