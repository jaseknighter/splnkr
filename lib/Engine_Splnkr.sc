Engine_Splnkr : CroneEngine {
  classvar maxNumVoices = 1;
  var voiceGroup;
  var voiceList;

  // var <splnkrVoice;
  var numOutValues = 2;
  var pollFunc;
  var outArray;
  var amplitudeDetectPoll1,amplitudeDetectPoll2,amplitudeDetectPoll3,amplitudeDetectPoll4;
  var frequencyDetectPoll1, frequencyDetectPoll2, frequencyDetectPoll3, frequencyDetectPoll4;

  var maxsegments = 20;
  var numSegs, envLevels, envTimes, envCurves;
  
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

  var filterLevel1=1,centerFrequency1=440, reciprocalQuality1=1;
  var filterLevel2=1,centerFrequency2=440, reciprocalQuality2=1;
  var filterLevel3=1,centerFrequency3=440, reciprocalQuality3=1;
  var filterLevel4=1,centerFrequency4=440, reciprocalQuality4=1;
  var filterLevel5=1,centerFrequency5=440, reciprocalQuality5=1;
  var filterLevel6=1,centerFrequency6=440, reciprocalQuality6=1;
  var filterLevel7=1,centerFrequency7=440, reciprocalQuality7=1;
  var filterLevel8=1,centerFrequency8=440, reciprocalQuality8=1;
  var filterLevel9=1,centerFrequency9=440, reciprocalQuality9=1;
  var filterLevel0=1,centerFrequency10=440, reciprocalQuality10=1;
  var filterLevel1=1,centerFrequency11=440, reciprocalQuality11=1;
  var filterLevel2=1,centerFrequency12=440, reciprocalQuality12=1;
  var filterLevel3=1,centerFrequency13=440, reciprocalQuality13=1;
  var filterLevel4=1,centerFrequency14=440, reciprocalQuality14=1;
  var filterLevel5=1,centerFrequency15=440, reciprocalQuality15=1;
  var filterLevel6=1, centerFrequency16=440, reciprocalQuality16=1;
  
  var splnkrDef, splnkrVoice;
  var slpnkr_audio;
  
  var wet, dry;
  var h, e;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    voiceGroup = Group.new(context.xg);
    voiceList = List.new();
    h = Signal.hanningWindow(1000);
    e = Buffer.loadCollection(context.server, h, 1);
    
    splnkrDef = SynthDef(\SplnkrSynth, {
      arg amp=1,bpm=120,drywet=1,
      ampMin=ampMinArray, ampMax=ampMaxArray, 
      freqMin=freqMinArray, freqMax=freqMaxArray,
      effect_phaser=0,effect_distortion=0,effect_delay=0,
      effect_bitcrush,bitcrush_bits=10,bitcrush_rate=12000, // this has parameters
      effect_strobe=0,effect_vinyl=0,effect_pitchshift=0,
      wobble_rpm=33, wobble_amp=0.05, wobble_exp=39, flutter_amp=0.03, flutter_fixedfreq=6, flutter_variationfreq=2,
      filterLevel1=1, centerFrequency1=440, reciprocalQuality1=1, 
      filterLevel2=1, centerFrequency2=440, reciprocalQuality2=1, 
      filterLevel3=1, centerFrequency3=440, reciprocalQuality3=1, 
      filterLevel4=1, centerFrequency4=440, reciprocalQuality4=1, 
      filterLevel5=1, centerFrequency5=440, reciprocalQuality5=1, 
      filterLevel6=1, centerFrequency6=440, reciprocalQuality6=1, 
      filterLevel7=1, centerFrequency7=440, reciprocalQuality7=1, 
      filterLevel8=1, centerFrequency8=440, reciprocalQuality8=1, 
      filterLevel9=1, centerFrequency9=440, reciprocalQuality9=1, 
      filterLevel10=1, centerFrequency10=440, reciprocalQuality10=1, 
      filterLevel11=1, centerFrequency11=440, reciprocalQuality11=1, 
      filterLevel12=1, centerFrequency12=440, reciprocalQuality12=1, 
      filterLevel13=1, centerFrequency13=440, reciprocalQuality13=1, 
      filterLevel14=1, centerFrequency14=440, reciprocalQuality14=1, 
      filterLevel15=1, centerFrequency15=440, reciprocalQuality15=1, 
      filterLevel16=1, centerFrequency16=440, reciprocalQuality16=1,
      envTime1=0, envLevel1=1, envCurve1=0, 
      envTime2=1, envLevel2=1, envCurve2=0, 
      envTime3=1, envLevel3=1, envCurve3=0, 
      envTime4=1, envLevel4=1, envCurve4=0, 
      envTime5=1, envLevel5=1, envCurve5=0, 
      envTime6=1, envLevel6=1, envCurve6=0, 
      envTime7=1, envLevel7=1, envCurve7=0, 
      envTime8=0, envLevel8=0, envCurve8=0,

      envBuf, enveloper = 1, trigRate = 50, overlap = 0.5, panMax = 0.5,
      panType = 0, minGrainDur = 0.001, interpolation = 4; 
      
      

      // var wet,dry;
      var detect,detectAmp,detectFreq;
      

      var in,freq,hasFreq,out,trig,notes,noteAdder=0; // autotune vars
      var bpf1,bpf2,bpf3,bpf4,bpf5,bpf6,bpf7,bpf8,bpf9,bpf10,bpf11,bpf12,bpf13,bpf14,bpf15,bpf16;
      var env, envctl;

      var inSig, numFrames, startTrig, grainDur,
        latchedTrigRate, latchedStartTrig, latchedOverlap, pan, sig;

      // env = Env.newClear(maxsegments);
      // envctl = \env.kr(env.asArray);

      ampMinArray=Array.fill(4,{0.001});
      ampMaxArray=Array.fill(4,{0.999}); 
      freqMinArray=Array.fill(4,{40}); 
      freqMaxArray=Array.fill(4,{1200});

      wet = SoundIn.ar([0,1]);
      dry = SoundIn.ar([0,1]);

      //////////////////////////////////////////
      // bpf, pitch/amp detection
      //////////////////////////////////////////

      // amplitude compensation for lower rq of bandpass filter
      bpf1 = BPF.ar(wet,centerFrequency1,reciprocalQuality1, (reciprocalQuality1 ** -1) * (400 / centerFrequency1 ** 0.5));
      bpf2 = BPF.ar(wet,centerFrequency2,reciprocalQuality2, (reciprocalQuality2 ** -1) * (400 / centerFrequency2 ** 0.5));
      bpf3 = BPF.ar(wet,centerFrequency3,reciprocalQuality3, (reciprocalQuality3 ** -1) * (400 / centerFrequency3 ** 0.5));
      bpf4 = BPF.ar(wet,centerFrequency4,reciprocalQuality4, (reciprocalQuality4 ** -1) * (400 / centerFrequency4 ** 0.5));
      bpf5 = BPF.ar(wet,centerFrequency5,reciprocalQuality5, (reciprocalQuality5 ** -1) * (400 / centerFrequency5 ** 0.5));
      bpf6 = BPF.ar(wet,centerFrequency6,reciprocalQuality6, (reciprocalQuality6 ** -1) * (400 / centerFrequency6 ** 0.5));
      bpf7 = BPF.ar(wet,centerFrequency7,reciprocalQuality7, (reciprocalQuality7 ** -1) * (400 / centerFrequency7 ** 0.5));
      bpf8 = BPF.ar(wet,centerFrequency8,reciprocalQuality8, (reciprocalQuality8 ** -1) * (400 / centerFrequency8 ** 0.5));
      bpf9 = BPF.ar(wet,centerFrequency9,reciprocalQuality9, (reciprocalQuality9 ** -1) * (400 / centerFrequency9 ** 0.5));
      bpf10 = BPF.ar(wet,centerFrequency10,reciprocalQuality10, (reciprocalQuality10 ** -1) * (400 / centerFrequency10 ** 0.5));
      bpf11 = BPF.ar(wet,centerFrequency11,reciprocalQuality11, (reciprocalQuality11 ** -1) * (400 / centerFrequency11 ** 0.5));
      bpf12 = BPF.ar(wet,centerFrequency12,reciprocalQuality12, (reciprocalQuality12 ** -1) * (400 / centerFrequency12 ** 0.5));
      bpf13 = BPF.ar(wet,centerFrequency13,reciprocalQuality13, (reciprocalQuality13 ** -1) * (400 / centerFrequency13 ** 0.5));
      bpf14 = BPF.ar(wet,centerFrequency14,reciprocalQuality14, (reciprocalQuality14 ** -1) * (400 / centerFrequency14 ** 0.5));
      bpf15 = BPF.ar(wet,centerFrequency15,reciprocalQuality15, (reciprocalQuality15 ** -1) * (400 / centerFrequency15 ** 0.5));
      bpf16 = BPF.ar(wet,centerFrequency16,reciprocalQuality16, (reciprocalQuality16 ** -1) * (400 / centerFrequency16 ** 0.5));

      
      wet = (bpf1*filterLevel1)+(bpf2*filterLevel2)+(bpf3*filterLevel3)+(bpf4*filterLevel4)+(bpf5*filterLevel5)+(bpf6*filterLevel6)+(bpf7*filterLevel7)+(bpf8*filterLevel8)+(bpf9*filterLevel9)+(bpf10*filterLevel10)+(bpf11*filterLevel11)+(bpf12*filterLevel12)+(bpf13*filterLevel13)+(bpf14*filterLevel14)+(bpf15*filterLevel15)+(bpf16*filterLevel16);
      // wet = (bpf1)+(bpf2)+(bpf3)+(bpf4)+(bpf5)+(bpf6)+(bpf7)+(bpf8)+(bpf9)+(bpf10)+(bpf11)+(bpf12)+(bpf13)+(bpf14)+(bpf15)+(bpf16);
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

      // outputArray to send to polls
      outArray = Array.fill(numOutValues, 0);
      outArray[0] = detectAmp; // amplitude detection
      outArray[1] = freq; // frequency
      SendReply.kr(Impulse.kr(10), '/triggerPolls', outArray);
      



      //////////////////////////////////////////
      // granular enveloping
      //////////////////////////////////////////
      

      // inSig = DelayC.ar(LPF.ar(inSig.tanh, 2000), 0.1, 0.01);
      wet = DelayC.ar(LPF.ar(wet.tanh, 2000), 0.1, 0.01);

      startTrig = Impulse.ar(trigRate);
      // why this ? - shape of envelope shouldn't be changed while application
      
      latchedTrigRate = Latch.ar(K2A.ar(trigRate), startTrig);
      latchedStartTrig = Impulse.ar(latchedTrigRate);
      latchedOverlap = Latch.ar(K2A.ar(overlap), startTrig);

      latchedOverlap = max(latchedOverlap, latchedTrigRate * minGrainDur);
      grainDur = (latchedOverlap / latchedTrigRate);

      // h = Env.xyc(env).asSignal(1000);
      // h = Env.new(levels: [1, 0, 1], times: [0.5, 0.5], curve: [5, -5]).asSignal(length:1000);
      // h = Signal.hanningWindow(1000);
      // e = Buffer.loadCollection(context.server, h, 1);
      // context.server.sync;
      envBuf = e.bufnum;
      numFrames = BufFrames.kr(envBuf);
      // numFrames.poll;

      env = BufRd.ar(
          1,
          envBuf,
          Sweep.ar(
              latchedStartTrig,
              latchedOverlap.reciprocal * latchedTrigRate * numFrames,
          ).clip(0, numFrames - 1),
          interpolation: interpolation
      );

      pan = Demand.ar(
          latchedStartTrig,
          0,
          Dswitch1([
              Dseq([1, -1], inf),
              Dwhite(-1, 1)
          ], panType)
      ) * panMax * 0.999;

      // wet = Pan2.ar(wet * env * amp, pan) * EnvGate.new;
      (enveloper).poll;

      wet = (Pan2.ar(wet * env * amp, pan) * EnvGate.new * enveloper) + (wet*((enveloper+1)%2));
      //////////////////////////////////////////
      // other effects
      //////////////////////////////////////////
      
      // TODO: what is a good order for these?
      // TODO: explode some options
      
      // delay 


      wet = (wet*(1-effect_delay))+(effect_delay*CombC.ar(wet,5,0.2,4));

      // // pitch shift
      wet = (wet*(1-effect_pitchshift))+(effect_pitchshift*PitchShift.ar(
        wet,
        0.1,
        // ((Demand.ar(trig, 0, notes)).midicps / freq),
        ((Demand.ar(trig, 0, notes) + 54).midicps / freq),
        0,
        0.01
      ));

      // phaser
      // wet = (wet*(1-effect_phaser))+(effect_phaser*CombC.ar(wet,1,SinOsc.kr(1/7).range(500,1000).reciprocal,0.05*SinOsc.kr(1/7.1).range(-1,1)));
      wet = (wet*(1-effect_phaser))+(effect_phaser*CombC.ar(wet,1,SinOsc.kr(1/7).range(500,550).reciprocal,0.05*SinOsc.kr(1/7.1).range(-1,1)));

      // distortion
      effect_distortion = Lag.kr(effect_distortion,0.5);
      wet = (wet*(1-(effect_distortion>0)))+(wet*effect_distortion).tanh;


      // bitcrush
      wet = (wet*(1-effect_bitcrush))+(effect_bitcrush*Decimator.ar(wet,Lag.kr(bitcrush_rate,1),Lag.kr(bitcrush_bits,1)));

      // strobe
      wet = ((effect_strobe<1)*wet)+((effect_strobe>0)*wet*SinOsc.ar(bpm/60));

            // vinyl wow + compressor
      wet=(effect_vinyl<1*wet)+(effect_vinyl>0* Limiter.ar(Compander.ar(wet,wet,0.5,1.0,0.1,0.1,1,2),dur:0.0008));
      wet =(effect_vinyl<1*wet)+(effect_vinyl>0* DelayC.ar(wet,0.01,VarLag.kr(LFNoise0.kr(1),1,warp:\sine).range(0,0.01)));                
      
      // alt flutter and wow code
      // var signed_wobble = wobble_amp*(SinOsc.kr(wobble_rpm/60)**wobble_exp);
      // var wow = Select.kr(signed_wobble > 0, signed_wobble, 0);
      // var flutter = flutter_amp*SinOsc.kr(flutter_fixedfreq+LFNoise2.kr(flutter_variationfreq));
      // var combined_defects = 1 + wow + flutter;

      // flutter + wow
      // wet = wet * combined_defects;

      
      //////////////////////////////////////////
      // apply lag, remove DC bias, and send the signal out
      //////////////////////////////////////////
      
      wet = wet*Lag.kr(amp*drywet,1);
      wet = LeakDC.ar(wet, 0.995);

      dry = dry*Lag.kr(amp*(1-drywet),1);
      // Out.ar(0,Balance2.ar(dry*0.5, wet*0.5, 0));
      // wet = wet*(drywet+0.001);
      // Out.ar(0, [detect, wet]);
      // Out.ar(0, [dry, wet]);
      // Out.ar(0, Mix.new([dry*0.5, wet*0.5]));

      Out.ar(0,Balance2.ar(dry, wet, 0));
    }).add;

    //trigger Polls
    pollFunc = OSCFunc({
      arg msg;
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
    this.addCommand("start_splnkring", "f", { arg msg;
      var voiceToRemove, newVoice;
      var id=0;
      var env;
      
      // Replace the existing voice if it exists
      // voiceToRemove = voiceList.detect{arg item; item.id == id};
      // if(voiceToRemove.isNil && (voiceList.size >= maxNumVoices), {
      ([voiceList.size >= maxNumVoices]).postln;
      if((voiceList.size >= maxNumVoices), {
        ("remove voice").postln;
        voiceToRemove = voiceList.detect{arg v; v.gate == 0};
      	if(voiceToRemove.isNil, {
      	  voiceToRemove = voiceList.last;
      	});
      });
      
      if(voiceToRemove.notNil, {
        voiceToRemove.theSynth.set(\gate, 0);
        voiceToRemove.theSynth.set(\killGate, 0);
        voiceToRemove.free;
        voiceList.remove(voiceToRemove);
      });
  			

      // Add new voice 
      context.server.makeBundle(nil, {
        id = id+1;
        newVoice = (id: id, theSynth: Synth("SplnkrSynth",
        [
          // \amp, amp,
          // \env, env,
        ],
        target: voiceGroup).onFree({ 
            voiceList.remove(newVoice); 
          })
        );
        voiceList.addFirst(newVoice);
        splnkrVoice = voiceList.detect({ arg item, i; item.id == id; });
        splnkrVoice.postln;

        // splnkrVoice = voiceList.detect{arg v; v.gate == 0};
        // ("makebundle").postln;
        // splnkrVoice = voiceList.detect{arg v; 
        //   v.postln;
          // v.gate == 0
        // };
      });
    });

    this.addCommand("amp", "f", { arg msg;
      splnkrVoice.theSynth.set(\amp, msg[1]);
    });

    this.addCommand("enveloper", "i", { arg msg;
      splnkrVoice.theSynth.set(\enveloper, msg[1]);
    });

    this.addCommand("trig_rate", "f", { arg msg;
      splnkrVoice.theSynth.set(\trigRate, msg[1]);
    });

    this.addCommand("overlap", "f", { arg msg;
      splnkrVoice.theSynth.set(\overlap, msg[1]);
    });
    this.addCommand("pan_type", "f", { arg msg;
      splnkrVoice.theSynth.set(\panType, msg[1]);
    });
    this.addCommand("pan_max", "f", { arg msg;
      splnkrVoice.theSynth.set(\panMax, msg[1]);
    });

    this.addCommand("bpm", "f", { arg msg;
      splnkrVoice.theSynth.set(\bpm, msg[1]);
    });

    this.addCommand("drywet", "f", { arg msg;
      splnkrVoice.theSynth.set(\drywet, msg[1]);
    });

    this.addCommand("phaser", "f", { arg msg;
      splnkrVoice.theSynth.set(\effect_phaser, msg[1]);
    });

    this.addCommand("distortion", "f", { arg msg;
      splnkrVoice.theSynth.set(\effect_distortion, msg[1]);
    });

    this.addCommand("delay", "f", { arg msg;
      splnkrVoice.theSynth.set(\effect_delay, msg[1]);
    });

    this.addCommand("strobe", "f", { arg msg;
      splnkrVoice.theSynth.set(\effect_strobe, msg[1]);
    });

    this.addCommand("vinyl", "f", { arg msg;
      splnkrVoice.theSynth.set(\effect_vinyl, msg[1]);
    });

    this.addCommand("pitchshift", "f", { arg msg;
      splnkrVoice.theSynth.set(\effect_pitchshift, msg[1]);
    });

    this.addCommand("bitcrush", "fff", { arg msg;
      splnkrVoice.theSynth.set(
        \effect_bitcrush, msg[1],
        \bitcrush_bits, msg[2],
        \bitcrush_rate, msg[3],
      );
    });

    this.addCommand("set_numSegs", "f", { arg msg;
    	numSegs = msg[1];
    });

    // this.addCommand("set_env_levels", "ffffffffffffffffffff", { arg msg;
    this.addCommand("set_env_levels", "ffffffff", { arg msg;
      envLevels = Array.new(numSegs);
      for (0, numSegs-1, { arg i;
        var val = msg[i+1];
        envLevels.insert(i,val);
      }); 
    });

    // this.addCommand("set_env_times", "ffffffffffffffffffff", { arg msg;
    this.addCommand("set_env_times", "ffffffff", { arg msg;
      var newEnv, envLength;

      envTimes = Array.new(numSegs);
      for (0, numSegs-1, { arg i; 
        var val = msg[i+1];
        envTimes.insert(i,val);
      }); 
      

      newEnv = Array.new(numSegs-1);
      // (["set env",envLevels, envTimes, envCurves]).postln;
      for (0, numSegs-1, { arg i;
        var xycSegment = Array.new(3);
        xycSegment.insert(0, envTimes[i]);
        xycSegment.insert(1, envLevels[i]);
        xycSegment.insert(2, envCurves[i]);
        newEnv.insert(i,xycSegment);
      });
      envLength = envTimes[numSegs-1] * 1000;
      envLength.postln;
      h = Env.xyc(newEnv).asSignal(envLength);
      e.free;
      e = Buffer.loadCollection(context.server, h, 1);
      
    });
    
    // this.addCommand("set_env_curves", "ffffffffffffffffffff", { arg msg;
    this.addCommand("set_env_curves", "ffffffff", { arg msg;
      envCurves = Array.new(numSegs);
      for (0, numSegs-1, { arg i;
        var val = msg[i+1];
        envCurves.insert(i,val);
      }); 
    });

    this.addCommand("set_detect_amp_min", "if", { arg msg;
      ampMinArray.put(msg[1], msg[2]);
      splnkrVoice.theSynth.set(\ampMin, ampMinArray);
    });

    this.addCommand("set_detect_amp_max", "ff", { arg msg;
      ampMaxArray.put(msg[1], msg[2]);
      splnkrVoice.theSynth.set(\ampMax, ampMaxArray);
    });

    this.addCommand("set_detect_frequency_min", "ff", { arg msg;
      freqMinArray.put(msg[1], msg[2]);
      splnkrVoice.theSynth.set(\freqMin, freqMinArray);
    });

    this.addCommand("set_detect_frequency_max", "ff", { arg msg;
      freqMaxArray.put(msg[1], msg[2]);
      splnkrVoice.theSynth.set(\freqMax, freqMaxArray);
    });

    this.addCommand("set_filter_level", "ff", { arg msg;
      var i = msg[1];
      var filterLevel = msg[2];
      case 
        {i==1} {splnkrVoice.theSynth.set(\filterLevel1, filterLevel)}
        {i==2} {splnkrVoice.theSynth.set(\filterLevel2, filterLevel)}
        {i==3} {splnkrVoice.theSynth.set(\filterLevel3, filterLevel)}
        {i==4} {splnkrVoice.theSynth.set(\filterLevel4, filterLevel)}
        {i==5} {splnkrVoice.theSynth.set(\filterLevel5, filterLevel)}
        {i==6} {splnkrVoice.theSynth.set(\filterLevel6, filterLevel)}
        {i==7} {splnkrVoice.theSynth.set(\filterLevel7, filterLevel)}
        {i==8} {splnkrVoice.theSynth.set(\filterLevel8, filterLevel)}
        {i==9} {splnkrVoice.theSynth.set(\filterLevel9, filterLevel)}
        {i==10} {splnkrVoice.theSynth.set(\filterLevel10, filterLevel)}
        {i==11} {splnkrVoice.theSynth.set(\filterLevel11, filterLevel)}
        {i==12} {splnkrVoice.theSynth.set(\filterLevel12, filterLevel)}
        {i==13} {splnkrVoice.theSynth.set(\filterLevel13, filterLevel)}
        {i==14} {splnkrVoice.theSynth.set(\filterLevel14, filterLevel)}
        {i==15} {splnkrVoice.theSynth.set(\filterLevel15, filterLevel)}
        {i==16} {splnkrVoice.theSynth.set(\filterLevel16, filterLevel)};
    });

    this.addCommand("set_center_frequency", "ff", { arg msg;
      var i = msg[1];
      var centerFrequency = msg[2];
      case 
        {i==1} {splnkrVoice.theSynth.set(\centerFrequency1, centerFrequency); ([i,centerFrequency]);}
        {i==2} {splnkrVoice.theSynth.set(\centerFrequency2, centerFrequency); ([i,centerFrequency]);}
        {i==3} {splnkrVoice.theSynth.set(\centerFrequency3, centerFrequency); ([i,centerFrequency]);}
        {i==4} {splnkrVoice.theSynth.set(\centerFrequency4, centerFrequency); ([i,centerFrequency]);}
        {i==5} {splnkrVoice.theSynth.set(\centerFrequency5, centerFrequency); ([i,centerFrequency]);}
        {i==6} {splnkrVoice.theSynth.set(\centerFrequency6, centerFrequency); ([i,centerFrequency]);}
        {i==7} {splnkrVoice.theSynth.set(\centerFrequency7, centerFrequency); ([i,centerFrequency]);}
        {i==8} {splnkrVoice.theSynth.set(\centerFrequency8, centerFrequency); ([i,centerFrequency]);}
        {i==9} {splnkrVoice.theSynth.set(\centerFrequency9, centerFrequency); ([i,centerFrequency]);}
        {i==10} {splnkrVoice.theSynth.set(\centerFrequency10, centerFrequency); ([i,centerFrequency]);}
        {i==11} {splnkrVoice.theSynth.set(\centerFrequency11, centerFrequency); ([i,centerFrequency]);}
        {i==12} {splnkrVoice.theSynth.set(\centerFrequency12, centerFrequency); ([i,centerFrequency]);}
        {i==13} {splnkrVoice.theSynth.set(\centerFrequency13, centerFrequency); ([i,centerFrequency]);}
        {i==14} {splnkrVoice.theSynth.set(\centerFrequency14, centerFrequency); ([i,centerFrequency]);}
        {i==15} {splnkrVoice.theSynth.set(\centerFrequency15, centerFrequency); ([i,centerFrequency]);}
        {i==16} {splnkrVoice.theSynth.set(\centerFrequency16, centerFrequency); ([i,centerFrequency]);};

    });

    this.addCommand("set_reciprocal_quality", "ff", { arg msg;
      var i = msg[1];
      var reciprocalQuality = msg[2];
      case 
        {i==1} {splnkrVoice.theSynth.set(\reciprocalQuality1, reciprocalQuality)}
        {i==2} {splnkrVoice.theSynth.set(\reciprocalQuality2, reciprocalQuality)}
        {i==3} {splnkrVoice.theSynth.set(\reciprocalQuality3, reciprocalQuality)}
        {i==4} {splnkrVoice.theSynth.set(\reciprocalQuality4, reciprocalQuality)}
        {i==5} {splnkrVoice.theSynth.set(\reciprocalQuality5, reciprocalQuality)}
        {i==6} {splnkrVoice.theSynth.set(\reciprocalQuality6, reciprocalQuality)}
        {i==7} {splnkrVoice.theSynth.set(\reciprocalQuality7, reciprocalQuality)}
        {i==8} {splnkrVoice.theSynth.set(\reciprocalQuality8, reciprocalQuality)}
        {i==9} {splnkrVoice.theSynth.set(\reciprocalQuality9, reciprocalQuality)}
        {i==10} {splnkrVoice.theSynth.set(\reciprocalQuality10, reciprocalQuality)}
        {i==11} {splnkrVoice.theSynth.set(\reciprocalQuality11, reciprocalQuality)}
        {i==12} {splnkrVoice.theSynth.set(\reciprocalQuality12, reciprocalQuality)}
        {i==13} {splnkrVoice.theSynth.set(\reciprocalQuality13, reciprocalQuality)}
        {i==14} {splnkrVoice.theSynth.set(\reciprocalQuality14, reciprocalQuality)}
        {i==15} {splnkrVoice.theSynth.set(\reciprocalQuality15, reciprocalQuality)}
        {i==16} {splnkrVoice.theSynth.set(\reciprocalQuality16, reciprocalQuality)};
    });
  }

  free {
    splnkrVoice.free;
    voiceGroup.free;
    voiceList.free;
    wet.free;
    pollFunc.free;
  }
}

