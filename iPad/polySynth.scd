// Here is a SynthDef for a basic 2 oscillator polyphonic subtractive synth.
// Basic synth modeled after a miniMoog
"adding synthdefs".postln;

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
	arg freq1 = 440,
	freq2 = 440,
	osc1sel = ~polyCtl[\osc1sel],
	osc2sel = ~polyCtl[\osc2sel],
	osc1tune = ~polyCtl[\osc1tune],
	osc2tune = ~polyCtl[\osc2tune],
	oscMix = ~polyCtl[\oscMix],
	oscNoise = ~polyCtl[\oscNoise],
	level = 0.5,
	lpfCut = ~polyCtl[\lpfCut],
	lpfRes = ~polyCtl[\lpfRes],
	lpfEnv = ~polyCtl[\lpfEnv],
	lpfMix = ~polyCtl[\lpfMix],
	lpfAtt = ~polyCtl[\lpfAtt],
	lpfDec = ~polyCtl[\lpfDec],
	lpfSus = ~polyCtl[\lpfSus],
	lpfRel = ~polyCtl[\lpfRel],
	ampAtt = ~polyCtl[\ampAtt],
	ampDec = ~polyCtl[\ampDec],
	ampSus = ~polyCtl[\ampSus],
	ampRel = ~polyCtl[\ampRel],
	gate =  1;

	// Sounds sources:
	var oscArray = [SinOsc.ar(freq1), Saw.ar(freq1), Pulse.ar(freq1)];
	var oscArray2 = [SinOsc.ar(freq2), Saw.ar(freq2), Pulse.ar(freq2)];
	var noise = PinkNoise.ar();

	// mix sound sources
	var osc1 = Select.ar(osc1sel, oscArray);
	var osc2 = Select.ar(osc2sel, oscArray2);
	var mix = XFade2.ar(osc1, osc2, oscMix);
	var ampEnv = EnvGen.kr(Env.adsr(ampAtt, ampDec, ampSus, ampRel), gate, doneAction:2);
	var noiseMix = XFade2.ar(mix, noise, oscNoise, level * ampEnv);

	// filter section
	var filterEnv = EnvGen.kr(Env.adsr(lpfAtt, lpfDec, lpfSus, lpfRel, lpfEnv, bias: 1 - lpfEnv));
	var filterMix = MoogFF.ar(noiseMix, lpfCut * filterEnv, lpfRes);
	var outSig = XFade2.ar(noiseMix*0.5, filterMix, lpfMix); // mix pre and post filter signals

	outSig = Limiter.ar(outSig!2, 0.5, 0.01);
	Out.ar(0,outSig);
}).add;


// ***** polySynth controls *****
~osc1sel = { // osc 1 choose between sine, saw or pulse waveforms
	arg val;
	if (val == 1, {
		~polyCtl[\osc1sel] = (~polyCtl[\osc1sel] + 1) % 3;
		~polyCtl[\osc1sel].postln;
		~synthGroup.set(\osc1sel, ~polyCtl[\osc1sel]);
	});
};

~osc2sel = { // osc 2 choose between sine, saw or pulse waveforms
	arg val;
	if (val == 1, {
		~polyCtl[\osc2sel] = (~polyCtl[\osc2sel] + 1) % 3;
		~polyCtl[\osc2sel].postln;
		~synthGroup.set(\osc2sel, ~polyCtl[\osc2sel]);
	});
};

~osc1tune = { // osc 1 tuning +/- (semitones)
	arg val;
	g = ControlSpec(~tuneMin * -1, ~tuneMax);
	~polyCtl[\osc1tune] = g.map(val);
	128.do({
		arg i;
		i+~polyCtl[\osc1tune];
		~keys[i].set(\freq1, (i+~polyCtl[\osc1tune]).midicps);
	});
};

~osc2tune = { // osc 2 tuning +/- (semitones)
	arg val;
	g = ControlSpec(~tuneMin * -1, ~tuneMax);
	~polyCtl[\osc2tune] = g.map(val);
	128.do({
		arg i;
		i+~polyCtl[\osc2tune];
		~keys[i].set(\freq2, (i+~polyCtl[\osc2tune]).midicps);
	});
};

~oscMix = { // mix osc 1 <-> osc 2
	arg val;
	~polyCtl[\oscMix] = (val*2)-1;
	~synthGroup.set(\oscMix, ~polyCtl[\oscMix]);
};

~oscNoise = { // mix osc1/2 <-> noise
	arg val;
	~polyCtl[\oscNoise] = (val*2)-1;
	~synthGroup.set(\oscNoise, ~polyCtl[\oscNoise]);
};

~lpfCut = { // Filter cutoff frequency (Hz)
	arg val;
	g = ControlSpec(15, 12000, \exp);
	~polyCtl[\lpfCut] = g.map(val);
	// ~polyCtl[\lpfCut].postln;
	~synthGroup.set(\lpfCut, ~polyCtl[\lpfCut]);
};

~lpfRes = { // Filter resonance (gain, 0 - 4)
	arg val;
	g = ControlSpec(0, 4, \lin);
	~polyCtl[\lpfRes] = g.map(val);
	~polyCtl[\lpfRes].postln;
	~synthGroup.set(\lpfRes, ~polyCtl[\lpfRes]);
};

~lpfEnv = { // Filter envelope amount ( 0 - 1)
	arg val;
	~polyCtl[\lpfEnv] = val;
	~polyCtl[\lpfEnv].postln;
	~synthGroup.set(\lpfEnv, ~polyCtl[\lpfEnv]);
};

~lpfMix = { // Mix pre <-> post filter
	arg val;
	~polyCtl[\lpfMix] = (val*2)-1;
	~synthGroup.set(\lpfMix, ~polyCtl[\lpfMix]);
};

~lpfAtt = { // Filter ADSR - Attack (sec)
	arg val;
	~polyCtl[\lpfAtt] = val * ~envSegMax;
	~synthGroup.set(\lpfAtt, ~polyCtl[\lpfAtt]);
};

~lpfDec = { // Filter ADSR - Decay (sec)
	arg val;
	~polyCtl[\lpfDec] = val * ~envSegMax;
	~synthGroup.set(\lpfDec, ~polyCtl[\lpfDec]);
};

~lpfSus = { // Filter ADSR - Sustain (level)
	arg val;
	~polyCtl[\lpfSus] = val;
	~synthGroup.set(\lpfSus, ~polyCtl[\lpfSus]);
};

~lpfRel = { // Filter ADSR - Release (sec)
	arg val;
	~polyCtl[\lpfRel] = val * ~envSegMax;
	~synthGroup.set(\lpfRel, ~polyCtl[\lpfRel]);
};

~ampAtt = { // Amplitude ADSR - Attack (sec)
	arg val;
	~polyCtl[\ampAtt] = val * ~envSegMax;
	~synthGroup.set(\ampAtt, ~polyCtl[\ampAtt]);
};

~ampDec = { // Amplitude ADSR - Decay (sec)
	arg val;
	~polyCtl[\ampDec] = val * ~envSegMax;
	~synthGroup.set(\ampDec, ~polyCtl[\ampDec]);
};

~ampSus = { // Amplitude ADSR - Sustain (level)
	arg val;
	~polyCtl[\ampSus] = val;
	~synthGroup.set(\ampSus, ~polyCtl[\ampSus]);
};

~ampRel = { // Amplitude ADSR - Release (sec)
	arg val;
	~polyCtl[\ampRel] = val * ~envSegMax;
	~synthGroup.set(\ampRel, ~polyCtl[\ampRel]);
};