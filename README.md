# splnkr
 amplitude tracking sequencer/sampler for monome norns

*additional documentation in progress*

*warning*: animating the center frequency with the grid interface can result in loud percussive sounds. use caution!

## installation from maiden
`;install https://github.com/jaseknighter/splnkr`

(restart after installing)

### IMPORTANT: prior to running the splnkr script:
* open a terminal/powershell
* ssh to norns (`ssh we@norns.local`) and login
* run this code to reset, recompile, and reconnect jacks: 

  ```~/norns/stop.sh; sleep 1; ~/norns/start.sh; sleep 9; jack_disconnect crone:output_5 SuperCollider:in_1; jack_disconnect crone:output_6 SuperCollider:in_2; jack_connect softcut:output_1 SuperCollider:in_1; jack_connect softcut:output_2 SuperCollider:in_2```

### norns ui: key/encoder controls
access instructions for key/encoder controls within the script by pressing k1+e3

* All screens
  * e2: next/prev control
* Screen 1: select/play sample 
  * k2: select sample to slice up
  * e3: incr/decr playhead
  * k3: start/stop playhead
* Screen 2: play mode
  * k2/k3: delete/add cutter
  * e3: change play mode
* Screen 3: adjust cut ends
  * k2/k3: delete/add cutter
  * k1 + e2: select cutter
  * k1 + e3: adjust cutter
  * k1 + e1: fine adjust cutter
  * e3: select cutter end
* Screen 4: move cutter
  * k2/k3: delete/add cutter
  * k1 + e2: select cutter
  * k1 + e3: adjust cutter
  * k1 + e1: fine adjust cutter
* Screen 5: adjust rate
  * k2/k3: delete/add cutter
  * k1 + e2: select rate
  * e3: adjust all cutter rates
  * k1 + e1: fine adjust rate
  * k1 + e3: adjust selected cutter rate
* Screen 6: adjust level
  * k2/k3: delete/add cutter
  * e3: adjust level
* Screen 7: autogenerate cutters
  * e3: autogenerate clips by level (up to 20)
  * k1 + e3: autogenerate clips with even spacing (up to 20)

### recording clips
clips may be recorded from the PARAMETERS>EDIT menu. what gets recorded depends on the `play mode` setting:
* *stop*: record the entire sample 
* *full loop*: record the entire sample 
* *all cuts*: record all sample areas set by cutters
* *sel cut*: record the sample area set by the selected cutter

*important note*: if *play mode* is set to `all cuts`, all *rate* settings must either be positive or negative. 

## filterbank/grid interface

parameters for the 16 channel filterbank may be controlled via the params menu or using the grid

each channel has three parameters: 
* channel level (amp)
* reciprocal quality (rq)
* center frequency (cf)

### grid controls
each of the three parameters may be accessed using by toggling between first three buttons on the grid's bottom row 

the fifth and sixth buttons on the grid's bottom row control animation options for each of the three filter channel parameters:

button 5: pressing this button sweeps the values of each channel to the left cycling the values around to the far right channel after the values pass by the far left channel. if lit, pressing the button again turns off the animation.
button 6: pressing this button sweeps the values of each channel to the upwards, cycling back to the channel's min value when the max value is reached. if lit, pressing the button again turns off the animation.

## effects


## outputs 

midi, crow, jf, and w/ outputs are avaiable in the params menu

## envelope

the second screen (accessed with E1) provides access to an envelope that is applied to the outputs

## todo
* integrate shell commands to reconfigure norns audio signal paths into the script
* build out a sampler sequencer
* add a frequency follower
* augment supercollider effects processor
* additional features tbd

## credits
* splnkr leverages the [stonesoup](https://github.com/schollz/stonesoup) script developed by @infinitedigits/@schollz
* this project was inspired by the [lines discussion](https://llllllll.co/t/re-deconstructing-jan-jelineks-zwischen/46577/4) about Jan Jelinek’s album “Zwischen” initiated by Matt Lowery