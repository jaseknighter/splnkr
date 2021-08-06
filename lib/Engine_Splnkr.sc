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

  var centerFrequency1=440, reciprocalQuality1=1;
  var centerFrequency2=440, reciprocalQuality2=1;
  var centerFrequency3=440, reciprocalQuality3=1;
  var centerFrequency4=440, reciprocalQuality4=1;
  var centerFrequency5=440, reciprocalQuality5=1;
  var centerFrequency6=440, reciprocalQuality6=1;
  var centerFrequency7=440, reciprocalQuality7=1;
  var centerFrequency8=440, reciprocalQuality8=1;
  var centerFrequency9=440, reciprocalQuality9=1;
  var centerFrequency10=440, reciprocalQuality10=1;
  var centerFrequency11=440, reciprocalQuality11=1;
  var centerFrequency12=440, reciprocalQuality12=1;
  var centerFrequency13=440, reciprocalQuality13=1;
  var centerFrequency14=440, reciprocalQuality14=1;
  var centerFrequency15=440, reciprocalQuality15=1;
  var centerFrequency16=440, reciprocalQuality16=1;
  
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
      centerFrequency1=440, reciprocalQuality1=1,
      centerFrequency2=440, reciprocalQuality2=1,
      centerFrequency3=440, reciprocalQuality3=1,
      centerFrequency4=440, reciprocalQuality4=1,
      centerFrequency5=440, reciprocalQuality5=1,
      centerFrequency6=440, reciprocalQuality6=1,
      centerFrequency7=440, reciprocalQuality7=1,
      centerFrequency8=440, reciprocalQuality8=1,
      centerFrequency9=440, reciprocalQuality9=1,
      centerFrequency10=440, reciprocalQuality10=1,
      centerFrequency11=440, reciprocalQuality11=1,
      centerFrequency12=440, reciprocalQuality12=1,
      centerFrequency13=440, reciprocalQuality13=1,
      centerFrequency14=440, reciprocalQuality14=1,
      centerFrequency15=440, reciprocalQuality15=1,
      centerFrequency16=440, reciprocalQuality16=1;

      // centerFrequency1=(1/16)*10000, reciprocalQuality1=1,
      // centerFrequency2=(2/16)*10000, reciprocalQuality2=1,
      // centerFrequency3=(3/16)*10000, reciprocalQuality3=1,
      // centerFrequency4=(4/16)*10000, reciprocalQuality4=1,
      // centerFrequency5=(5/16)*10000, reciprocalQuality5=1,
      // centerFrequency6=(6/16)*10000, reciprocalQuality6=1,
      // centerFrequency7=(7/16)*10000, reciprocalQuality7=1,
      // centerFrequency8=(8/16)*10000, reciprocalQuality8=1,
      // centerFrequency9=(9/16)*10000, reciprocalQuality9=1,
      // centerFrequency10=(10/16)*10000, reciprocalQuality10=1,
      // centerFrequency11=(11/16)*10000, reciprocalQuality11=1,
      // centerFrequency12=(12/16)*10000, reciprocalQuality12=1,
      // centerFrequency13=(13/16)*10000, reciprocalQuality13=1,
      // centerFrequency14=(14/16)*10000, reciprocalQuality14=1,
      // centerFrequency15=(15/16)*10000, reciprocalQuality15=1,
      // centerFrequency16=(16/16)*10000, reciprocalQuality16=1;

      var wet,dry,detect,detectAmp,detectFreq;
      

      var in,freq,hasFreq,out,trig,notes,noteAdder=0; // autotune vars
      var bpf1,bpf2,bpf3,bpf4,bpf5,bpf6,bpf7,bpf8,bpf9,bpf10,bpf11,bpf12,bpf13,bpf14,bpf15,bpf16;
      
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

      bpf1 = SoundIn.ar([0,1]);
      bpf2 = SoundIn.ar([0,1]);
      bpf3 = SoundIn.ar([0,1]);
      bpf4 = SoundIn.ar([0,1]);
      bpf5 = SoundIn.ar([0,1]);
      bpf6 = SoundIn.ar([0,1]);
      bpf7 = SoundIn.ar([0,1]);
      bpf8 = SoundIn.ar([0,1]);
      bpf9 = SoundIn.ar([0,1]);
      bpf10 = SoundIn.ar([0,1]);
      bpf11 = SoundIn.ar([0,1]);
      bpf12 = SoundIn.ar([0,1]);
      bpf13 = SoundIn.ar([0,1]);
      bpf14 = SoundIn.ar([0,1]);
      bpf15 = SoundIn.ar([0,1]);
      bpf16 = SoundIn.ar([0,1]);
      

      bpf1 = BPF.ar(wet,centerFrequency1,reciprocalQuality1);
      bpf2 = BPF.ar(wet,centerFrequency2,reciprocalQuality2);
      bpf3 = BPF.ar(wet,centerFrequency3,reciprocalQuality3);
      bpf4 = BPF.ar(wet,centerFrequency4,reciprocalQuality4);
      bpf5 = BPF.ar(wet,centerFrequency5,reciprocalQuality5);
      bpf6 = BPF.ar(wet,centerFrequency6,reciprocalQuality6);
      bpf7 = BPF.ar(wet,centerFrequency7,reciprocalQuality7);
      bpf8 = BPF.ar(wet,centerFrequency8,reciprocalQuality8);
      bpf9 = BPF.ar(wet,centerFrequency9,reciprocalQuality9);
      bpf10 = BPF.ar(wet,centerFrequency10,reciprocalQuality10);
      bpf11 = BPF.ar(wet,centerFrequency11,reciprocalQuality11);
      bpf12 = BPF.ar(wet,centerFrequency12,reciprocalQuality12);
      bpf13 = BPF.ar(wet,centerFrequency13,reciprocalQuality13);
      bpf14 = BPF.ar(wet,centerFrequency14,reciprocalQuality14);
      bpf15 = BPF.ar(wet,centerFrequency15,reciprocalQuality15);
      bpf16 = BPF.ar(wet,centerFrequency16,reciprocalQuality16);
      
      wet = bpf1+bpf2+bpf3+bpf4+bpf5+bpf6+bpf7+bpf8+bpf9+bpf10+bpf11+bpf12+bpf13+bpf14+bpf15+bpf16;
      // wet = Mix.ar[bpf1,bpf2,bpf3,bpf4,bpf5,bpf6,bpf7,bpf8,bpf9,bpf10,bpf11,bpf12,bpf13,bpf14,bpf15,bpf16];


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

      // autotune-frequency detector
      trig = Impulse.ar(4);
      notes = Dseq([0,4,5], inf);
    	# freq, hasFreq = Tartini.kr(wet);

      // TODO: what is a good order for these?
      // TODO: explode some options
      
      // delay 
      wet = (wet*(1-effect_delay))+(effect_delay*CombC.ar(wet,5,0.2,4));

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

      
      // outputArray to send to polls
      outArray = Array.fill(numOutValues, 0);
      outArray[0] = detectAmp; // amplitude detection
      outArray[1] = freq; // frequency
      SendReply.kr(Impulse.kr(10), '/triggerPolls', outArray);
      
      dry = dry*Lag.kr(amp*(1-drywet),1);
      // dry = dry*(1-(drywet+0.001));
      wet = wet*Lag.kr(amp*drywet,1);
      // wet = wet*(drywet+0.001);
      // Out.ar(0, [detect, wet]);
      // Out.ar(0, [dry, wet]);
      // Out.ar(0, Mix.new([dry*0.5, wet*0.5]));
      // Out.ar(0,Balance2.ar(dry*0.5, wet*0.5, 0));
      Out.ar(0, [wet, wet]);
    }.play( target: context.xg);

    //trigger Polls
    pollFunc = OSCFunc({
      arg msg;
      // var ampDetectVal = msg[4].snap(resolution: 0.001, margin: 0.005, strength: 1.0);
      // var freqDetectVal = msg[5].snap(resolution: 0.001, margin: 0.005, strength: 1.0);
      var ampDetectVal = msg[4];
      var freqDetectVal = msg[3];
      
      for (0, 3, { arg i;
        if (
            ((ampDetectVal > ampMinArray[i]) && (ampDetectVal < ampMaxArray[i])) &&
            ((freqDetectVal > freqMinArray[i]) && (freqDetectVal < freqMaxArray[i]))
        ) {
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
      (msg[1]).postln;
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
      // ([msg[1],msg[1].isInteger,msg[2],msg[2].isInteger]).postln;
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

    this.addCommand("set_center_frequency", "ff", { arg msg;
      var i = msg[1];
      var centerFrequency = msg[2];
      ([i,centerFrequency]).postln;
      // synth.set(\centerFrequency, msg[1]);
      case 
        {i==1} {synth.set(\centerFrequency1, centerFrequency)}
        {i==2} {synth.set(\centerFrequency2, centerFrequency)}
        {i==3} {synth.set(\centerFrequency3, centerFrequency)}
        {i==4} {synth.set(\centerFrequency4, centerFrequency)}
        {i==5} {synth.set(\centerFrequency5, centerFrequency)}
        {i==6} {synth.set(\centerFrequency6, centerFrequency)}
        {i==7} {synth.set(\centerFrequency7, centerFrequency)}
        {i==8} {synth.set(\centerFrequency8, centerFrequency)}
        {i==9} {synth.set(\centerFrequency9, centerFrequency)}
        {i==10} {synth.set(\centerFrequency10, centerFrequency)}
        {i==11} {synth.set(\centerFrequency11, centerFrequency)}
        {i==12} {synth.set(\centerFrequency12, centerFrequency)}
        {i==13} {synth.set(\centerFrequency13, centerFrequency)}
        {i==14} {synth.set(\centerFrequency14, centerFrequency)}
        {i==15} {synth.set(\centerFrequency15, centerFrequency)}
        {i==16} {synth.set(\centerFrequency16, centerFrequency)};

    });

    this.addCommand("set_reciprocal_quality", "ff", { arg msg;
      var i = msg[1];
      var reciprocalQuality = msg[2];
      ([i,reciprocalQuality]).postln;
      case 
        {i==1} {synth.set(\reciprocalQuality1, reciprocalQuality)}
        {i==2} {synth.set(\reciprocalQuality2, reciprocalQuality)}
        {i==3} {synth.set(\reciprocalQuality3, reciprocalQuality)}
        {i==4} {synth.set(\reciprocalQuality4, reciprocalQuality)}
        {i==5} {synth.set(\reciprocalQuality5, reciprocalQuality)}
        {i==6} {synth.set(\reciprocalQuality6, reciprocalQuality)}
        {i==7} {synth.set(\reciprocalQuality7, reciprocalQuality)}
        {i==8} {synth.set(\reciprocalQuality8, reciprocalQuality)}
        {i==9} {synth.set(\reciprocalQuality9, reciprocalQuality)}
        {i==10} {synth.set(\reciprocalQuality10, reciprocalQuality)}
        {i==11} {synth.set(\reciprocalQuality11, reciprocalQuality)}
        {i==12} {synth.set(\reciprocalQuality12, reciprocalQuality)}
        {i==13} {synth.set(\reciprocalQuality13, reciprocalQuality)}
        {i==14} {synth.set(\reciprocalQuality14, reciprocalQuality)}
        {i==15} {synth.set(\reciprocalQuality15, reciprocalQuality)}
        {i==16} {synth.set(\reciprocalQuality16, reciprocalQuality)};

    });


  }

  

  free {
    synth.free;
    pollFunc.free;
  }
}

