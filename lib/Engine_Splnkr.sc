// CroneEngine_Splnkr
// Inspirations:
//   @infinitedigits/@schollz StoneSoup (https://github.com/schollz/stonesoup)
//   @markeats/@markwheeler Passerby (https://github.com/markwheeler/passersby)

Engine_Splnkr : CroneEngine {
  var <synth;
  var numOutValues = 2;
  var pollFunc;
  var outArray;
  var amplitudeDetectPoll1,amplitudeDetectPoll2,amplitudeDetectPoll3,amplitudeDetectPoll4;
  var frequencyDetectPoll1, frequencyDetectPoll2, frequencyDetectPoll3, frequencyDetectPoll4;

  var wobble_rpm=33;
  var wobble_amp=0.05; 
  var wobble_exp=39;
  var flutter_amp=0.03;
  var flutter_fixedfreq=6;
  var flutter_variationfreq=2;  
  
  var ampMinArray;//=Array.fill(4,{0.001});
  var ampMaxArray;//=Array.fill(4,{0.999}); 
  var freqMinArray;//=Array.fill(4,{40}); 
  var freqMaxArray;//=Array.fill(4,{1200});
  
  var cfhzmin=0.1;
  var cfhzmax=0.3;
  var rqmin=0.005;
  var rqmax=0.008;
  var lsf=200;
  var ldb=0;
  
  var cf=440;
  var rq=1;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    synth = {
      arg amp=1,bpm=120,drywet=1,
      ampMin=ampMinArray, ampMax=ampMaxArray, 
      freqMin=freqMinArray, freqMax=freqMaxArray,
      effect_phaser=0,effect_distortion=0,effect_delay=0,
      effect_bitcrush,bitcrush_bits=10,bitcrush_rate=12000, // this has parameters
      effect_strobe=0,effect_vinyl=0,effect_pitchshift=0,
      wobble_rpm=33, wobble_amp=0.05, wobble_exp=39, flutter_amp=0.03, flutter_fixedfreq=6, flutter_variationfreq=2,
      cf=440, rq=1;
      

      var wet, dry, detect,detectAmp,detectFreq;
      

      var in,freq,hasFreq,out,trig,notes,noteAdder=0; // autotune vars
    
      ampMinArray=Array.fill(4,{0.001});
      ampMaxArray=Array.fill(4,{0.999}); 
      freqMinArray=Array.fill(4,{40}); 
      freqMaxArray=Array.fill(4,{1200});


      // alt flutter and wow code
      // var signed_wobble = wobble_amp*(SinOsc.kr(wobble_rpm/60)**wobble_exp);
      // var wow = Select.kr(signed_wobble > 0, signed_wobble, 0);
      // var flutter = flutter_amp*SinOsc.kr(flutter_fixedfreq+LFNoise2.kr(flutter_variationfreq));
      // var combined_defects = 1 + wow + flutter;

      dry = SoundIn.ar([0,1]);
      wet = SoundIn.ar([0,1]);

      // bpfSig = SoundIn.ar([0,1]);
      wet = BPF.ar(wet,cf,rq);

      //autotune
      trig = Impulse.ar(5);
      notes = Dseq([0,4,5], inf);
    	# freq, hasFreq = Tartini.kr(dry);

      // TODO: what is a good order for these?
      
      // pitch shift
      wet = (wet*(1-effect_pitchshift))+(effect_pitchshift*PitchShift.ar(
        wet,
        0.1,
        // ((Demand.ar(trig, 0, notes)).midicps / freq),
        ((Demand.ar(trig, 0, notes) + 54).midicps / freq),
        0,
        0.01
      ));

      // phaser
      wet = (wet*(1-effect_phaser))+(effect_phaser*CombC.ar(wet,1,SinOsc.kr(1/7).range(500,1000).reciprocal,0.05*SinOsc.kr(1/7.1).range(-1,1)));

      // distortion
      effect_distortion = Lag.kr(effect_distortion,0.5);
      wet = (wet*(1-(effect_distortion>0)))+(wet*effect_distortion).tanh;

      // delay 
      wet = (wet*(1-effect_delay))+(effect_delay*CombC.ar(wet,5,0.2,4));
      // TODO: explode some options

      // bitcrush
      wet = (wet*(1-effect_bitcrush))+(effect_bitcrush*Decimator.ar(wet,Lag.kr(bitcrush_rate,1),Lag.kr(bitcrush_bits,1)));

      // strobe
      wet = ((effect_strobe<1)*wet)+((effect_strobe>0)*wet*SinOsc.ar(bpm/60));

      // flutter + wow
      // wet = wet * combined_defects;


      // vinyl wow + compressor
      wet=(effect_vinyl<1*wet)+(effect_vinyl>0* Limiter.ar(Compander.ar(wet,wet,0.5,1.0,0.1,0.1,1,2),dur:0.0008));
      wet =(effect_vinyl<1*wet)+(effect_vinyl>0* DelayC.ar(wet,0.01,VarLag.kr(LFNoise0.kr(1),1,warp:\sine).range(0,0.01)));                
      // TODO: add bandpass + vinyl sound for vinyl effect?

      // TODO: RLPF?

      // TODO: RHPF?

      // TODO: flanger?

      // TODO: pitch shifter?

      // TODO: greyhole?

      // TOOD: stutter?

      // TODO: your favorite ??????

      // bandpass filter
      // wet = BPF.ar(
      //   wet,
      //   {LFNoise1.kr(
      //     LFNoise1.kr(4).exprange(cfhzmin,cfhzmax)
      //   ).exprange(cfmin,cfmax)}!2,
      //   {LFNoise1.kr(0.1).exprange(rqmin,rqmax)}!2
      // );


      // amplitude based onset detection
      detect = PinkNoise.ar(
        Decay.kr(
          Coyote.kr(
            wet,
            fastMul: 0.6,
            thresh: 0.001), 
          0.2
        )
      );


      detectAmp = Amplitude.kr(detect);
      // detectFreq = freq;
      
      // outputArray to send to polls
      outArray = Array.fill(numOutValues, 0);
      outArray[0] = detectAmp; // amplitude detection
      outArray[1] = freq; // frequency
      SendReply.kr(Impulse.kr(5), '/triggerPolls', outArray);
      
      dry = dry*Lag.kr(amp*(1-drywet),1);
      // dry = dry*(1-(drywet+0.001));
      wet = wet*Lag.kr(amp*drywet,1);
      // wet = wet*(drywet+0.001);
      // Out.ar(0, [detect, wet]);
      // Out.ar(0, Mix.new([dry*0.5, wet*0.5]));
      Out.ar(0,Balance2.ar(dry*0.5, wet*0.5, 0));
    }.play( target: context.xg);

    //trigger Polls
    pollFunc = OSCFunc({
      arg msg;
      // var ampDetectVal = msg[4].snap(resolution: 0.001, margin: 0.005, strength: 1.0);
      // var freqDetectVal = msg[5].snap(resolution: 0.001, margin: 0.005, strength: 1.0);
      var ampDetectVal = msg[4];
      var freqDetectVal = msg[3];
      for (0, 3, { arg i;
        // ([i,ampDetectVal, ampMinArray[i], ampMaxArray[i],
        // freqDetectVal, freqMinArray[i], freqMaxArray[i]]).postln;
        // [ampDetectVal > ampMinArray[i] , ampDetectVal < ampMaxArray[i] ,
        // freqDetectVal > freqMinArray[i], freqDetectVal < freqMaxArray[i]].postln;
        if (
            ((ampDetectVal > ampMinArray[i]) && (ampDetectVal < ampMaxArray[i])) &&
            ((freqDetectVal > freqMinArray[i]) && (freqDetectVal < freqMaxArray[i]))
        ) {
          // freqDetectVal.postln;
          case 
            {i==0} {amplitudeDetectPoll1.update(ampDetectVal)}
            {i==1} {amplitudeDetectPoll2.update(ampDetectVal)}
            {i==2} {amplitudeDetectPoll3.update(ampDetectVal)}
            {i==3} {amplitudeDetectPoll4.update(ampDetectVal)};

          case 
            {i==0} {frequencyDetectPoll1.update(freqDetectVal)}
            {i==1} {frequencyDetectPoll2.update(freqDetectVal)}
            {i==2} {frequencyDetectPoll3.update(freqDetectVal)}
            {i==3} {frequencyDetectPoll4.update(freqDetectVal)};
        };
      });

      // frequencyDetectPoll1.update(freqDetectVal);
      // frequencyDetectPoll2.update(freqDetectVal);
      // frequencyDetectPoll3.update(freqDetectVal);
      // frequencyDetectPoll4.update(freqDetectVal);
      
    }, path: '/triggerPolls', srcID: context.server.addr);

    // Polls
    amplitudeDetectPoll1 = this.addPoll(name: "amplitudeDetect1", periodic: false);
    amplitudeDetectPoll2 = this.addPoll(name: "amplitudeDetect2", periodic: false);
    amplitudeDetectPoll3 = this.addPoll(name: "amplitudeDetect3", periodic: false);
    amplitudeDetectPoll4 = this.addPoll(name: "amplitudeDetect4", periodic: false);
    frequencyDetectPoll1 = this.addPoll(name: "frequencyDetect1", periodic: false);
    frequencyDetectPoll2 = this.addPoll(name: "frequencyDetect2", periodic: false);
    frequencyDetectPoll3 = this.addPoll(name: "frequencyDetect3", periodic: false);
    frequencyDetectPoll4 = this.addPoll(name: "frequencyDetect4", periodic: false);
    
    // Commands
    this.addCommand("amp", "f", { arg msg;
      synth.set(\amp, msg[1]);
    });

	
    this.addCommand("amp", "f", { arg msg;
      synth.set(\amp, msg[1]);
    });

    this.addCommand("bpm", "f", { arg msg;
      synth.set(\bpm, msg[1]);
    });

    this.addCommand("drywet", "f", { arg msg;
      synth.set(\drywet, msg[1]);
    });

    this.addCommand("phaser", "f", { arg msg;
      synth.set(\effect_phaser, msg[1]);
    });

    this.addCommand("distortion", "f", { arg msg;
      synth.set(\effect_distortion, msg[1]);
    });

    this.addCommand("delay", "f", { arg msg;
      synth.set(\effect_delay, msg[1]);
    });

    this.addCommand("strobe", "f", { arg msg;
      synth.set(\effect_strobe, msg[1]);
    });

    this.addCommand("vinyl", "f", { arg msg;
      synth.set(\effect_vinyl, msg[1]);
    });

    this.addCommand("pitchshift", "f", { arg msg;
      synth.set(\effect_pitchshift, msg[1]);
    });

    this.addCommand("bitcrush", "fff", { arg msg;
      synth.set(
        \effect_bitcrush, msg[1],
        \bitcrush_bits, msg[2],
        \bitcrush_rate, msg[3],
      );
    });

    this.addCommand("set_env_levels", "ffffffffffffffffffff", { arg msg;
      // env_levels = Array.new(~numSegs);
      // for (0, ~numSegs-1, { arg i;
      //   var val = msg[i+1];
      //   env_levels.insert(i,val);
      // }); 
    });

    this.addCommand("set_env_times", "ffffffffffffffffffff", { arg msg;
      // env_times = Array.new(~numSegs);
      // for (0, ~numSegs-1, { arg i; 
      //   var val = msg[i+1];
      //   env_times.insert(i,val);
      // }); 
    });
    
    this.addCommand("set_env_curves", "ffffffffffffffffffff", { arg msg;
      // env_curves = Array.new(~numSegs);
      // for (0, ~numSegs-1, { arg i;
      //   var val = msg[i+1];
      //   env_curves.insert(i,val);
      // }); 
    });

    // var ampMinValVal1=0.1, ampMaxValVal1=0.9, freqMinVal1=40, freqMaxVal1=1200;

    this.addCommand("set_detect_amp_min", "if", { arg msg;
      ampMinArray.put(msg[1], msg[2]);
      synth.set(\ampMin, ampMinArray);
      // ([ampMinArray[msg[1]],ampMinArray[msg[1]-1],msg[1],msg[2]]).postln;
      ([msg[1],msg[1].isInteger,msg[2],msg[2].isInteger]).postln;
    });

    this.addCommand("set_detect_amp_max", "ff", { arg msg;
      ampMaxArray.put(msg[1], msg[2]);
      synth.set(\ampMax, ampMaxArray);
    });

    this.addCommand("set_detect_frequency_min", "ff", { arg msg;
      freqMinArray.put(msg[1], msg[2]);
      synth.set(\freqMin, freqMinArray);
    });

    this.addCommand("set_detect_frequency_max", "ff", { arg msg;
      freqMaxArray.put(msg[1], msg[2]);
      synth.set(\freqMax, freqMaxArray);
    });

    this.addCommand("set_center_frequency", "f", { arg msg;
      synth.set(\cf, msg[1]);
    });

    this.addCommand("set_rq", "f", { arg msg;
      synth.set(\rq, msg[1]);
    });

  }



  

  free {
    synth.free;
    pollFunc.free;
  }
}