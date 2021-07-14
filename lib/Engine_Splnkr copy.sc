// CroneEngine_Splnkr
// Inspirations:
//   @infinitedigits/@schollz StoneSoup (https://github.com/schollz/stonesoup)
//   @markeats/@markwheeler Passerby (https://github.com/markwheeler/passersby)

Engine_Splnkrr : CroneEngine {
  var <synth;
  var numOutValues = 1;
  var pollFunc;
  var outArray;
  var amplitudeDetectPoll;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    synth = {
      arg amp=1,bpm=120,
      effect_phaser=0,effect_distortion=0,effect_delay=0,
      effect_bitcrush,bitcrush_bits=10,bitcrush_rate=12000, // this has parameters
      effect_strobe=0,effect_vinyl=0;
      var in, detect,detectAmp,zeroCrossingFreq;

      in = SoundIn.ar([0,1]);

      // amplitude based onset detection
      detect = PinkNoise.ar(
        Decay.kr(
          Coyote.kr(
            in,
            fastMul: 0.6,
            thresh: 0.001), 
          0.2
        )
      );

      // zeroCrossingFreq = ZeroCrossing.ar(in);
      // pitch = Pitch.kr(in, ampThreshold: 0.02, median: 7);

      // TODO: what is a good order for these?

      // phaser
      in = (in*(1-effect_phaser))+(effect_phaser*CombC.ar(in,1,SinOsc.kr(1/7).range(500,1000).reciprocal,0.05*SinOsc.kr(1/7.1).range(-1,1)));

      // distortion
      effect_distortion = Lag.kr(effect_distortion,0.5);
      in = (in*(1-(effect_distortion>0)))+(in*effect_distortion).tanh;

      // delay 
      in = (in*(1-effect_delay))+(effect_delay*CombC.ar(in,5,0.2,4));
      // TODO: explode some options

      // bitcrush
      in = (in*(1-effect_bitcrush))+(effect_bitcrush*Decimator.ar(in,Lag.kr(bitcrush_rate,1),Lag.kr(bitcrush_bits,1)));

      // strobe
      in = ((effect_strobe<1)*in)+((effect_strobe>0)*in*SinOsc.ar(bpm/60));

      // vinyl wow + compressor
      in=(effect_vinyl<1*in)+(effect_vinyl>0* Limiter.ar(Compander.ar(in,in,0.5,1.0,0.1,0.1,1,2),dur:0.0008));
      in =(effect_vinyl<1*in)+(effect_vinyl>0* DelayC.ar(in,0.01,VarLag.kr(LFNoise0.kr(1),1,warp:\sine).range(0,0.01)));                
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
      
      Out.ar(0, [detect, in*Lag.kr(amp,1)]);

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