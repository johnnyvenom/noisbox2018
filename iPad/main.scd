(
"controls.scd".loadRelative; // contains OSCdefs and input functions.
"polySynth.scd".loadRelative; // contains the SynthDefs

// *********************************
// GLOBAL variables:
// *********************************

~page = 0; //page up/down through sets of controls.
// maybe eventually will have "modes" and "pages"
~octave = 2; //default octave for the synthesizer; range is -2 to 8.
~numKeys = 24;

~synthGroup = Group.new; // put all Synths in a group, so abandoned voices can be eventually freed
~keys = Array.newClear(128);

~noteAction = { // when any key is pressed or released, this happens
	arg status, keyNum, statusArray; // an array of values. 0 = note is off, 1 = note is on.
	var octaveOffset = (~octave*12)+24;
	var isSilent = true;
	keyNum = keyNum + octaveOffset;

	if (status == 1,
		{ // turn keyNum on
			~keys[keyNum].set(\gate, 0);  //safety - force envelope release if not nil (nil.set will not be sent)
			// ~keys[keyNum] = Synth.new(\square, [\freq, keyNum.midicps, \gate, 1], ~synthGroup);
			~keys[keyNum] = Synth.new(\poly, [\freq, keyNum.midicps, \gate, 1], ~synthGroup);
		},
		{ // turn keyNum off
			s.bind {
				~keys[keyNum].set(\gate, 0);
				~keys[keyNum]= nil;  //safety - clear slot
			};
		}
	);
};

// clear orphaned Nodes off the group
~clearGroup = {
	arg val;
	if (val == 1,
		{
		~synthGroup.freeAll;
		"clearing stuck Nodes".postln;
		}
	);
};
)

OSCdef.freeAll; s.freeAll;
s.plotTree;
s.dumpOSC(false);
s.dumpOSC(true);
s.quit;

OSCFunc.trace(false);

s.latency;
s.sync;
s.freeAll;