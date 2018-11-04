s.boot;

(
~maxRecLength = 60;
~maxLoops = 10;

// create a bunch of buffers. ~buf[0] is master, the rest for overdubs.
~buf = nil!~maxLoops;
~maxLoops.do({
	arg i;
	~buf[i] = Buffer.alloc(s, s.sampleRate * ~maxRecLength, 2);
});

// create buses
~kbus = (); //control
~kbus.timer = Bus.control(s, 1);
~kbus.loopstart = Bus.control(s, 1);

~abus = (); //audio
~abus.in = Bus.audio(s, 2);
~abus.out = Bus.audio(s, 2);
~abus.rec = Bus.audio(s, 2);
~abus.dir = Bus.audio(s, 2);
~abus.loops = Bus.audio(s, 2);
~abus.mute = Bus.audio(s, 2);
)

(

SynthDef(\input, {
	arg amp=1, recBus, dirBus;
	var in, recSig, dirSig;
	in = SoundIn.ar([0, 1]);
	recSig = in * amp;
	dirSig = in * amp;
	Out.ar(recBus, recSig);
	Out.ar(dirBus, dirSig);
}).add;

SynthDef(\rec, {
	arg t_start, t_stop, recBus, timerBus, recLev = 1, preLev = 0, loop = 0, whichBuf;
	var inSig, isRec, timer;
	isRec = SetResetFF.kr(t_start, t_stop);
	// isRec.poll(label: \isRec);
	inSig = In.ar(recBus, 2);
	timer = Timer.kr(t_start + t_stop);
	timer = timer % ~maxRecLength;
	Out.kr(timerBus, timer);
	// loopStart = Impulse.kr(timer.reciprocal);
	// Out.kr(loopStartBus, loopStart);
	RecordBuf.ar(inSig, whichBuf, 0, recLev, preLev, isRec, loop);
}).add;

SynthDef(\playM, {
	arg timerBus, loopBus, whichBuf, loop = 1;
	var sig, timer, loopStart;
	timer = In.kr(timerBus);
	timer.poll(label: \timer);
	loopStart = Impulse.kr(timer.reciprocal);
	// Out.ar(loopBus, BufRd.ar(2, whichBuf, Sweep.ar(loopStart, s.sampleRate), 1, 2));
	Out.ar(loopBus, PlayBuf.ar(2, whichBuf, 1, loopStart, loop: 1));
}).add;

SynthDef(\overdub, {
	arg t_startDub = 0, t_stopDub = 0, recBus, timerBus, whichBuf, recLev = 1, preLev = 0, loop = 1;
	var inSig, isRec, timer, loopStart;
	isRec = SetResetFF.kr(t_startDub, t_stopDub);
	inSig = In.ar(recBus, 2);
	timer = In.kr(timerBus);
	loopStart = Impulse.kr(timer.reciprocal);
	RecordBuf.ar(inSig, whichBuf, 0, recLev, preLev, isRec, loop, loopStart);
}).add; // working on this here....

SynthDef(\output, {
	arg loopBus, dirBus, loopAmp=1, dirAmp=1, mainAmp=1, out=0;
	var loopSig, dirSig, outSig;
	loopSig = In.ar(loopBus, 2) * loopAmp;
	dirSig = In.ar(dirBus, 2) * dirAmp;
	outSig = (loopSig + dirSig) * mainAmp;
	Out.ar(out, outSig);
}).add;

SynthDef(\psr, {
	arg sweepBus, timerBus;
	var timer, phasor, loopStart;
	timer = In.kr(timerBus);
	loopStart = Impulse.kr(timer.reciprocal);

	phasor = Sweep.ar(loopStart, s.sampleRate);
	phasor.poll;
});
)



a = Synth(\psr, [\sweepBus, ~abus.sweep, \timerBus, ~kbus.timer], ~outGroup);
s.freeAll;

(
// a GUI controller to run the thing:
w = Window.new("VL Looper Controls", Rect(
	Window.screenBounds.width-550,
	Window.screenBounds.height+550,
	400,
	475
))
.front
.alwaysOnTop_(true);

~but0 = Button(w, Rect(25, 25, 350, 50))
.states_([["RESET"]])
.mouseDownAction_({
	| mode |
	"reset environment".postln;
	fork{
	"creating groups".postln;
		~inGroup = Group.new;
		~recGroup = Group.after(~inGroup);
		~playMGroup = Group.after(~recGroup);
		~outGroup = Group.tail;
		0.5.wait;
		"zeroing buffers".postln;
		~maxLoops.do({ |i| ~buf[i].zero });
		0.5.wait;
		"creating in/out/rec synths".postln;
		~in = Synth(\input, [\recBus, ~abus.rec, \dirBus, ~abus.dir], ~inGroup);
		~out = Synth(\output, [\dirBus, ~abus.dir, \loopBus, ~abus.loops], ~outGroup);
		~rec = Synth(\rec, [\recBus, ~abus.rec, \timerBus, ~kbus.timer, \whichBuf, ~buf[0]], ~recGroup); // start rec synth
	};
	~but1.value_(0); ~but2.value_(0); ~but3.value_(0);
});

~but1 = Button(w, Rect(25, 100, 350, 100))
.states_([["REC", Color.white, Color.magenta(0.5)], ["OVERDUB", Color.white, Color.blue(0.5)]])
.mouseDownAction_({
	| mode |
	if (mode.value == 0,
		{
			"record!".postln;
			~rec.set(\t_start, 1); // start recM recording
			("Button 1:" + mode.value).post;
		},
		{
			"overdub!".postln;
			// stop recM recording
			// start play recM
			// start record overdub
			// set ~but2 to "STOP"
		}
	)
});

~but2 = Button(w, Rect(25, 225, 350, 100))
.states_([["PLAY", Color.white, Color.green(0.5)], ["STOP", Color.white, Color.red(0.5)]])
.mouseDownAction_({
	| mode |
	if (mode.value == 0,
		{
			"play!".postln;
			if (~but1.value == 1,
				{
					"stopping record master".postln;
					~rec.set(\t_stop, 1); // stop recM
			// ~but1.value_(1); // change button 1
			});
			~in.set(\dirBus, ~abus.mute);
			~play = Synth(\playM, [\timerBus, ~kbus.timer, \loopBus, ~abus.loops, \whichBuf, ~buf[0]], ~playMGroup);	// start master playback

		},
		{
			"stop!".postln;
			~play.free;
		}
	)
});

~but3 = Button(w, Rect(25, 350, 350, 100))
.states_([["state 0", Color.white, Color.yellow(0.5)], ["state 1", Color.white, Color.cyan(0.5)]])
.mouseDownAction_({
	| mode |
	mode.value.postln;
	if (mode.value == 0,
		{
			"clear last!".postln
		},
		{
			"clear all!".postln;
		}
	)
});
)

~but3.value_(0);
~but3.value;

~but3 = Button(w, Rect(25, 350, 350, 100))
.states_([["CLEAR LAST", Color.white, Color.yellow(0.5)], ["CLEAR ALL", Color.white, Color.cyan(0.5)]])
.mouseDownAction_({
	| mode |
	if (mode.value == 0,
		{
			"clear last!".postln
		},
		{
			"clear all!".postln;
		}
	)
});


~but2.valueAction_(0);


~ctlBus1 = Bus.control(s, 1);
~ctlBus2 = Bus.control(s, 1);
SynthDef(\ctl, {
	arg ctl1, ctl2;
	Out.kr(~ctlBus1, ctl1);
	Out.kr(~ctlBus2, ctl2);
}).add;

(
SynthDef(\monitor, {
	arg whichBus;
	var monitor;
	monitor = In.kr(whichBus);
	monitor.poll(label: \monitor);
}).add;
)

a = Synth(\ctl, [\ctl1, 0.222, \ctl2, 1.11111]);
b = Synth(\monitor, [\whichBus, ~kbus.timer], ~outGroup);
a.set(\ctl1, 0, \ctl2, 0);
{ In.ar(~ctlBus2).poll }.play;
a.free; b.free;

~but1.value;
~buf[0].plot;
~buf[0].play;
~in.set(\dirBus, ~abus.mute);

s.reboot;
s.freeAll;

if (~but1.value == 1, {111.postln}, {0.postln});
~but1.value;