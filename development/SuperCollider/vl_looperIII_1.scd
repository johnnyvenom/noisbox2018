// variable length looper for Noisebox

// initialization (run once when patch is first started)
(
~maxLoopLength = 60; // seconds
~loop = Buffer.alloc(s, ~maxLoopLength*s.sampleRate, 2); // hold our loop

~kbus = (); // collection for all our control buses
~kbus.timer = Bus.control(s, 1);

~abus = (); // collection for all our audio buses
~abus.dir = Bus.audio(s, 2);
~abus.rec = Bus.audio(s, 2);
~abus.phasor = Bus.audio(s, 1);
~abus.fb = Bus.audio(s, 2);
~abus.out = Bus.audio(s, 2);

SynthDef(\in, {
	arg dirBus, recBus;
	var inSig, dirSig, recSig;
	inSig = SoundIn.ar([0, 1]);
	dirSig = inSig; // input signal to feed direct to output
	recSig = inSig; // input signal to go to looper
	Out.ar(dirBus, dirSig);
	Out.ar(recBus, recSig);
}).add;

SynthDef(\phasor, {
	arg phasorBus, t_trig, timerGate, rate = 1, start = 0, max = ~maxLoopLength, which = 0;
	var timer, phasor, timerPoll;
	timer = Timer.kr(Gate.kr(t_trig, timerGate));
	timer = timer % ~maxLoopLength;
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
	sig = BufRd.ar(2, whichBuf, phasor);
	Out.ar(fbBus, sig);
	Out.ar(outBus, sig);
}).add;

SynthDef(\out, {
	arg outBus, dirBus, dirGate = 1, amp = 1;
	var inSig, dirSig;
	inSig = In.ar(outBus, 2); // from playback
	dirSig = Gate.ar(In.ar(dirBus, 2), dirGate); // from direct
	Out.ar(0, [inSig, dirSig].sum * 0.5 * amp);
}).add;
)

(
~loop.zero;

g = (); //groups to keep synths in correct order
g.in = Group.head;
g.phasor = Group.after(g.in);
g.playBus = Group.after(g.phasor);
g.recBus = Group.after(g.playBus);
g.out = Group.after(g.recBus);

~in = Synth(\in, [\dirBus, ~abus.dir, \recBus, ~abus.rec], g.in);
~out = Synth(\out, [\outBus, ~abus.out, \dirBus, ~abus.dir, \dirGate, 1], g.out);
)

/********************************************
  GUI controls
 ********************************************/
(
/*
Looper states:
0 -> cleared and ready to record
1 -> recording first loop
2 -> overdubbing
3 -> playing back
4 -> stopped with buffer recorded
*/

// a GUI controller to run the thing:
Window.closeAll;
w = Window.new("VL Looper Controls", Rect(
	Window.screenBounds.width-550,
	Window.screenBounds.height+550,
	400,
	400
))
.front
.alwaysOnTop_(true);

~but0 = Button(w, Rect(25, 25, 350, 100))
.states_([["RECORD/OVERDUB", Color.white, Color.blue(0.5)]])
.mouseDownAction_({ | mode |
	("~loopState:" + ~loopState).postln;
	switch (~loopState,
		0, {
			"record!".postln;
			s.bind{
				~record = Synth(\rec, [
					\phasorBus, ~abus.phasor,
					\recBus, ~abus.rec,
					\fbBus, ~abus.fb,
					\whichBuf, ~loop],
				g.recBus).register; // start record synth (but don't run)
				~phasor = Synth(\phasor, [
					\phasorBus, ~abus.phasor,
					\t_trig, 0,
					\timerGate, 0,
					\max, ~maxLoopLength,
					\which, 0],
				g.phasor).register; // start phasor synth
				s.sync;
				~phasor.set(\timerGate, 1, \t_trig, 1); // begin recording
			};
			~loopState = 1;
		},
		1, { // rec/dub pressed while recording first loop
			// start playback and continue recording!
			"overdub!".postln;
			~play = Synth(\play, [
				\phasorBus, ~abus.phasor,
				\fbBus, ~abus.fb,
				\outBus, ~abus.out,
				\whichBuf, ~loop],
			g.playBus).register;
			s.bind{
				~phasor.set(\t_trig, 1); // end rec trigger
				s.sync;
				~phasor.set(\timerGate, 0); // close timer gate so no new timer updates
				~phasor.set(\which, 1); // loop to timer, not max length
			};
			~loopState = 2;
		},
		2, { // rec/dub pressed when overdubbing
			// stop dubbing and continue playback.
			"overdub off!".postln;
			~record.free;
			~loopState = 3;
		},
		3, { // rec/dub pressed during playback
			// start overdubbing
			"overdub on!".postln;
			~record = Synth(\rec, [
				\phasorBus, ~abus.phasor,
				\recBus, ~abus.rec,
				\fbBus, ~abus.fb,
				\whichBuf, ~loop],
			g.recBus).register;
			~loopState = 2;
		},
		4, { // rec/dub pressed when stopped w/ buffer recorded
			// playback and start overdubbing
			s.bind{
				~play = Synth(\play, [
					\phasorBus, ~abus.phasor,
					\fbBus, ~abus.fb,
					\outBus, ~abus.out,
					\whichBuf, ~loop],
				g.playBus).register;
				~record = Synth(\rec, [
					\phasorBus, ~abus.phasor,
					\recBus, ~abus.rec,
					\fbBus, ~abus.fb,
					\whichBuf, ~loop],
				g.recBus).register;
				~phasor.set(\t_trig, 1);
			};
			~loopState = 2;
		}
	); // end switch
});

~but1 = Button(w, Rect(25, 150, 350, 100))
.states_([["PLAY/STOP", Color.white, Color.green(0.5)]])
.mouseDownAction_({ | mode |
	("~loopState:" + ~loopState).postln;
	switch (~loopState,
		0, { // play/stop pressed but nothing has been recorded yet
			// do nothing...
		},
		1, { // play/stop pressed during rec first loop.
			// start looping that first loop!
			"playback!".postln;
			~play = Synth(\play, [
				\phasorBus, ~abus.phasor,
				\fbBus, ~abus.fb,
				\outBus, ~abus.out,
				\whichBuf, ~loop],
			g.playBus).register;
			s.bind{
				~phasor.set(\t_trig, 1); // end rec trigger
				s.sync;
				~phasor.set(\timerGate, 0); // close timer gate so no new timer updates
				~phasor.set(\which, 1); // loop to timer, not max length
				~record.free;
			};
			~loopState = 3;
		},
		2, { // play/stop pressed when overdubbing
			// stop playing
			"stop!".postln;
			~play.free;
			~record.free;
			~loopState = 4;
		},
		3, { // play/stop pressed while playing back
			// stop playing
			"stop!".postln;
			~play.free;
			~loopState = 4;
		},
		4, { // play/stop pressed while nothing playing
			"playback!".postln;
			s.bind{
				~play = Synth(\play, [
					\phasorBus, ~abus.phasor,
					\fbBus, ~abus.fb,
					\outBus, ~abus.out,
					\whichBuf, ~loop],
				g.playBus).register;
				~phasor.set(\t_trig, 1);
			};
			~loopState = 3;
		}
	); // end switch
});

~but2 = Button(w, Rect(275, 275, 100, 100))
.states_([["CLEAR LOOPS", Color.white, Color.red(0.5)]])
.mouseDownAction_({ | mode |
	("~loopState:" + ~loopState).postln;
	"clearing loops!".postln;
	if (~play.isPlaying, {~play.free});
	if (~record.isPlaying, {~record.free});
	if (~phasor.isPlaying, {~phasor.free});
	~knob1.value_(1);
	~loop.zero;
	~loopState = 0;
});

~but3 = Button(w, Rect(150, 275, 100, 100))
.states_([["INPUT MUTE"], ["INPUT UNMUTE"]])
.mouseDownAction_({ | mode |
	("~loopState:" + ~loopState).postln;
	switch (mode.value,
		0, {
			"muting input!".postln;
			~out.set(\dirGate, 0);
		},
		1, {
			"unmouting input".postln;
			~out.set(\dirGate, 1);
		}
	);
});

r = ControlSpec(-4, 6, \lin, 0.01, 0);
~knob1 = EZKnob(
	w,
	Rect(25, 275, 100, 100),
	" rate ",
	r,
	{
		arg knob;
		("Rate:" + knob.value).postln;
		if (~phasor.isPlaying, {
			~phasor.set(\rate, knob.value);
		});
	},
	1,
	true
);

)

~knob1.value_(0);
a = Bus.control(s, 1);
b = { In.kr(a).poll }.play;
a.set(0);
~play.set(\phasorBus, ~abus.phasor);
~phasor.set(\rate, 1);
a.free;
b.free;


