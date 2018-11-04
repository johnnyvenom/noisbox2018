(
fork{
	// ~ip = "192.168.1.8"; // iPad IP address (home)
	~ip = "192.168.1.148"; // iPad IP address (IDMIL - bodysuit1)
	~port = 5001;
	~root = "/raspberrypi";

	// *********************************
	// GLOBAL vars:
	// *********************************

	~glob = Dictionary.new(5); // Dict to hold global control vars (see assignments in controls.scd)
	~octave = 2; //default octave for the synthesizer; range is -2 to 8.
	~numKeys = 24; // number of keys on the keyboard
	~tuneMax = 24; // Oscillator tune up range (semitones)
	~tuneMin = 24; // Oscillator tune down range (semitones)
	~envSegMax = 10; // Max length of envelope segments (seconds)

	~synthGroup = Group.new; // put all Synths in a group, so abandoned voices can be eventually freed
	~modGroup = Group.after(~synthGroup); // eventually will have a group for audio capture and manipulate
	~masterGroup = Group.after(~modGroup); // group for master channel (with a limiter)
	~keys = Array.newClear(128);

	// ***** load additional files *****
	"controls.scd".loadRelative; // contains OSCdefs and input functions.
	"Setting up controls.".postln;
	"polySynth.scd".loadRelative; // contains the SynthDefs
	"Loading polySynth engine.".postln;

	s.sync; // wait for SynthDefs to load before proceeding

	// Create master Synth
	~master = Synth.new(\master, [\masterVol, ~glob[\volume]], ~masterGroup);

	~noteAction = { // when any key is pressed or released, this happens
		arg status, keyNum, statusArray; // an array of values. 0 = note is off, 1 = note is on.
		var octaveOffset = (~glob[\octave]*12)+24;
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
					\out, ~sendToMaster
				], ~synthGroup);
				// ] );
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
}; //end fork
)
// OSCdef.freeAll; s.freeAll; s.reboot;
