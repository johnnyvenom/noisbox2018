(
"controls.scd".loadRelative; // contains OSCdefs and input functions.
"polySynth.scd".loadRelative; // contains the SynthDefs

// *********************************
// GLOBAL vars:
// *********************************

~page = 0; //page up/down through sets of controls.
~octave = 2; //default octave for the synthesizer; range is -2 to 8.
~numKeys = 24; // number of keys on the keyboard
~tuneMax = 24; // Oscillator tune up range (semitones)
~tuneMin = 24; // Oscillator tune down range (semitones)
~envSegMax = 10; // Max length of envelope segments (seconds)

~synthGroup = Group.new; // put all Synths in a group, so abandoned voices can be eventually freed
~keys = Array.newClear(128);

~noteAction = { // when any key is pressed or released, this happens
	arg status, keyNum, statusArray; // an array of values. 0 = note is off, 1 = note is on.
	var octaveOffset = (~octave*12)+24;
	var isSilent = true;
	var noteFreq1 = (keyNum + octaveOffset + ~polyCtl[\osc1tune]).clip(0, 127).midicps;
	var noteFreq2 = (keyNum + octaveOffset + ~polyCtl[\osc2tune]).clip(0, 127).midicps;
	keyNum = keyNum + octaveOffset; // midi note #

	if (status == 1,
		{ // turn keyNum on
			~keys[keyNum].set(\gate, 0);  //safety - force envelope release if not nil (nil.set will not be sent)
			~keys[keyNum] = Synth.new(\poly, [
				\freq1, noteFreq1,
				\freq2, noteFreq2,
				\gate, 1,
				\osc1sel, ~polyCtl[\osc1sel],
				\osc2sel, ~polyCtl[\osc2sel],
				\oscMix, ~polyCtl[\oscMix],
				\oscNoise, ~polyCtl[\oscNoise],
				\lpfCut, ~polyCtl[\lpfCut],
				\lpfRes, ~polyCtl[\lpfRes],
				\lpfEnv, ~polyCtl[\lpfEnv],
				\lpfMix, ~polyCtl[\lpfMix],
				\lpfAtt, ~polyCtl[\lpfAtt],
				\lpfDec, ~polyCtl[\lpfDec],
				\lpfSus, ~polyCtl[\lpfSus],
				\lpfRel, ~polyCtl[\lpfRel],
				\ampAtt, ~polyCtl[\ampAtt],
				\ampDec, ~polyCtl[\ampDec],
				\ampSus, ~polyCtl[\ampSus],
				\ampRel, ~polyCtl[\ampRel],
			], ~synthGroup);
		},
		{ // turn keyNum off
			s.bind {
				~keys[keyNum].set(\gate, 0);
				~keys[keyNum]= nil;  //safety - clear slot
			};
		}
	);
};

// clear any hanging notes
~clearGroup = {
	arg val;
	fork ({
	if (val == 1,
		{
			128.do({
				arg i;
				~keys[i].set(\gate, 0);
				~keys[i] = nil;
				});
			~envSegMax.wait;
			~synthGroup.freeAll;
		}
	);
	});
};
)
OSCdef.freeAll; s.freeAll;


s.plotTree;
s.meter;
s.dumpOSC(false);
s.dumpOSC(true);
s.quit;

OSCFunc.trace(false);

s.latency;
s.sync;
s.freeAll;
m.sendMsg("/display/knob1", 0.1);
m.sendMsg("/raspberrypi/1/0", 0.9);

a.free; a = { XFade2.ar(DC.ar(0.25), DC.ar(0.5), 1) }.scope;
s.scope;

a.free;
a = {DC.ar(1) }.play;
Env.adsr(0.1, 0.2, 0.5, 1, 0.1, 0, 0.9).test(2).plot(minval: 0, maxval: 1);
