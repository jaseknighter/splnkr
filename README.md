# splnkr
 amplitude tracking sequencer/sampler for monome norns

## installation from maiden
`;install https://github.com/jaseknighter/splnkr`

(restart after installing)

### IMPORTANT: prior to running the splnkr script:
* ssh into norns:
  * open a terminal/powershell
  * ssh to norns (`ssh we@norns.local`) and login
  * run this code to reset, recompile, and reconnect jacks: 
  `~/norns/stop.sh; sleep 1; ~/norns/start.sh; sleep 9; jack_disconnect crone:output_5 SuperCollider:in_1; jack_disconnect crone:output_6 SuperCollider:in_2; jack_connect softcut:output_1 SuperCollider:in_1; jack_connect softcut:output_2 SuperCollider:in_2`
## norns audio outputs
* left output sends dry signal with pinknoise generated when an amplitude onset is detected
* right output sends the processed signal after applying parameters set on screen 3

## crow outputs
crow outputs 1-4 send triggers corresponding to different amplitude levels detected by supercollider

* output 1: levels > 0.001
* output 2: levels > 0.001 and < 0.05
* output 3: levels >= 0.05 and < 0.01
* output 4: levels >= 0.01

values triggering the crow outputs can be adjusted in the [splunkr.lua](https://github.com/jaseknighter/splnkr/blob/main/splnkr.lua) (search for `detect_level` in the code)

## sample file
a different sample file can be played by adding it to the lib folder and updating the following variables in the [splunkr.lua](https://github.com/jaseknighter/splnkr/blob/main/splnkr.lua) file:

* `file`: path to the sample
* `loop_start`: default starting point of the sample (in seconds)
* `loop_end`: default ending point of the sample (in seconds)

## Interface (E1 switche between pages)
### page 1: rate/length 
* E2 switch between parameters
* E3 change the value of the selected parameter
* K1+E3: fine tune the value of the selected parameter

### page 2: waveform
* displays the selected waveform (keys/encoders don't change anything...yet)

### page 3: effects (+ dry/wet control)
* E2 switch between parameters
* E3 change the value of the selected effect
  * Note: a value of 0 turns off the selected effect 
* K1+E3: fine tune the value of the selected effect

## todo
* build out a sampler sequencer
* add a frequency follower
* augment supercollider effects processor
* additional features tbd

## credits
splnkr leverages the [stonesoup](https://github.com/schollz/stonesoup) script developed by @infinitedigits/@schollz