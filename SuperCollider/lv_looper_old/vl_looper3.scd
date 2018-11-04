s.reboot;

~maxRecLength = 30;
~maxLoops = 10;

~buf = nil!~maxLoops;

// create a bunch of buffers. ~buf[0] is master, the rest for overdubs.
~maxLoops.do({
	arg i;
	~buf[i] = Buffer.alloc(s, s.sampleRate * ~maxRecLength, 2);
});

//control buses
~


~timerBus = Bus.control(s, 1);

SynthDef(\rec, {
	arg t_start = 0, t_stop = 0, timerBus = ~timerBus, recLev = 1, preLev = 0, loop = 0, whichBuf;
	var inSig, isRec, timer;
	isRec = SetResetFF.kr(t_start, t_stop);
	inSig = SoundIn.ar([0,1]);
	timer = Timer.kr(t_start+t_stop);
	Out.kr(timerBus, timer);
	RecordBuf.ar(inSig, whichBuf, 0, recLev, preLev, isRec, loop);
}).add;

SynthDef(\play, {
	arg out = 0, whichBuf, rate = 1, loop = 0, endFrame = 1;
	var sig, length, trig, timer, phasor;
	timer = In.kr(~timerBus);
	timer = timer % (whichBuf.numFrames/s.sampleRate);
	timer.poll;
	trig = Impulse.kr(timer.reciprocal);
	Out.ar(out, BufRd.ar(2, whichBuf, Sweep.ar(trig, s.sampleRate), 1, 2));
}).add;

~maxLoops.do({ | i | ~buf[i].zero });

~recBuf.zero; // clear master buffer
~rec = Synth.new(\rec, [\whichBuf, ~buf[0]]);
~rec.set(\t_start, 1); // start recordiing main loop
~rec.set(\t_stop, 1); // stop recording main loop

~rec.set(\t_stop, 1); ~play = Synth(\play, [\whichBuf, ~buf[0], \loop, 1]);

~rec.set(\t_start, 1, \preLev, 1);

~rec.free;

~recBuf.plot;
~recBuf.play;
~play = Synth(\play, [\whichBuf, ~recBuf, \loop, 1]);
~play.free;


~recBuf.zero;
