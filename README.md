# splnkr
this script is something like an amplitude/frequency tracking sequencer/sampler/effects processor for monome norns with a set of 16 grid-controlled bandpass filters. 

features to add: convolution reverb, multitap delay, a note/drum/effect sequencer.

*additional documentation in progress*

*IMPORTANT WARNING*: animating the center frequency with the grid interface can result in loud percussive sounds. use caution!

## installation from maiden
`;install https://github.com/jaseknighter/splnkr`

(restart after installing)

<!-- ### IMPORTANT: prior to running the splnkr script:
* open a terminal/powershell
* ssh to norns (`ssh we@norns.local`) and login
* run this code to reset, recompile, and reconnect jacks: 

  ```~/norns/stop.sh; sleep 1; ~/norns/start.sh; sleep 9; jack_disconnect crone:output_5 SuperCollider:in_1; jack_disconnect crone:output_6 SuperCollider:in_2; jack_connect softcut:output_1 SuperCollider:in_1; jack_connect softcut:output_2 SuperCollider:in_2``` -->

## bugs to fix (this is just a small sampling of the bugs to be found and liberated from the code)
* enveloping: 
** pan type and pan max don't work
** get rid of clicks when changing the envelope size/shape
** env length on screen 2 should change the length of the sample envelope 
* externals
** lots of little bugs related to just having one envelope (instead of the two from flora)
* samples
** sample player breaks when in `all cuts` mode and cuts have rates going in different directions (e.g. -1 and 1)


## norns ui: key/encoder controls
<!-- access instructions for key/encoder controls within the script by pressing k1+e3 -->

*Page 1: sample selector/slicer*
* All screens
  * e1: previous page 
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

*Page 2: envelope*
* e1: previous page 
<!-- * k1 + e1: select active plant   -->
* e2: select envelope control  
* e3: change envelope control value  
* k2/k3: delete/add envelope control point  

the envelope is used with/sent to external devices (crow, jf, midi, w/). 

it also sets the envelope that is built into the supercollider splnkr engine. in the params menu, use the *enveloping* param to activate live signal enveloping.

## filterbank/grid interface

parameters for the 16 channel filterbank may be controlled via the params menu or using the grid.

each filter "channel" has three parameters: 
* channel level (amp)
* reciprocal quality (rq)
* center frequency (cf)

### grid controls
*parameter adjustment*
the top 7 buttons in each row indicate the intensity of the setting for the specified parameter (i.e. none of the top 7 buttons are lit indicates lowest intensity and all 7 buttons lit means indicates highest intensity.)

selecting a button sets the intensity for the active  parameter. selecting a button that is already lit sets the parameter to its lowest value.

*toggling between parameters*
each of the three parameters listed above may be controled via the grid by toggling between first three buttons on the grid's bottom row.

*animation controls*
the 5th and 6th buttons on the grid's bottom row control animation options for each of the three filter channel parameters:

*button 5*: pressing this button sweeps the values of each channel to the left cycling the values around to the far right channel after the values pass by the far left channel. if lit, pressing the button again turns off the animation.
*button 6*: pressing this button sweeps the values of each channel to the upwards, cycling back to the channel's min value when the max value is reached. if lit, pressing the button again turns off the animation.

selecting a buttons 5 or 6 when they are already lit turns off the animation for the selected filter parameter

*parameter overlay*
selecting button 8 on the bottom row turns overlays the values of all three filter parameters over one another, making it easier to see how they interact, especially with animation turned on.

## effects

current basic effects (to be enhanced) are available in the params menu: pitchshift, phaser, delay, strobe

## audio routing
in the params menu, three options may be selected for how audio is routed to the supercollider engine:

* audio in + softcut out -> engine 
* audio in only -> engine
* softcut out only -> engine

## outputs 

midi, crow, jf, and w/ outputs are avaiable in the params menu (lots of bugs here to sort out). 

*pitch/frequency tracking*

after the wet signal is sent to the SuperCollider engine's bandpass filters, pitch and amplitude is tracked and sent back to norns, which passes the info on to external devices (midi, crow, jf, w/) depending on their (buggy) settings  
 
## recording clips
clips may be recorded from the PARAMETERS>EDIT menu. what gets recorded depends on the `play mode` setting:
* *stop*: record the entire sample 
* *full loop*: record the entire sample 
* *all cuts*: record all sample areas set by cutters
* *sel cut*: record the sample area set by the selected cutter

*important note*: if *play mode* is set to `all cuts`, all *rate* settings must either be positive or negative. 

## credits
* splnkr leverages the [stonesoup](https://github.com/schollz/stonesoup) script developed by @infinitedigits/@schollz
* this project was inspired by the [lines discussion](https://llllllll.co/t/re-deconstructing-jan-jelineks-zwischen/46577/4) about Jan Jelinek’s album “Zwischen” initiated by Matt Lowery
* additional inspirations:
  * @markeats/@markwheeler Passerby (https://github.com/markwheeler/passersby)
  * @tyleretters Dronecaster (https://llllllll.co/t/34737)
  * @dan_derks Cheat Codes 2 (https://llllllll.co/t/38414)
