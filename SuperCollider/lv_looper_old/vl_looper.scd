// Variable length looping sampler
s.boot;
(
q = ();
q.maxRecLength = 30;

q.recBuf = Buffer.alloc(s, s.sampleRate * q.maxRecLength, 2); // allocate a 30 sec buffer

SynthDef(\rec, { // record in
	| bufnum = 0, over = 0 |
	var sample;
	sample = SoundIn.ar([0, 1]); // record mic input for now..
	RecordBuf.ar(sample, bufnum, preLevel: over);
}).add;

SynthDef.new(\loop, { // playback
	| out = 0, bufnum, rate = 1, loop = 0, endFrame = 1 |
	Out.ar(out,
		BufRd.ar(2, bufnum, Phasor.ar(0, BufRateScale.kr(q.recBuf), 0, endFrame), loop)
	)
}).add;
)

(
~record = {
	arg val;
	val.postln;
	switch (val,
		0, { // stop recording
			a.free;
			q.recStopTime = Main.elapsedTime;
			q.numRecFrames = s.sampleRate * (q.recStopTime - q.recStartTime).trunc;
			q.loopBuf = Buffer.alloc(s, q.numRecFrames, 2);
			q.recBuf.getToFloatArray(0, q.numRecFrames*2, action: {
				arg array;
				a = array;
				q.loopBuf = q.loopBuf.sendCollection(a, action: {arg buf; "finished".postln;});
			});
		},

		1, { // record new
			q.recStartTime = Main.elapsedTime;
			a = Synth(\rec, [\bufnum, q.recBuf, \over, 0]); },
		2, { // overdub
			a = Synth(\rec, [\bufnum, q.recBuf, \over, 1]);
		};
	);
};

~play = {
	arg val;
	switch (val,
		1, { x = Synth(\loop, [\out, 0, \bufnum, q.recBuf, \loop, 1, \endFrame, q.numRecFrames]) },
		0, { x.free; }
	);
};

~dub = {
	arg val;
	switch (val,
		1, { d = Synth(\rec, [\bufnum, q.recBuf, \over, 1]); },
		0, { d.free; }
	);
};
)

x = { PlayBuf.ar(2, q.loopBuf, loop: 1)}.play;

x = Synth.new(\loop, [\out, 0, \bufnum, q.loopBuf, \loop, 1, \endFrame, q.numRecFrames]);
x.free;

~record.value(1); // record start
~record.value(0); // record stop
~record.value(2); // overdub
~play.value(1);
~play.value(0);
q.recBuf.plot;
q.loopBuf.plot;
Platform.systemExtensionDir;


Timer
IndexIn