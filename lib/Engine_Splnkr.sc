//TODOs:
//      cleanup
//      move envBuf from an arg to a var????
//      why isn't flutter and wow working
//      for freq detector add min/max params for clipping (see: freq = Clip.ar(freq, 40.midicps, 70.midicps);)

Engine_Splnkr : CroneEngine {
  classvar maxNumVoices = 1;
  var wet,dry;
  var voiceGroup;
  var voiceList;
  var numOutValues = 2;
  var maxsegments = 20;
  var numSegs=3, envLevels, envTimes, envCurves;
  var splnkrDef, splnkrVoice;
  var enveloper = 1, trigRate = 5, overlap = 0.99, panMax = 0.5, panType=0;
  var id=0;
  var ampPollFunc, onsetDetectAmpPollFunc, freqPollFunc;
  var outArray;
  var amplitudeDetectPoll,onsetAmplitudeDetectPoll, frequencyDetectPoll;
  // var ampMinArray, ampMaxArray, freqMinArray, freqMaxArray;
  var amp=1,bpm=120,drywet=1;
  var effect_phaser=0,effect_distortion=0,effect_delay=0,
      effect_bitcrush,bitcrush_bits=10,bitcrush_rate=12000, // this has parameters
      effect_strobe=0,effect_vinyl=0, effect_flutter_and_wow=0,
      effect_pitchshift=0, pitchshift_offset=0, 
      pitchshift_note1=1, pitchshift_note2=3, pitchshift_note3=5, pitchshift_note4=1, pitchshift_note5=3;
  var pitch_shift_trigger_frequency=1, pitch_shift_base_note=0;
  var grain_size, time_dispersion;

      // pitchshi
      // pitchshift_midi_offset=0;
  var effect_delaytime = 0.25, effect_delaydecaytime = 4.0, effect_delaymul = 2.0;

  var wobble_rpm=33, wobble_amp=0.05, wobble_exp=3, flutter_amp=0.0, flutter_fixedfreq=6, flutter_variationfreq=2; 
  // var bpfLevelsArray, bpfCenterFreqsArray, bpfRQsArray;
  var filterLevel0=1,centerFrequency0=440, reciprocalQuality0=1;
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
  var combBuf1, combBuf2;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    voiceGroup = Group.new(context.xg);
    voiceList = List.new();

    

    // envSig = Signal.hanningWindow(1000);
    // envBuf = Buffer.loadCollection(context.server, envSig, 1).bufnum;
    
    splnkrDef = SynthDef(\SplnkrSynth, {
      arg amp=1,bpm=120,drywet=1,
      // bpfLevels=bpfLevelsArray, bpfCenterFreqs=bpfCenterFreqsArray, bpfRQs=bpfRQsArray,
      filterLevel0=1,centerFrequency0=440, reciprocalQuality0=1,
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
      // ampMin=ampMinArray, ampMax=ampMaxArray,
      // freqMin=freqMinArray, freqMax=freqMaxArray,
      effect_phaser=0,effect_distortion=0,effect_delay=0,
      effect_bitcrush,bitcrush_bits=10,bitcrush_rate=12000, 
      effect_strobe=0,effect_vinyl=0, effect_flutter_and_wow=0,
      // pitchshift_midi_offset=0,
      pitch_shift_trigger_frequency=1, effect_pitchshift=0, pitchshift_offset=0, pitch_shift_base_note=24,
      pitchshift_note1=1, pitchshift_note2=3, pitchshift_note3=5, pitchshift_note4=1, pitchshift_note5=3,
      grain_size=0.1, time_dispersion=0.01,
      effect_delaytime = 0.25, effect_delaydecaytime = 4.0, effect_delaymul = 2.0,
      envBuf,
      bpfs,
      enveloper = 1, trigRate = 5, overlap = 0.99, panMax = 0.5,
      panType = 0, minGrainDur = 0.001, interpolation = 4,
      wobble_rpm=33, wobble_amp=0.05, wobble_exp=39, flutter_amp=0.03, flutter_fixedfreq=6, flutter_variationfreq=2,
      start=0, end=1, t_trig=0;

      var out;
      var startA,endA,startB,endB,crossfade,aOrB;


      var envTime1=0, envLevel1=1, envCurve1=0, envTime2=1, envLevel2=1, envCurve2=0, envTime3=1, envLevel3=1, envCurve3=0, envTime4=1, envLevel4=1, envCurve4=0, envTime5=1, envLevel5=1, envCurve5=0, envTime6=1, envLevel6=1, envCurve6=0, envTime7=1, envLevel7=1, envCurve7=0, envTime8=0, envLevel8=0, envCurve8=0;
      var sweptEnv, envctl, inSig, numFrames, startTrig, grainDur;
      var latchedTrigRate, latchedStartTrig, latchedOverlap, pan, sweep;
      var onsetDetect, onsetDetectAmp, detectAmp, detectFreq;
      var in,freq,hasFreq,trig,notes,noteAdder=0; // autotune vars
      var bpf0,bpf1,bpf2,bpf3,bpf4,bpf5,bpf6,bpf7,bpf8,bpf9,bpf10,bpf11,bpf12,bpf13,bpf14,bpf15;
      var signed_wobble = wobble_amp*(SinOsc.kr(wobble_rpm/60)**wobble_exp);
      var wow = Select.kr(signed_wobble > 0, signed_wobble, 0);
      var flutter = flutter_amp*SinOsc.kr(flutter_fixedfreq+LFNoise2.kr(flutter_variationfreq));
      var combined_defects = 1 + wow + flutter;
      var pitchshift_note, trigger, pitch_ratio;
      // var sig = In.ar(in, 2), pitch_ratio;
      
      // bpfLevels = Array.fill(16,{0.5});
      // bpfCenterFreqs = Array.fill(16,{440});
      // bpfRQs = Array.fill(16,{1});
      
      // ampMinArray=Array.fill(4,{0.001});
      // ampMaxArray=Array.fill(4,{0.999});
      // freqMinArray=Array.fill(4,{40});
      // freqMaxArray=Array.fill(4,{9600});

      wet = SoundIn.ar([0,1]);
      dry = SoundIn.ar([0,1]);

      //////////////////////////////////////////
      // bandpass filters
      //////////////////////////////////////////

      // amplitude compensation for lower rq of bandpass filter
      bpf0 = BPF.ar(wet,centerFrequency0,reciprocalQuality0, (reciprocalQuality0 ** -1) * (400 / centerFrequency0 ** 0.5));
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
      
      wet = (bpf0*filterLevel0)+(bpf1*filterLevel1)+(bpf2*filterLevel2)+(bpf3*filterLevel3)+(bpf4*filterLevel4)+(bpf5*filterLevel5)+(bpf6*filterLevel6)+(bpf7*filterLevel7)+(bpf8*filterLevel8)+(bpf9*filterLevel9)+(bpf10*filterLevel10)+(bpf11*filterLevel11)+(bpf12*filterLevel12)+(bpf13*filterLevel13)+(bpf14*filterLevel14)+(bpf15*filterLevel15);

      //////////////////////////////////////////
      // amplitude based onset detection
      //////////////////////////////////////////

      onsetDetect = PinkNoise.ar(
        Decay.kr(
          Coyote.kr(
            wet,
            fastMul: 0.6,
            thresh: 0.001
            ),
          0.2
        )
      );

      onsetDetectAmp = Amplitude.kr(onsetDetect);
      detectAmp = Amplitude.kr(wet);

      //frequency detector

      # freq, hasFreq = Tartini.kr(wet);

      freq = Clip.ar(freq, 0.midicps, 127.midicps);

      // outputArray to send to polls
      outArray = Array.fill(numOutValues, 0);
      SendReply.kr(Impulse.kr(50), '/triggerAmpPoll', detectAmp);
      SendReply.kr(Impulse.kr(50), '/triggerOnsetDetectAmpPoll', onsetDetectAmp);
      SendReply.kr(Impulse.kr(50), '/triggerFreqPoll', freq);

      
      //////////////////////////////////////////
      // granular enveloping
      //////////////////////////////////////////
      

      // inSig = DelayC.ar(LPF.ar(inSig.tanh, 2000), 0.1, 0.01);
      wet = DelayC.ar(LPF.ar(wet.tanh, 2000), 0.1, 0.01);

      startTrig = Impulse.ar(trigRate);
      latchedTrigRate = Latch.ar(K2A.ar(trigRate), startTrig);
      latchedStartTrig = Impulse.ar(latchedTrigRate);
      latchedOverlap = Latch.ar(K2A.ar(overlap), startTrig);
      latchedOverlap = max(latchedOverlap, latchedTrigRate * minGrainDur);
      grainDur = (latchedOverlap / latchedTrigRate);
      numFrames = BufFrames.kr(envBuf);

      sweep = Sweep.ar(
        latchedStartTrig,
        latchedOverlap.reciprocal * latchedTrigRate * numFrames,
      ).clip(0, numFrames - 1);

      sweptEnv = BufRd.ar(1,envBuf,sweep,interpolation: interpolation);

      pan = Demand.ar(
          latchedStartTrig,
          0,
          Dswitch1([
              Dseq([1, -1], inf),
              Dwhite(-1, 1)
          ], panType)
      ) * panMax * 0.999;

      //////////////////////////////////////////
      // other effects
      //////////////////////////////////////////


      // flutter + wow
      signed_wobble = wobble_amp*(SinOsc.kr(wobble_rpm/60)**wobble_exp);
      wow = Select.kr(signed_wobble > 0, signed_wobble, 0);
      flutter = flutter_amp*SinOsc.kr(flutter_fixedfreq+LFNoise2.kr(flutter_variationfreq));
      combined_defects = 1 + ((wow + flutter)*effect_flutter_and_wow);
      
      // wet = wet * combined_defects;
      // wet =(effect_flutter_and_wow<1*wet)+(effect_flutter_and_wow>0 * wet *   combined_defects);

      // pitch shift
      trigger = Impulse.ar(pitch_shift_trigger_frequency);
      pitchshift_note = Dseq([pitchshift_note1,pitchshift_note2,pitchshift_note3,pitchshift_note4,pitchshift_note5], inf);
      pitch_ratio = (
        (Demand.ar(trigger, 0, pitchshift_note) + (pitch_shift_base_note.cpsmidi + pitchshift_offset)).midicps 
        / pitch_shift_base_note);
      wet = (wet*(1-effect_pitchshift))+(effect_pitchshift*PitchShift.ar(
        wet,
        grain_size, //0.1, 
        pitch_ratio,
        0,
        time_dispersion //0.01 
      ));

      // phaser
      // wet = (wet*(1-effect_phaser))+(effect_phaser*CombC.ar(wet,1,SinOsc.kr(1/7).range(500,1000).reciprocal,0.05*SinOsc.kr(1/7.1).range(-1,1)));

      // combBuf2 = Buffer.alloc(context.server,48000,2);
      // wet = (wet*(1-effect_phaser))+(effect_phaser*BufCombC.ar(combBuf2,wet,1,SinOsc.kr(1/7).range(500,1000).reciprocal,0.05*SinOsc.kr(1/7.1).range(-1,1),4));

      // distortion
      effect_distortion = Lag.kr(effect_distortion,0.5);
      wet = (wet*(1-(effect_distortion>0)))+(wet*effect_distortion).tanh;


      // bitcrush
      wet = (wet*(1-effect_bitcrush))+(effect_bitcrush*Decimator.ar(wet,Lag.kr(bitcrush_rate,1),Lag.kr(bitcrush_bits,1)));

      // strobe
      // wet = ((effect_strobe<1)*wet)+((effect_strobe>0)*wet*SinOsc.ar(bpm/60));

      // vinyl wow + compressor
      // wet=(effect_vinyl<1*wet)+(effect_vinyl>0* Limiter.ar(Compander.ar(wet,wet,0.5,1.0,0.1,0.1,1,2),dur:0.0008));
      // wet =(effect_vinyl<1*wet)+(effect_vinyl>0* DelayC.ar(wet,0.01,VarLag.kr(LFNoise0.kr(1),1,warp:\sine).range(0,0.01)));


      wet = (Pan2.ar(wet * sweptEnv * amp, pan) * EnvGate.new * enveloper) + (wet*((enveloper+1)%2));

      // delay
      combBuf1 = Buffer.alloc(context.server,48000,2);
      wet = (wet*(1-effect_delay))+(effect_delay*BufCombC.ar(combBuf1,wet,effect_delaytime,effect_delaydecaytime,effect_delaymul));

      //////////////////////////////////////////
      // amplitude based onset and frequency detection
      //////////////////////////////////////////

      // // amplitude based onset detection
      // onsetDetect = PinkNoise.ar(
      //   Decay.kr(
      //     Coyote.kr(
      //       wet,
      //       // fastMul: 0.4,
      //       thresh: 0.0001
      //       ),
      //     0.01
      //   )
      // );

      // onsetDetectAmp = Amplitude.kr(onsetDetect);
      // detectAmp = Amplitude.kr(wet);

      // //frequency detector

      // # freq, hasFreq = Tartini.kr(wet);

      // freq = Clip.ar(freq, 0.midicps, 127.midicps);

      // // outputArray to send to polls
      // outArray = Array.fill(numOutValues, 0);
      // SendReply.kr(Impulse.kr(50), '/triggerAmpPoll', detectAmp);
      // SendReply.kr(Impulse.kr(50), '/triggerOnsetDetectAmpPoll', onsetDetectAmp);
      // SendReply.kr(Impulse.kr(50), '/triggerFreqPoll', freq);


      //////////////////////////////////////////
      // apply drywet, lag, remove DC bias, and send the signal out
      //////////////////////////////////////////

      wet = wet*Lag.kr(amp*drywet,1);
      wet = LeakDC.ar(wet, 0.995);
      dry = dry*Lag.kr(amp*(1-drywet),1);

      // latch to change trigger between the two
      aOrB=ToggleFF.kr(t_trig);
      startA=Latch.kr(start,aOrB);
      endA=Latch.kr(end,aOrB);
      startB=Latch.kr(start,1-aOrB);
      endB=Latch.kr(end,1-aOrB);
      crossfade=Lag.ar(K2A.ar(aOrB),1);

      out = Mix.new([wet,dry*(2-drywet)]);
      
      Out.ar(0,(crossfade*out*0.05))

      // Out.ar(0,out);      
      // Out.ar(0,Balance2.ar(wet, dry, 0));

      // Out.ar(0,Balance2.ar(wet, wet, 0));
    }).add;

    //////////////////////////////////////////
    // polling
    //////////////////////////////////////////
    
    //trigger Polls
    ampPollFunc = OSCFunc({
      arg msg;
      var ampDetectVal = msg[3].asStringPrec(3).asFloat;
      amplitudeDetectPoll.update(ampDetectVal)
    }, path: '/triggerAmpPoll', srcID: context.server.addr);

    onsetDetectAmpPollFunc = OSCFunc({
      arg msg;
      var onsetAmpDetectVal = msg[3].asStringPrec(3).asFloat;      
      onsetAmplitudeDetectPoll.update(onsetAmpDetectVal)
    }, path: '/triggerOnsetDetectAmpPoll', srcID: context.server.addr);

    freqPollFunc = OSCFunc({
      arg msg;
      var freqDetectVal = msg[3].asStringPrec(3).asFloat;
      frequencyDetectPoll.update(freqDetectVal)
    }, path: '/triggerFreqPoll', srcID: context.server.addr);

    // add polls
    amplitudeDetectPoll = this.addPoll(name: "amplitudeDetect", periodic: false);
    onsetAmplitudeDetectPoll = this.addPoll(name: "onsetAmplitudeDetect", periodic: false);
    frequencyDetectPoll = this.addPoll(name: "frequencyDetect", periodic: false);
    
    //////////////////////////////////////////
    // Commands
    //////////////////////////////////////////
      

    //////////////////////////////////////////
    // create splnkr synth instance command
    this.addCommand("splnk", "f", { arg msg;
      var voicesToRemove, newVoice;
      var env;
      var envSig, envBuf;
      var newEnv, envLength;

      context.server.makeBundle(nil, {
        //free the envBuf and create a new one to go with the new Synth
        envLength = envTimes[numSegs-1] * 1000;
        newEnv = Array.new(numSegs-1);
        for (0, numSegs-1, { arg i;
          var xycSegment = Array.new(3);
          xycSegment.insert(0, envTimes[i]);
          xycSegment.insert(1, envLevels[i]);
          xycSegment.insert(2, envCurves[i]);
          newEnv.insert(i,xycSegment);
        });
        envSig = Env.xyc(newEnv).asSignal(envLength);
        envBuf = Buffer.loadCollection(context.server, envSig, 1).bufnum;
        
        // (["wobble_amp, wobble_rpm,wobble_exp,flutter_amp,flutter_fixedfreq,flutter_variationfreq"]).postln;
        // ([wobble_amp, wobble_rpm,wobble_exp,flutter_amp,flutter_fixedfreq,flutter_variationfreq]).postln;
        
        newVoice = (id: id, theSynth: Synth("SplnkrSynth",
        [
          \amp, amp,
          // \env, env,
          \envBuf, envBuf,
          \enveloper,enveloper,
          \trigRate,trigRate,
          \overlap,overlap,
          \panType,panType,
          \panMax,panMax,
          \wobble_rpm, wobble_rpm,
          \wobble_amp, wobble_amp,
          \wobble_exp, wobble_exp, // best an odd power, higher values produce sharper, smaller peak
          \flutter_amp, flutter_amp,
          \flutter_fixedfreq, flutter_fixedfreq,
          \flutter_variationfreq, flutter_variationfreq,
          \effect_phaser,effect_phaser,
          \effect_distortion,effect_distortion,
          \effect_delay,effect_delay,
          \effect_delaytime, effect_delaytime, 
          \effect_delaydecaytime, effect_delaydecaytime,
          \effect_delaymul, effect_delaymul,
          \effect_pitchshift,effect_pitchshift, 
          \pitchshift_note1,pitchshift_note1,
          \pitchshift_note2,pitchshift_note2,
          \pitchshift_note3,pitchshift_note3,
          \pitchshift_note4,pitchshift_note4,
          \pitchshift_note5,pitchshift_note5,
          \pitch_shift_trigger_frequency,pitch_shift_trigger_frequency,
          \grain_size,grain_size,
          \time_dispersion,time_dispersion,
          \effect_flutter_and_wow,effect_flutter_and_wow,
          // \pitchshift_midi_offset,pitchshift_midi_offset,
        ],
        target: voiceGroup).onFree({ 
            voiceList.remove(newVoice); 
          })
        );

        voiceList.addFirst(newVoice);

        // set splnkrVoice to the most recent voice instantiated
        splnkrVoice = voiceList.detect({ arg item, i; item.id == id; });
        id = id+1;
      });

      // Free the existing voice if it exists
      if((voiceList.size > 0), {
        voiceList.do{ arg v,i; 
          v.theSynth.set(\t_trig, 1);
          if (i > 1){
            v.theSynth.set(\gate, 0);
            v.theSynth.free;
          }
        };
      });

    });

    this.addCommand("crossfade", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\t_trig, msg[1]);
      };
    });

    this.addCommand("set_filter_level", "ff", { arg msg;
      var i = msg[1];
      var filterLevel = msg[2];

      if(splnkrVoice.theSynth.isNil == false){ 
        case
          {i==0} {splnkrVoice.theSynth.set(\filterLevel0, filterLevel)}
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
          {i==15} {splnkrVoice.theSynth.set(\filterLevel15, filterLevel)};
      };
    });

    this.addCommand("set_center_frequency", "ff", { arg msg;
      var i = msg[1];
      var centerFrequency = msg[2];
      if(splnkrVoice.theSynth.isNil == false){ 
        case
          {i==0} {splnkrVoice.theSynth.set(\centerFrequency0, centerFrequency); ([i,centerFrequency]);}
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
          {i==15} {splnkrVoice.theSynth.set(\centerFrequency15, centerFrequency); ([i,centerFrequency]);};
      };
    });

    this.addCommand("set_reciprocal_quality", "ff", { arg msg;
      var i = msg[1];
      var reciprocalQuality = msg[2];
      if(splnkrVoice.theSynth.isNil == false){ 
        case
          {i==0} {splnkrVoice.theSynth.set(\reciprocalQuality0, reciprocalQuality)}
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
          {i==15} {splnkrVoice.theSynth.set(\reciprocalQuality15, reciprocalQuality)};
      };
    });
    // this.addCommand("set_filter_level", "ff", { arg msg;
    //   var i = msg[1];
    //   var filterLevel = msg[2];
    //   bpfLevelsArray.put(i,filterLevel);
    //   if(splnkrVoice.theSynth.isNil == false){ 
    //     splnkrVoice.theSynth.set(\bpfLevels, bpfLevelsArray);
    //     // (bpfLevels).postln;
    //   };
      
    // });

    // this.addCommand("set_center_frequency", "ff", { arg msg;
    //   var i = msg[1];
    //   var centerFrequency = msg[2];
    //   bpfCenterFreqsArray.put(i,centerFrequency);
    //   if(splnkrVoice.theSynth.isNil == false){ 
    //     splnkrVoice.theSynth.set(\bpfCenterFreqs, bpfCenterFreqsArray)
    //   };
      
    // });

    // this.addCommand("set_reciprocal_quality", "ff", { arg msg;
    //   var i = msg[1];
    //   var reciprocalQuality = msg[2];
    //   bpfRQsArray.put(i,reciprocalQuality);
    //   if(splnkrVoice.theSynth.isNil == false){ 
    //     splnkrVoice.theSynth.set(\bpfRQs, bpfRQsArray)
    //   };
    // });

    //////////////////////////////////////////
    // granular enveloping commands
    this.addCommand("set_numSegs", "f", { arg msg;
    	numSegs = msg[1];
    });


    this.addCommand("set_env_levels", "ffffffff", { arg msg;
      // (["set_env_levels"]).postln;
      envLevels = Array.new(numSegs);
      for (0, numSegs-1, { arg i;
        var val = msg[i+1];
        envLevels.insert(i,val);
      }); 
    });

    this.addCommand("set_env_times", "ffffffff", { arg msg;
      // var envLength;
      envTimes = Array.new(numSegs);
      // (["set_env_times"]).postln;
      for (0, numSegs-1, { arg i; 
        var val = msg[i+1];
        envTimes.insert(i,val);
      }); 
    });
    
    this.addCommand("set_env_curves", "ffffffff", { arg msg;
      // (["set_env_curves"]).postln;
      envCurves = Array.new(numSegs);
      for (0, numSegs-1, { arg i;
        var val = msg[i+1];
        envCurves.insert(i,val);
      }); 
    });

    this.addCommand("enveloper", "i", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\enveloper, msg[1]);
        enveloper = msg[1];
      };
    });

    this.addCommand("trig_rate", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\trigRate, msg[1]);
        trigRate = msg[1];
      };
    });

    this.addCommand("overlap", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\overlap, msg[1]);
        overlap = msg[1];
      };
    });
    this.addCommand("pan_type", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\panType, msg[1]);
        panType = msg[1];
      };
    });
    this.addCommand("pan_max", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\panMax, msg[1]);
        panMax = msg[1];
      };
    });

    //////////////////////////////////////////
    // other effect commands
    this.addCommand("amp", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\amp, msg[1]);
        amp = msg[1];
      };
    });
    
    this.addCommand("bpm", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\bpm, msg[1]);
        bpm = msg[1]
      };
    });

    this.addCommand("drywet", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\drywet, msg[1]);
        drywet = msg[1];
      };
    });

    this.addCommand("phaser", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\effect_phaser, msg[1]);
        effect_phaser = msg[1];    
      };
    });

    this.addCommand("distortion", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\effect_distortion, msg[1]);
        effect_distortion = msg[1];    
      };
    });

    this.addCommand("delay", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\effect_delay, msg[1]);
        effect_delay = msg[1];    
      };
    });

    this.addCommand("delaytime", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\effect_delaytime, msg[1]);
        effect_delaytime = msg[1];    
      };
    });

    this.addCommand("delaydecaytime", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\effect_delaydecaytime, msg[1]);
        effect_delaydecaytime = msg[1];    
      };
    });

    this.addCommand("delaymul", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\effect_delaymul, msg[1]);
        effect_delaymul = msg[1];    
      };
    });



    this.addCommand("strobe", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\effect_strobe, msg[1]);
        effect_strobe = msg[1];    
      };
    });

    // this.addCommand("vinyl", "f", { arg msg;
    //   if (voiceList.size > 0){ 
    //     splnkrVoice.theSynth.set(\effect_vinyl, msg[1]);
    //   };
    // });

    this.addCommand("flutter_and_wow", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\flutter_and_wow, msg[1]);
      };
    });

    this.addCommand("pitchshift", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\effect_pitchshift, msg[1]);
        effect_pitchshift = msg[1];    
      };
    });

    this.addCommand("pitch_shift_trigger_frequency", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\pitch_shift_trigger_frequency, msg[1]);
        pitch_shift_trigger_frequency = msg[1];    
      };
    });

    this.addCommand("pitchshift_note1", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\pitchshift_note1, msg[1]);
      };
    });

    this.addCommand("pitchshift_note2", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\pitchshift_note2, msg[1]);
      };
    });

    this.addCommand("pitchshift_note3", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\pitchshift_note3, msg[1]);
      };
    });

    this.addCommand("pitchshift_note4", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\pitchshift_note4, msg[1]);
      };
    });

    this.addCommand("pitchshift_note5", "f", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(\pitchshift_note5, msg[1]);
      };
    });

    this.addCommand("grain_size", "f", { arg msg;
      if (voiceList.size > 0){ 
        // splnkrVoice.theSynth.set(\grain_size, msg[1]);
        grain_size = msg[1];
      };
    });

    this.addCommand("time_dispersion", "f", { arg msg;
      if (voiceList.size > 0){ 
        // splnkrVoice.theSynth.set(\time_dispersion, msg[1]);
        time_dispersion = msg[1];
      };
    });


    // this.addCommand("pitchshift_midi_offset", "f", { arg msg;
    //   if (voiceList.size > 0){ 
    //     splnkrVoice.theSynth.set(\pitchshift_midi_offset, msg[1]);
    //     pitchshift_midi_offset = msg[1];
    //   };
    // });
      

    this.addCommand("bitcrush", "fff", { arg msg;
      if (voiceList.size > 0){ 
        splnkrVoice.theSynth.set(
          \effect_bitcrush, msg[1],
          \bitcrush_bits, msg[2],
          \bitcrush_rate, msg[3],
        );
      };
    });

    //////////////////////////////////////////
    // wow and flutter commands
    this.addCommand("wobble_rpm", "f", { arg msg;
      wobble_rpm = msg[1];
    });
    
    this.addCommand("wobble_amp", "f", { arg msg;
      wobble_amp = msg[1];
    });
    
    this.addCommand("wobble_exp", "f", { arg msg;
      wobble_exp = msg[1];
    });
    
    this.addCommand("flutter_amp", "f", { arg msg;
      flutter_amp = msg[1];
    });
    
    this.addCommand("flutter_fixedfreq", "f", { arg msg;
      flutter_fixedfreq = msg[1];
    });
    
    this.addCommand("flutter_variationfreq", "f", { arg msg;
      flutter_variationfreq = msg[1];
    });
    


  }

  free {
    splnkrVoice.free;
    voiceGroup.free;
    voiceList.free;
    wet.free;
    ampPollFunc.free;
    onsetDetectAmpPollFunc.free;
  }
}

