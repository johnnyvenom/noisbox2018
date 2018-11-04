s.reboot;

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
~abus.sweep = Bus.audio(s, 1);
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
	arg t_start, t_stop, recBus, timerBus, gate = 1, recLev = 1, preLev = 0, loop = 0, whichBuf;
	var inSig, isRec, timer;
	isRec = SetResetFF.kr(t_start, t_stop);
	isRec.poll(label: \isRec);
	inSig = In.ar(recBus, 2);
	timer = Timer.kr(t_start + t_stop);
	timer = timer % ~maxRecLength;
	timer = Gate.kr(timer, gate); // close gate when done recording master to set length of loops
	timer.poll(label: \timer);
	Out.kr(timerBus, timer);
	RecordBuf.ar(inSig, whichBuf, 0, recLev, preLev, isRec, loop);
}).add;

SynthDef(\sweep, { //
	arg sweepBus, timerBus;
	var timer, phasor, loopStart;
	timer = In.kr(timerBus);
	// timer.poll(label: \timer);
	loopStart = Impulse.kr(timer.reciprocal);
	phasor = Sweep.ar(loopStart, s.sampleRate);
	// phasor.poll;
	Out.ar(sweepBus, phasor);
}).add;

SynthDef(\playM, {
	arg timerBus, loopBus, sweepBus, whichBuf, loop = 1;
	var sig, timer, loopStart, phasor;
	phasor = In.ar(sweepBus);
	Out.ar(loopBus, BufRd.ar(2, whichBuf, phasor, loop, 2));
}).add;

SynthDef(\overdub, {
	arg recBus, sweepBus, whichBuf, loop = 1;
	var inSig, timer, phasor, loopStart;
	inSig = In.ar(recBus, 2);
	phasor = In.ar(sweepBus);
	BufWr.ar(inSig, whichBuf, phasor, loop);
}).add;

SynthDef(\output, {
	arg loopBus, dirBus, loopAmp=1, dirAmp=1, mainAmp=1, out=0;
	var loopSig, dirSig, outSig;
	loopSig = In.ar(loopBus, 2) * loopAmp;
	dirSig = In.ar(dirBus, 2) * dirAmp;
	outSig = (loopSig + dirSig) * mainAmp;
	Out.ar(out, outSig);
}).add;

)
/***** END SYNTHDEFS ******/


a = { In.ar(~kbus.timer).poll }.play;
~rec.set(\gate, 1);

(
// a GUI controller to run the thing:
Window.closeAll;
w = Window.new("VL Looper Controls", Rect(
	Window.screenBounds.width-550,
	Window.screenBounds.height+550,
	400,
	475
))
.front
.alwaysOnTop_(true);


~but0 = Button(w, Rect(25, 25, 150, 50))
.states_([["SETUP"]])
.mouseDownAction_({
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
});

~but1 = Button(w, Rect(25, 100, 150, 50))
.states_([["START_REC", Color.white, Color.magenta(0.6)]])
.mouseDownAction_({
	"recording master loop".postln;
	// ~rec.set(\gate, 1);
	~rec.set(\t_start, 1); // start recM recording
});

~but2 = Button(w, Rect(200, 100, 150, 50))
.states_([["STOP_REC", Color.white, Color.magenta(0.2, 0.6)]])
.mouseDownAction_({
	"stop recording master loop".postln;
	~rec.set(\t_stop, 1);
	~rec.set(\gate, 0); // freeze timer
});

~but3 = Button(w, Rect(25, 175, 150, 50))
.states_([["START_PLAY", Color.white, Color.green(0.6)]])
.mouseDownAction_({
	"start playing master loop".postln;
	~sweep = Synth.new(\sweep, [\sweepBus, ~abus.sweep, \timerBus, ~kbus.timer]);
	~play = Synth(\playM, [\timerBus, ~kbus.timer, \loopBus, ~abus.loops, \sweepBus, ~abus.sweep, \whichBuf, ~buf[0]], ~playMGroup);	// start master playback
});

~but4 = Button(w, Rect(200, 175, 150, 50))
.states_([["STOP_PLAY", Color.white, Color.red(0.8)]])
.mouseDownAction_({
	"stop playing master loop".postln;
	~play.free;
	~sweep.free;
});

~but5 = Button(w, Rect(25, 250, 150, 50))
.states_([["RECORD_OVERDUB", Color.white, Color.blue(0.8)]])
.mouseDownAction_({
	"record an overdub".postln;
	if (
		~sweep.isPlaying == false,
		{ ~sweep = Synth.new(\sweep, [\sweepBus, ~abus.sweep, \timerBus, ~kbus.timer]).register; }
	);
	~overdub = Synth(\overdub, [\recBus, ~abus.rec, \sweepBus, ~abus.sweep, \whichBuf, ~buf[~numDubs+1]], ~recGroup);
});

~but6 = Button(w, Rect(200, 250, 150, 50))
.states_([["STOP_OVERDUB", Color.white, Color.cyan(0.5)]])
.mouseDownAction_({
	"stop playing master loop".postln;
	~play.free;
});
)

