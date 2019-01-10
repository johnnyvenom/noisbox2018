
s.boot;

~maxRecLength = 30;
~maxLoops = 10;

~buf = nil!~maxLoops;

// create a bunch of buffers. ~buf[0] is master, the rest for overdubs.
~maxLoops.do({
	arg i;
	~buf[i] = Buffer.alloc(s, s.sampleRate * ~maxRecLength, 2);
});

//control buses
~kbus = ();
~kbus.timer = Bus.control(s, 1);
~kbus.loopstart = Bus.control(s, 1);

//audio buses
~abus = ();
~abus.in = Bus.audio(s, 2);
~abus.out = Bus.audio(s, 2);
~abus.rec = Bus.audio(s, 2);
~abus.dir = Bus.audio(s, 2);

SynthDef(\input, {
	arg amp = 1, recBus=50, dirBus=60;
	var in, recSig, dirSig;
	in = SoundIn.ar([0, 1]);
	recSig = in*amp;
	dirSig = in*amp;
	Out.ar(recBus, recSig);
	Out.ar(dirBus, dirSig);
}).add;


SynthDef(\rec, {
	arg t_start = 0, t_stop = 0, inBus = 50, timerBus = ~kbus.timer, recLev = 1, preLev = 0, loop = 0, whichBuf;
	var inSig, isRec, timer;
	isRec = SetResetFF.kr(t_start, t_stop);
	inSig = In.ar(inBus, 2);
	timer = Timer.kr(t_start+t_stop);
	Out.kr(timerBus, timer);
	RecordBuf.ar(inSig, whichBuf, 0, recLev, preLev, isRec, loop);
}).add;

SynthDef(\play, {
	arg timerBus = ~kbus.timer, loopStartBus = ~kbus.loopStart, outBus = 70, whichBuf = ~buf[0], rate = 1, loop = 0, endFrame = 1;
	var sig, length, timer, loopStart, phasor;
	timer = In.kr(timerBus);
	timer = timer % (~buf[0].numFrames/s.sampleRate);
	timer.poll;
	loopStart = Impulse.kr(timer.reciprocal);
	Out.kr(loopStartBus, loopStart);
	Out.ar(outBus, BufRd.ar(2, whichBuf, Sweep.ar(loopStart, s.sampleRate), 1, 2));
}).add;

SynthDef(\output, {
	arg recBus=70, dirBus=60, recAmp=1, dirAmp=1, mainAmp=1, out=0;
	var recSig, dirSig, outSig;

	recSig = In.ar(recBus, 2) * recAmp;
	dirSig = In.ar(dirBus, 2) * dirAmp;
	outSig = (recSig + dirSig) * mainAmp;
	Out.ar(out, outSig)
}).add;


// get ready to record

~maxLoops.do({ | i | ~buf[i].zero });

~inGroup = Group.new;
~recGroup = Group.after(~inGroup);
~playMGroup = Group.after(~recGroup);
~playDGroup = Group.after(~playMGroup);
~outGroup = Group.after(~playDGroup);

~in = Synth(\input, [\recBus, 50, \dirBus, 60], ~inGroup);
~out = Synth(\output, [\recBus, 70, \dirBus, 60], ~outGroup);

~rec = Synth.new(\rec, [\inBus, 50, \whichBuf, ~buf[0]], ~recGroup);

~rec.set(\t_start, 1); // start recordiing main loop
~rec.set(\t_stop, 1); ~play = Synth(\play, [\whichBuf, ~buf[0], \loop, 1], ~playMGroup);

~in.free;
~out.free;
~rec.free;
~play.free;

