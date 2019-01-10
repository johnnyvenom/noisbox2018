s.boot;
s.reboot;

(
~maxRecLength = 300;
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
	arg t_start, t_stop, inBus = 60, timerBus = 20, recLev = 1, preLev = 0, loop = 0, whichBuf;
	var inSig, isRec, timer;
	isRec = SetResetFF.kr(t_start, t_stop);
	inSig = In.ar(inBus, 2);
	timer = Timer.kr(t_start + t_stop);
	Out.kr(timerBus, timer);
	RecordBuf.ar(inSig, whichBuf, 0, recLev, preLev, isRec, loop);
}).add;

SynthDef(\play, {
	arg timerBus = 20, loopStartBus = 30, loopBus = 80, whichBuf, rate = 1, loop = 0, endFrame = 1;
	var sig, length, timer, loopStart, phasor;
	timer = In.kr(timerBus);
	timer = timer % (~buf[0].numFrames/s.sampleRate);
	timer.poll;
	loopStart = Impulse.kr(timer.reciprocal);
	Out.kr(loopStartBus, loopStart);
	Out.ar(loopBus, BufRd.ar(2, whichBuf, Sweep.ar(loopStart, s.sampleRate), 1, 2));
}).add;

SynthDef(\output, {
	arg loopBus = 80, dirBus = 70, loopAmp=1, dirAmp=1, mainAmp=1, out=0;
	var loopSig, dirSig, outSig;

	loopSig = In.ar(loopBus, 2) * loopAmp;
	dirSig = In.ar(dirBus, 2) * dirAmp;
	outSig = (loopSig + dirSig) * mainAmp;
	Out.ar(out, outSig);
}).add;


~inGroup = Group.new;
~recGroup = Group.after(~inGroup);
~playMGroup = Group.after(~recGroup);
~outGroup = Group.tail;
)

~in = Synth(\input, [], ~inGroup);
~rec = Synth(\rec, [\whichBuf, ~buf[0]], ~recGroup);

~rec.set(\t_start, 1); // start recordiing main loop
~rec.set(\t_stop, 1); ~play = Synth(\play, [\whichBuf, ~buf[0], \loop, 1], ~playMGroup);
~out = Synth(\output, [\dirBus, 70], ~outGroup);

~in.free;
~rec.free;
~play.free;
~out.free;

~buf[0].plot;

s.freeAll;