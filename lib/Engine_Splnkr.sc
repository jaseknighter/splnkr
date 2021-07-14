// CroneEngine_Splnkr
// Inspirations:
//   @infinitedigits/@schollz StoneSoup (https://github.com/schollz/stonesoup)
//   @markeats/@markwheeler Passerby (https://github.com/markwheeler/passersby)

Engine_Splnkr : CroneEngine {
  var <synth;
  var numOutValues = 1;
  var pollFunc;
  var outArray;
  var amplitudeDetectPoll;

  var wobble_rpm=33;
  var wobble_amp=0.05; 
  var wobble_exp=39;
  var flutter_amp=0.03;
  var flutter_fixedfreq=6;
  var flutter_variationfreq=2;  

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    synth = {
      arg amp=1,bpm=120,drywet=1,
      effect_phaser=0,effect_distortion=0,effect_delay=0,
      effect_bitcrush,bitcrush_bits=10,bitcrush_rate=12000, // this has parameters
      effect_strobe=0,effect_vinyl=0,
      wobble_rpm=33, wobble_amp=0.05, wobble_exp=39, flutter_amp=0.03, flutter_fixedfreq=6, flutter_variationfreq=2;
      var wet, dry, detect,detectAmp,zeroCrossingFreq;
      
      // alt flutter and wow code
      // var signed_wobble = wobble_amp*(SinOsc.kr(wobble_rpm/60)**wobble_exp);
      // var wow = Select.kr(signed_wobble > 0, signed_wobble, 0);
      // var flutter = flutter_amp*SinOsc.kr(flutter_fixedfreq+LFNoise2.kr(flutter_variationfreq));
      // var combined_defects = 1 + wow + flutter;

      dry = SoundIn.ar([0,1]);
      wet = SoundIn.ar([0,1]);

      // amplitude based onset detection
      detect = PinkNoise.ar(
        Decay.kr(
          Coyote.kr(
            dry,
            fastMul: 0.6,
            thresh: 0.001), 
          0.2
        )
      );

      // zeroCrossingFreq = ZeroCrossing.ar(in);
      // pitch = Pitch.kr(in, ampThreshold: 0.02, median: 7);

      // TODO: what is a good order for these?

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

      detectAmp = Amplitude.kr(detect);
      
      // outputArray to send to polls
      outArray = Array.fill(numOutValues, 0);
      outArray[0] = detectAmp; // amplitude detection
      
      SendReply.kr(Impulse.kr(15), '/triggerPolls', outArray);
      
      dry = dry*Lag.kr(amp*(1-drywet),1);
      // dry = dry*(1-(drywet+0.001));
      wet = wet*Lag.kr(amp*drywet,1);
      // wet = wet*(drywet+0.001);
      Out.ar(0, [detect, wet]);

    }.play( target: context.xg);

    //trigger Polls
    pollFunc = OSCFunc({
      arg msg;
      
      var adVal = msg[4].snap(resolution: 0.001, margin: 0.005, strength: 1.0);
      amplitudeDetectPoll.update(adVal);
    }, path: '/triggerPolls', srcID: context.server.addr);

    // Polls
    amplitudeDetectPoll = this.addPoll(name: "amplitudeDetect", periodic: false);
    
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

    this.addCommand("bitcrush", "fff", { arg msg;
      synth.set(
        \effect_bitcrush, msg[1],
        \bitcrush_bits, msg[2],
        \bitcrush_rate, msg[3],
      );
    });
  }

  free {
    synth.free;
    pollFunc.free;
  }
}