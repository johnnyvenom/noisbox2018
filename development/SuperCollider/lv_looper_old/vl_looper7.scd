s.boot;
s.reboot;

(
~maxRecLength = 60;
~maxLoops = 10;

~buf = nil!~maxLoops;

// create a bunch of buffers. ~buf[0] is master, the rest for overdubs.
~maxLoops.do({
	arg i;
	~buf[i] = Buffer.alloc(s, s.sampleRate * ~maxRecLength, 2);
});
)

//control buses
// timerBus = 20;
// loopStartBus = 30;

//audio buses
// inBus = 40;
// outBus = 50;
// recBus = 60;
// dirBus = 70;
// loopBus = 80;

(
SynthDef(\input, {
	var amp=1, recBus=60, dirBus=70;
	var in, recSig, dirSig;
	in = SoundIn.ar([0, 1]);
	recSig = in * amp;
	dirSig = in * amp;
	Out.ar(recBus, recSig);
	Out.ar(dirBus, dirSig);
}).add;

SynthDef(\rec, {
	arg t_start, t_stop, inBus = 60, timerBus = 20, loopStartBus = 30, recLev = 1, preLev = 0, loop = 0, whichBuf;
	var inSig, isRec, timer, loopStart;
	isRec = SetResetFF.kr(t_start, t_stop);
	inSig = In.ar(inBus, 2);
	timer = Timer.kr(t_start + t_stop);
	timer = timer % ~maxRecLength;
	Out.kr(timerBus, timer);
	loopStart = Impulse.kr(timer.reciprocal);
	Out.kr(loopStartBus, loopStart);
	RecordBuf.ar(inSig, whichBuf, 0, recLev, preLev, isRec, loop);
}).add;

SynthDef(\play, {
	arg timerBus = 20, loopStartBus = 30, loopBus = 80, whichBuf, loop = 1;
	var sig, timer, loopStart;
	timer = In.kr(timerBus);
	timer.poll;
	loopStart = Impulse.kr(timer.reciprocal);
	loopStart.poll;
	// Out.ar(loopBus, BufRd.ar(2, whichBuf, Sweep.ar(loopStart, s.sampleRate), 1, 2));
	Out.ar(loopBus, PlayBuf.ar(2, whichBuf, 1, loopStart, loop: 1));
}).add;

SynthDef(\overdub, {
	arg t_startDub = 0, t_stopDub = 0, inBus = 60, timerBus = 20, whichBuf, recLev = 1, preLev = 1, loop = 1;
	var inSig, isRec, timer, loopStart, phasor;
	isRec = SetResetFF.kr(t_startDub, t_stopDub);
	inSig = In.ar(inBus, 2);
	timer = In.kr(timerBus);
	loopStart = Impulse.kr(timer.reciprocal);
	RecordBuf.ar(inSig, whichBuf, 0, recLev, preLev, isRec, loop, loopStart);
}).add;

SynthDef(\output, {
	arg loopBus = 80, dirBus = 70, loopAmp=1, dirAmp=1, mainAmp=1, out=0;
	var loopSig, dirSig, outSig;

	loopSig = In.ar(loopBus, 2) * loopAmp;
	dirSig = In.ar(dirBus, 2) * dirAmp;
	outSig = (loopSig + dirSig) * mainAmp;
	Out.ar(out, outSig);
}).add;
)

(
// a bunch of functions for using the thing
~loop = ();
~loop.setup = {
	fork{
		// s.freeAll;
		0.5.wait;
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
		~in = Synth(\input, [], ~inGroup);
		~out = Synth(\output, [\dirBus, 70], ~outGroup);
		~rec = Synth(\rec, [\whichBuf, ~buf[0]], ~recGroup); // start rec synth
	};
};

~loop.recStart = {
	~rec.set(\t_start, 1); // start recording
};

~loop.recStop = {
	s.bind{
		~rec.set(\t_stop, 1); // stop recording
		~play = Synth(\play, [\whichBuf, ~buf[0], \loop, 1], ~playMGroup); // start playback
		s.sync;
		~dub = Synth(\overdub, [\whichBuf, ~buf[0]], ~recGroup); //start and sync overdub synth
	};
	~loop.playback = true;
};

~loop.playStop = {
	~play.free;
	~dub.free;
	~loop.playback = false;
};

~loop.playStart = {
	s.bind{
		~play = Synth(\play, [\whichBuf, ~buf[0], \loop, 1], ~playMGroup); // start playback
		~dub = Synth(\overdub, [\whichBuf, ~buf[0]], ~recGroup); //start and sync overdub synth
	};
	~loop.playback = true;
};

~loop.overdubRec = { // play should already be engaged
	// if (~loop.playback = false, ~loop.playStart.value);
	~dub.set(\t_startDub, 1);
};

~loop.overdubStop = { // stop recording, but keep playing
	~dub.set(\t_stopDub, 1);
	// ~playDub = Synth(\play, [\whichBuf, ~buf[1], \loop, 1], ~playMGroup);
};
)

s.freeAll;
~loop.setup.value;
~loop.recStart.value;
~loop.recStop.value;
~loop.playStop.value;
~loop.playStart.value;
~loop.overdubRec.value;
~loop.overdubStop.value;


a = {
	fork{
		"hello".postln;
		1.0.wait;
		"world".postln;
	};
};

a.value;
a = true;
if (a = true, "true", "false");

~buf[0].plot;


~rec = Synth(\rec, [\whichBuf, ~buf[0]], ~recGroup); ~rec.set(\t_start, 1); // start recordiing main loop
~rec.set(\t_stop, 1); ~play = Synth(\play, [\whichBuf, ~buf[0], \loop, 1], ~playMGroup);

~dub = Synth(\overdub, [\whichBuf, ~buf[0]], ~recGroup); ~dub.set(\t_startDub, 1);
~dub.set(\t_stopDub, 1);

~play = Synth(\play, [\whichBuf, ~buf[0], \loop, 1], ~playMGroup);

~in.free;
~rec.free;
~play.free;
~dub.free;
~out.free;

~rec.free; ~play.free; ~dub.free;

~buf[0].plot;
s.sendMsg("/n_free", 1014);


// make a quick gui to control all this stuff
(
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
	~loop.setup;
});

~but1 = Button(w, Rect(25, 100, 350, 100))
.states_([["REC", Color.white, Color.magenta(0.5)], ["OVERDUB", Color.white, Color.blue(0.5)]])
.mouseDownAction_({
	| mode |
	if (mode.value == 0,
		{
			"record!".postln
			~loop.recStart;
		},
		{
			"overdub!".postln;
			~but2 = 1;
		}
	)
});

~but2 = Button(w, Rect(25, 225, 350, 100))
.states_([["PLAY", Color.white, Color.green(0.5)], ["STOP", Color.white, Color.red(0.5)]])
.mouseDownAction_({
	| mode, state |
	mode.postln
});

~but3 = Button(w, Rect(25, 350, 350, 100))
.states_([["CLEAR LAST", Color.white, Color.yellow(0.5)], ["CLEAR ALL", Color.white, Color.cyan(0.5)]])
.mouseDownAction_({
	| mode, state |
	mode.postln
});

)
w.close;
Window.closeAll;
w.view.children;
~recStart.visible_(true);
~recStart.bounds_(Rect(20, 20, 100, 100));
~recStart.enabled_(true);
~recStart.remove;
~recStart.value_(1);
~recStart.value;
~but2.value;
