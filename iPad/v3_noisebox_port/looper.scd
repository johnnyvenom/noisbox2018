// variable length looper for Noisebox

// init params for display
fork({
	var params = [
		// stuff
		[\loopRate, "Rate", \knob, 1, 1.linlin(-4,6,0,1)],
		[\loopSrcMix, "Source", \knob, 0.5, 0.5],
		[\loopRecDub, "Rec/Dub", \button, 0, " "],
		[\loopPlayStop, "Ply/Stp", \button, 0, " "],
		[\loopClearBuf, "Clear", \button, 0, " "],
		[\loopMuteExt, "MuteExt", \button, 0, " "]
	];

	~d.looper = ();

	params.size.do({
		| i |
		~d[\looper][params[i][0]] = ();
		~d[\looper][params[i][0]].put(\label, params[i][1]); // set label
		~d[\looper][params[i][0]].put(\type, params[i][2]); // set type
		~d[\looper][params[i][0]].put(\outVal, params[i][3]); // set initial output value
		~d[\looper][params[i][0]].put(\normVal, params[i][4]); // set initial normalized value
	});
});

// initialization (run once when patch is first started)
~loop = ();
~loop.state = 0;
~loop.extIn = 1;
~loop.rateMinMax = [-4, 6]; // loop rate max/min control
~loop.maxLength = 60; // seconds
~loop.buf = Buffer.alloc(s, ~loop.maxLength * s.sampleRate, 2); // hold our loop

~kbus.loop_timer = Bus.control(s, 1);

~abus.loop_dir = Bus.audio(s, 2);
~abus.loop_rec = Bus.audio(s, 2);
~abus.loop_phasor = Bus.audio(s, 1);
~abus.loop_fb = Bus.audio(s, 2);
~abus.loop_out = Bus.audio(s, 2);

//groups to keep synths in correct order
~grp.loop_in = Group.head(~grp.looper);
~grp.loop_phasor = Group.after(~grp.loop_in);
~grp.loop_playBus = Group.after(~grp.loop_phasor);
~grp.loop_recBus = Group.after(~grp.loop_playBus);
~grp.loop_out = Group.after(~grp.loop_recBus);

SynthDef(\in, {
	arg extIn, synthIn, dirBus, recBus, srcMix = 0.5;
	var sig, extSig, synthSig, dirSig, recSig;
	extSig = In.ar(extIn);
	synthSig = In.ar(synthIn, 2);
	sig = LinSelectX.ar(srcMix, [extSig, synthSig]);
	dirSig = sig; // input signal to feed direct to output
	recSig = sig; // input signal to go to looper
	Out.ar(dirBus, dirSig);
	Out.ar(recBus, recSig);
}).add;

SynthDef(\phasor, {
	arg phasorBus, t_trig, timerGate, rate = 1, start = 0, max = ~loop.maxLength, which = 0;
	var timer, phasor, timerPoll;
	timer = Timer.kr(Gate.kr(t_trig, timerGate));
	timer = timer % ~loop.maxLength;
	// (timer * s.sampleRate).poll(label: \timer);
	phasor = Phasor.ar(t_trig, rate, start, Select.kr(which, [max, timer]) * s.sampleRate);
	// phasor.poll(label: \phasor);
	Out.ar(phasorBus, phasor);
}).add;

SynthDef(\rec, {
	arg phasorBus, recBus, fbBus, whichBuf;
	var phasor, recSig, fbSig, writeSig;
	phasor = In.ar(phasorBus);
	recSig = In.ar(recBus, 2);
	fbSig = In.ar(fbBus, 2);
	writeSig = [recSig, fbSig].sum;
	BufWr.ar(writeSig, whichBuf, phasor);
}).add;

SynthDef(\play, {
	arg whichBuf, phasorBus, fbBus, outBus;
	var sig, phasor;
	phasor = In.ar(phasorBus);
	sig = BufRd.ar(2, whichBuf, phasor, 1, 4);
	Out.ar(fbBus, sig);
	Out.ar(outBus, sig);
}).add;

SynthDef(\out, {
	arg out, outBus, dirBus, dirGate = 1, amp = 1;
	var inSig, dirSig;
	inSig = In.ar(outBus, 2); // from playback
	dirSig = Gate.ar(In.ar(dirBus, 2), dirGate); // from direct
	Out.ar(out, [inSig, dirSig].sum * amp);
}).add;

s.sync;

~in = Synth(\in, [\extIn, ~abus.ext, \synthIn, ~abus.psynth, \dirBus, ~abus.loop_dir, \recBus, ~abus.loop_rec], ~grp.loop_in);
~out = Synth(\out, [\out, ~abus.looper, \outBus, ~abus.loop_out, \dirBus, ~abus.loop_dir, \dirGate, 1], ~grp.loop_out);

s.sync;


/********************************************
  Looper Controls
 ********************************************/

/*
Looper states:
0 -> cleared and ready to record
1 -> recording first loop
2 -> overdubbing
3 -> playing back
4 -> stopped with buffer recorded
*/

~loopRecDub = { // RECORD/OVERDUB button
	// arg state;
	switch (~loop.state,
		0, {
			"record!".postln;
			s.bind{
				~record = Synth(\rec, [
					\phasorBus, ~abus.loop_phasor,
					\recBus, ~abus.loop_rec,
					\fbBus, ~abus.loop_fb,
					\whichBuf, ~loop.buf],
				~grp.loop_recBus).register; // start record synth (but don't run)
				~phasor = Synth(\phasor, [
					\phasorBus, ~abus.loop_phasor,
					\t_trig, 0,
					\timerGate, 0,
					\max, ~loop.maxLength,
					\which, 0
					// \rate, ~d.looper.loopRate.outVal
				],
				~grp.loop_phasor).register; // start phasor synth
				s.sync;
				~phasor.set(\timerGate, 1, \t_trig, 1); // begin recording
			};
			~loop.state = 1;
		},
		1, { // rec/dub pressed while recording first loop
			// start playback and continue recording!
			"overdub!".postln;
			~play = Synth(\play, [
				\phasorBus, ~abus.loop_phasor,
				\fbBus, ~abus.loop_fb,
				\outBus, ~abus.loop_out,
				\whichBuf, ~loop.buf],
			~grp.loop_playBus).register;
			s.bind{
				~phasor.set(\t_trig, 1); // end rec trigger
				s.sync;
				~phasor.set(\timerGate, 0); // close timer gate so no new timer updates
				~phasor.set(\which, 1); // loop to timer, not max length
			};
			~loop.state = 2;
		},
		2, { // rec/dub pressed when overdubbing
			// stop dubbing and continue playback.
			"overdub off!".postln;
			~record.free;
			~loop.state = 3;
		},
		3, { // rec/dub pressed during playback
			// start overdubbing
			"overdub on!".postln;
			~record = Synth(\rec, [
				\phasorBus, ~abus.loop_phasor,
				\recBus, ~abus.loop_rec,
				\fbBus, ~abus.loop_fb,
				\whichBuf, ~loop.buf],
			~grp.loop_recBus).register;

			~loop.state = 2;
		},
		4, { // rec/dub pressed when stopped w/ buffer recorded
			// playback and start overdubbing
			"overdub back on!".postln;
			s.bind{
				~play = Synth(\play, [
					\phasorBus, ~abus.loop_phasor,
					\fbBus, ~abus.loop_fb,
					\outBus, ~abus.loop_out,
					\whichBuf, ~loop.buf],
				~grp.loop_playBus).register;

				~record = Synth(\rec, [
					\phasorBus, ~abus.loop_phasor,
					\recBus, ~abus.loop_rec,
					\fbBus, ~abus.loop_fb,
					\whichBuf, ~loop.buf],
				~grp.loop_recBus).register;

				~phasor.set(\t_trig, 1);
			};
			~loop.state = 2;
		}
	); // end switch
};

~loopPlayStop = { // PLAY/STOP button
	switch (~loop.state,
		0, { // play/stop pressed but nothing has been recorded yet
			// do nothing...
			"nothing to play!".postln;
		},
		1, { // play/stop pressed during rec first loop.
			// start looping that first loop!
			"playback!".postln;
			~play = Synth(\play, [
				\phasorBus, ~abus.loop_phasor,
				\fbBus, ~abus.loop_fb,
				\outBus, ~abus.loop_out,
				\whichBuf, ~loop.buf],
			~grp.loop_playBus).register;
			s.bind{
				~phasor.set(\t_trig, 1); // end rec trigger
				s.sync;
				~phasor.set(\timerGate, 0); // close timer gate so no new timer updates
				~phasor.set(\which, 1); // loop to timer, not max length
				~record.free;
			};
			~loop.state = 3;
		},
		2, { // play/stop pressed when overdubbing
			// stop playing
			"stop!".postln;
			~play.free;
			~record.free;
			~loop.state = 4;
		},
		3, { // play/stop pressed while playing back
			// stop playing
			"stop!".postln;
			~play.free;
			~loop.state = 4;
		},
		4, { // play/stop pressed while nothing playing
			"playback!".postln;
			s.bind{
				~play = Synth(\play, [
					\phasorBus, ~abus.loop_phasor,
					\fbBus, ~abus.loop_fb,
					\outBus, ~abus.loop_out,
					\whichBuf, ~loop.buf],
				~grp.loop_playBus).register;
				~phasor.set(\t_trig, 1);
			};
			~loop.state = 3;
		}
	); // end switch
};

~loopClearBuf = { // CLEAR LOOPS button
	"clearing loops!".postln;
	if (~play.isPlaying, {~play.free});
	if (~record.isPlaying, {~record.free});
	if (~phasor.isPlaying, {~phasor.free});
	// ~knob1.value_(1); ***NOTE: need to reset RATE knob
	~loop.buf.zero;
	~loop.state = 0;
};

~loopMuteExt = { // MUTE EXTERNAL button
	if (~loop.extIn == 1,
		{
			"muting input!".postln;
			~out.set(\dirGate, 0);
		},
		{
			"unmuting external input!".postln;
			~out.set(\dirGate, 1);
		}
	);
	~loop.extIn = (~loop.extIn - 1).abs;
};

~loopRate = { // playback speed control
	arg val;
	var inst = \looper, ctl = \loopRate, normVal = val;
	var outVal = val.linlin(0, 1, ~loop.rateMinMax[0],  ~loop.rateMinMax[1]);
	if (~phasor.isPlaying, {
		outVal.postln;
		~phasor.set(\rate, outVal);
		~storeCtlVals.value(inst, ctl, outVal, normVal);
	});
};

~loopSrcMix = { // input source mix (0 = external; 1: synth)
	arg val;
	var inst = \looper, ctl = \loopSrcMix, normVal = val;
	var outVal = normVal;
	~in.set(\srcMix, outVal);
	~storeCtlVals.value(inst, ctl, outVal, normVal);
};
