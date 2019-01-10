(
fork{
	"".postln;
	"===========================".postln;
	"NOISEBOX V3i for iPad. John Sullivan, 2018.".postln;
	0.2.wait;
	"".postln;
	"make sure iPad is connected and IP addresses are correctly configured".postln;
	0.2.wait;
	"".postln;

	~ip = "192.168.1.9"; // iPad IP address (home)
	//  ~ip = "192.168.1.148"; // iPad IP address (IDMIL - bodysuit1)
	~port = 5001;
	~root = "/raspberrypi";

	// *********************************
	// GLOBAL vars:
	// *********************************
	~glob = Dictionary.new(5); // Dict to hold global control vars (see assignments in controls.scd)
	~octave = 2; //default octave for the synthesizer; range is -2 to 8.`
	~numKeys = 24; // number of keys on the keyboard
	~tuneMax = 24; // Oscillator tune up range (semitones)
	~tuneMin = 24; // Oscillator tune down range (semitones)
	~envSegMax = 10; // Max length of envelope segments (seconds)

	~keys = Array.newClear(128);

	~grp = (); // Dict for groups
	~abus = (); // Dict for audio buses
	~kbus = (); // Dict for control buses

	// GROUPS
	~grp.in = Group.head; // external audio input for looper and FX
	~grp.psynth = Group.after(~grp.in); // put all Synths in a group, so abandoned voices can be eventually freed
	~grp.looper = Group.after(~grp.psynth); // looper group
	~grp.fx = Group.after(~grp.looper); // FX group
	~grp.master = Group.after(~grp.fx); // group for master channel (with a limiter)

	// Buses (GLOBAL - additional buses are used for looper and FX modules)
	~abus.ext = Bus.audio(s, 2); // signal from external audio
	~abus.psynth = Bus.audio(s, 2); // signal from psynth
	~abus.looper = Bus.audio(s, 2); // signal from looper
	~abus.master = Bus.audio(s, 2); // signal to ~grp.master... for now


		// ***** load additional files *****
	"Setting up controls ".post;
	"controls.scd".loadRelative; // contains OSCdefs and input functions.
	5.do({ 0.1.wait; ". ".post;}); 0.2.wait; "".postln;
	~updateDisplayTitle.value(~glob[\pageName][~glob[\page]]);
	s.sync;
	"Loading polySynth engine ".post;
	"polySynth.scd".loadRelative; // contains the SynthDefs
	5.do({ 0.1.wait; ". ".post;}); 0.2.wait; "".postln;
	"Loading vl_looper ".post;
	"looper.scd".loadRelative;
	5.do({ 0.1.wait; ". ".post;}); 0.2.wait; "".postln;
	"Starting global synths ".post;
	5.do({ 0.1.wait; ". ".post;}); 0.2.wait; "".postln;



	SynthDef(\extIn, { // get external input
		arg out;
		var inSig = SoundIn.ar([0, 1]);
		Out.ar(out, inSig);
	}).add;

	SynthDef(\fx, { // empty for now.. will move to separate file
		arg in, out;
		var inSig = In.ar(in, 2);
		// put fx here...
		// ...
		// ...
		// ...
		Out.ar(out, inSig);
	}).add;

	SynthDef(\master, {
		arg in, out = 0, masterVol = ~glob[\volume];
		var inSig = In.ar(in, 2) * masterVol;
		// inSig = Limiter.ar(sig, 1, 0.01);
		Out.ar(out, inSig);
	}).add;

	s.sync; // wait for SynthDefs to load before proceeding


	~extIn = Synth(\extIn, [\out, ~abus.ext], ~grp.in);
	~fx = Synth(\fx, [\in, ~abus.looper, \out, ~abus.master], ~grp.fx);
	~master = Synth.new(\master, [\in, ~abus.master, \out, 0, \masterVol, ~glob[\volume]], ~grp.master);

	0.5.wait;
	"".postln;
	"DONE! Enjoy playing...".postln;
	"===========================".postln;
	"".postln;


	//
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
					\out, ~abus.psynth
				], ~grp.psynth);
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
					~grp.psynth.freeAll;
				}
			);
		});
	};
}; //end fork
)
// OSCdef.freeAll; s.freeAll; s.reboot;
