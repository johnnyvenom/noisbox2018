// Here is a SynthDef for a basic 2 oscillator polyphonic subtractive synth.
"adding synthdefs".postln;

SynthDef(\poly, {
	arg oscType = 0,
	oscType2 = 1,
	pan = 0,
	level = 0.5,
	cutoff = 500,
	gain = 3.3,
	attack = 0.1,
	decay = 0.1,
	sustain = 0.7,
	release = 0.2,
	attack_f = 0.1,
	decay_f = 0.1,
	sustain_f = 0.9,
	release_f = 0.2,
	gate =  1,
	freq = 440;

	var oscArray = [Saw.ar(freq ), SinOsc.ar(freq), Pulse.ar(freq)];
	var oscArray2 = [Saw.ar(freq), SinOsc.ar(freq), Pulse.ar(freq)];
	var ampEnv = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate, doneAction:2);
	var filterEnv = EnvGen.ar(Env.adsr(attack_f, decay_f, sustain_f, release_f));
	var osc1 = Select.ar(oscType, oscArray);
	var osc2 = Select.ar(oscType2, oscArray2);
	var fade = XFade2.ar(osc1, osc2, pan , level * ampEnv);
	var filter = MoogFF.ar(fade, cutoff * filterEnv, gain, mul: 0.8);
	filter = filter!2;
	Out.ar(0,filter)
}).add;

// Here is a SynthDef for a simple square wave synth.
SynthDef.new(\square, {
	arg freq = 220, width = 0.5, gate = 0;
	var sig, env;
	env = EnvGen.kr(Env.adsr, gate*Line.kr(1, 0, 60), doneAction: 2);
	sig = Pulse.ar(freq, width);
	sig = sig!2 * env;
	Out.ar(0, sig);
}).add;


