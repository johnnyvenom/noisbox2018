// Here is a SynthDef for a basic 2 oscillator polyphonic subtractive synth.

//init params for polySynth.

fork({
	var params = [
		[\osc1sel,"OSC1sel",\button, 0, \SIN],
		[\osc2sel,"OSC2sel",\button, 1, \SAW],
		[\osc1tune,"Osc1tune",\knob, 0, 0.5],
		[\osc2tune,"Osc2tune",\knob, 0, 0.5],
		[\oscMix,"OscMix",\knob, 0, 0.5],
		[\oscNoise,"OscNoise",\knob, -1, 0],
		[\lpfCut,"LPF cut",\knob, 500, 500.explin(15, 12000, 0.001, 1)],
		[\lpfRes,"LPF res",\knob, 3.3, 3.3.linlin(0,4,0,1)],
		[\lpfEnv,"LPF Env",\knob, 1, 1],
		[\lpfMix,"LPF Mix",\knob, 1, 1],
		[\lpfAtt,"LPF Att",\knob, 0.1, 0.1.linlin(0,~envSegMax,0,1)],
		[\lpfDec,"LPF Dec",\knob, 0.1, 0.1.linlin(0,~envSegMax,0,1)],
		[\lpfSus,"LPF Sus",\knob, 0.9, 0.9.linlin(0,~envSegMax,0,1)],
		[\lpfRel,"LPF Rel",\knob, 0.2, 0.2.linlin(0,~envSegMax,0,1)],
		[\ampAtt,"Amp Att",\knob, 0.1, 0.1.linlin(0,~envSegMax,0,1)],
		[\ampDec,"Amp Dec",\knob, 0.1, 0.1.linlin(0,~envSegMax,0,1)],
		[\ampSus,"Amp Sus",\knob, 0.7, 0.7.linlin(0,~envSegMax,0,1)],
		[\ampRel,"Amp Rel",\knob, 0.2, 0.2.linlin(0,~envSegMax,0,1)]
	];

	~d.pSynth = ();
	~envSegMax = 5; // Max length of envelope segments (seconds)

	params.size.do({
		| i |
		~d[\pSynth][params[i][0]] = ();
/*		~d[\pSynth][params[i][0]].put(\inst, \pSynth); // set \inst
		~d[\pSynth][params[i][0]].put(\ctl, params[i][0]); // set \ctl*/
		~d[\pSynth][params[i][0]].put(\label, params[i][1]); // set label
		~d[\pSynth][params[i][0]].put(\type, params[i][2]); // set label
		~d[\pSynth][params[i][0]].put(\outVal, params[i][3]); // set initial output value
		~d[\pSynth][params[i][0]].put(\normVal, params[i][4]); // set initial normalized value
	});
});

~polyCtl = Dictionary.new(18);
~polyCtl.add(\osc1sel -> 0);
~polyCtl.add(\osc2sel -> 1);
~polyCtl.add(\osc1tune -> 0);
~polyCtl.add(\osc2tune -> 0);
~polyCtl.add(\oscMix -> 0);
~polyCtl.add(\oscNoise -> -1);
~polyCtl.add(\lpfCut -> 500);
~polyCtl.add(\lpfRes -> 3.3);
~polyCtl.add(\lpfEnv -> 1.0);
~polyCtl.add(\lpfMix -> 1.0);
~polyCtl.add(\lpfAtt -> 0.1);
~polyCtl.add(\lpfDec -> 0.1);
~polyCtl.add(\lpfSus -> 0.9);
~polyCtl.add(\lpfRel -> 0.2);
~polyCtl.add(\ampAtt -> 0.1);
~polyCtl.add(\ampDec -> 0.1);
~polyCtl.add(\ampSus -> 0.7);
~polyCtl.add(\ampRel -> 0.2);

SynthDef(\poly, {
	arg out,
	freq1 = 440,
	freq2 = 440,
	osc1sel = ~d.pSynth.osc1sel.outVal,
	osc2sel = ~d.pSynth.osc2sel.outVal,
	osc1tune = ~d.pSynth.osc1tune.outVal,
	osc2tune = ~d.pSynth.osc2tune.outVal,
	oscMix = ~d.pSynth.oscMix.outVal,
	oscNoise = ~d.pSynth.oscNoise.outVal,
	lpfCut = ~d.pSynth.lpfCut.outVal,
	lpfRes = ~d.pSynth.lpfRes.outVal,
	lpfEnv = ~d.pSynth.lpfEnv.outVal,
	lpfMix = ~d.pSynth.lpfMix.outVal,
	lpfAtt = ~d.pSynth.lpfAtt.outVal,
	lpfDec = ~d.pSynth.lpfDec.outVal,
	lpfSus = ~d.pSynth.lpfSus.outVal,
	lpfRel = ~d.pSynth.lpfRel.outVal,
	ampAtt = ~d.pSynth.ampAtt.outVal,
	ampDec = ~d.pSynth.ampDec.outVal,
	ampSus = ~d.pSynth.ampSus.outVal,
	ampRel = ~d.pSynth.ampRel.outVal,
	gate =  1;

	// Sound sources:
	var oscArray = [SinOsc.ar(freq1), Saw.ar(freq1), Pulse.ar(freq1)];
	var oscArray2 = [SinOsc.ar(freq2), Saw.ar(freq2), Pulse.ar(freq2)];
	var noise = PinkNoise.ar();

	// mix sound sources
	var osc1 = Select.ar(osc1sel, oscArray);
	var osc2 = Select.ar(osc2sel, oscArray2);
	var mix = XFade2.ar(osc1, osc2, oscMix);
	var ampEnv = EnvGen.kr(Env.adsr(ampAtt, ampDec, ampSus, ampRel), gate, doneAction:2);
	var noiseMix = XFade2.ar(mix, noise, oscNoise, ampEnv);

	// filter section
	var filterEnv = EnvGen.kr(Env.adsr(lpfAtt, lpfDec, lpfSus, lpfRel, lpfEnv, bias: 1 - lpfEnv));
	var filterMix = MoogFF.ar(noiseMix, lpfCut * filterEnv, lpfRes);
	var outSig = XFade2.ar(noiseMix*0.5, filterMix, lpfMix*2-1); // mix pre and post filter signals

	Out.ar(out,outSig!2);
}).add;

// ***** polySynth controls *****
~osc1sel = { // osc 1 choose between sine, saw or pulse waveforms
	arg val;
	var inst = \pSynth, ctl = \osc1sel, normVal;
	var wave = [\SIN, \SAW, \SQR];
	var outVal = ~d.pSynth.osc1sel.outVal+1%3;
	~grp.psynth.set(\osc1sel, outVal);

	~polyCtl[\osc1sel] = outVal;
	normVal = wave[outVal];
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~osc2sel = { // osc 2 choose between sine, saw or pulse waveforms
	arg val;
	var inst = \pSynth, ctl = \osc2sel, normVal;
	var wave = [\SIN, \SAW, \SQR];
	var outVal = ~d.pSynth.osc2sel.outVal+1%3;
	~grp.psynth.set(\osc2sel, outVal);

	~polyCtl[\osc2sel] = outVal;
	normVal = wave[outVal];
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~osc1tune = { // osc 1 tuning +/- (semitones)
	arg val;
	var inst = \pSynth, ctl = \osc1tune, normVal = val;
	var outVal = val.linlin(0, 1, ~tuneMin * -1, ~tuneMax);
	128.do({
		arg i;
		i+outVal;
		~keys[i].set(\freq1, (i+outVal).midicps);
	});

	~polyCtl[\osc1tune] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~osc2tune = { // osc 2 tuning +/- (semitones)
	arg val;
	var inst = \pSynth, ctl = \osc2tune, normVal = val;
	var outVal = val.linlin(0, 1, ~tuneMin * -1, ~tuneMax);
	128.do({
		arg i;
		i+outVal;
		~keys[i].set(\freq2, (i+outVal).midicps);
	});

	~polyCtl[\osc2tune] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~oscMix = { // mix osc 1 <-> osc 2
	arg val;
	var inst = \pSynth, ctl = \oscMix, normVal = val;
	var outVal = (val*2)-1;
	~grp.psynth.set(\oscMix, outVal);

	~polyCtl[\oscMix] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~oscNoise = { // mix osc1/2 <-> noise
	arg val;
	var inst = \pSynth, ctl = \oscNoise, normVal = val;
	var outVal = (val*2)-1;
	~grp.psynth.set(\oscNoise, outVal);

	~polyCtl[\oscNoise] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~lpfCut = { // Filter cutoff frequency (Hz)
	arg val;
	var inst = \pSynth, ctl = \lpfCut, normVal = val;
	var outVal = val.linexp(0, 1, 15, 12000);
	~grp.psynth.set(\lpfCut, outVal);

	~polyCtl[\lpfCut] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~lpfRes = { // Filter resonance (gain, 0 - 4)
	arg val;
	var inst = \pSynth, ctl = \lpfRes, normVal = val;
	var outVal = val.linlin(0, 1, 0, 4);
	~grp.psynth.set(\lpfRes, outVal);

	~polyCtl[\lpfRes] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~lpfEnv = { // Filter envelope amount ( 0 - 1)
	arg val;
	var inst = \pSynth, ctl = \lpfEnv, normVal = val;
	var outVal = val;
	~grp.psynth.set(\lpfEnv, outVal);

	~polyCtl[\lpfEnv] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~lpfMix = { // Mix pre <-> post filter
	arg val;
	var inst = \pSynth, ctl = \lpfMix, normVal = val;
	var outVal = val;
	~grp.psynth.set(\lpfMix, outVal);

	~polyCtl[\lpfMix] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~lpfAtt = { // Filter ADSR - Attack (sec)
	arg val;
	var inst = \pSynth, ctl = \lpfAtt, normVal = val;
	var outVal = val * ~envSegMax;
	~grp.psynth.set(\lpfAtt, outVal);

	~polyCtl[\lpfAtt] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~lpfDec = { // Filter ADSR - Decay (sec)
	arg val;
	var inst = \pSynth, ctl = \lpfDec, normVal = val;
	var outVal = val * ~envSegMax;
	~grp.psynth.set(\lpfDec, outVal);

	~polyCtl[\lpfDec] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~lpfSus = { // Filter ADSR - Sustain (level)
	arg val;
	var inst = \pSynth, ctl = \lpfSus, normVal = val;
	var outVal = val * ~envSegMax;
	~grp.psynth.set(\lpfSus, outVal);

	~polyCtl[\lpfSus] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~lpfRel = { // Filter ADSR - Release (sec)
	arg val;
	var inst = \pSynth, ctl = \lpfRel, normVal = val;
	var outVal = val * ~envSegMax;
	~grp.psynth.set(\lpfRel, outVal);

	~polyCtl[\lpfRel] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~ampAtt = { // Amp ADSR - Attack (sec)
	arg val;
	var inst = \pSynth, ctl = \ampAtt, normVal = val;
	var outVal = val * ~envSegMax;
	~grp.psynth.set(\ampAtt, outVal);

	~polyCtl[\ampAtt] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~ampDec = { // Amp ADSR - Decay (sec)
	arg val;
	var inst = \pSynth, ctl = \ampDec, normVal = val;
	var outVal = val * ~envSegMax;
	~grp.psynth.set(\ampDec, outVal);

	~polyCtl[\ampDec] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~ampSus = { // Amp ADSR - Sustain (level)
	arg val;
	var inst = \pSynth, ctl = \ampSus, normVal = val;
	var outVal = val * ~envSegMax;
	~grp.psynth.set(\ampSus, outVal);

	~polyCtl[\ampSus] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};

~ampRel = { // Amp ADSR - Release (sec)
	arg val;
	var inst = \pSynth, ctl = \ampRel, normVal = val;
	var outVal = val * ~envSegMax;
	~grp.psynth.set(\ampRel, outVal);

	~polyCtl[\ampRel] = outVal;
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};