(
~buf = Buffer.alloc(s, 5*s.sampleRate, 2);
~buf.zero;
~inGroup = Group.new(s);
~recGroup = Group.after(~inGroup);
~playGroup = Group.after(~recGroup);
~outGroup = Group.after(~playGroup);

SynthDef(\in, {
	arg recBus, dirBus;
	var sig = SoundIn.ar([0, 1]);
	Out.ar(recBus, sig);
	Out.ar(dirBus, sig);
}).add;

SynthDef(\loopRec, {
	arg myBuf, gate = 1, loop = 0;
	var sig = SoundIn.ar([0, 1]);
	SendTrig.kr(
		Gate.kr(
			Done.kr( RecordBuf.ar(sig, myBuf, 0, 1, 1, 1, 0)),
			gate),
		0, 1);
}).add;

SynthDef(\loopPlay, {
	arg outBus, myBuf, loop = 1;
	Out.ar(outBus, PlayBuf.ar(2, myBuf, 1, 1, 0, 1));
}).add;

SynthDef(\out, {
	arg inBus, dirBus, outBus;
	var dirSig, recSig, outSig;
	dirSig = In.ar(dirBus, 2);
	recSig = In.ar(inBus, 2);
	outSig = dirSig + recSig;
	Out.ar(0, outSig);
}).add;

o = OSCFunc({
	| msg |
	msg[3].postln;
	if (msg[3] == 1,
		{
			"overdub!".postln;
			~loopRec.free;
			~loopPlay = Synth(\loopPlay, [\outBus, 120, \myBuf, ~buf], ~playGroup);
			~overdub = Synth(\loopRec, [\myBuf, ~buf, \gate, 0, \loop, 1], ~recGroup);
		}
	)
}, '/tr'
);

)

~buf.zero;
~in = Synth(\in, [\recBus, 100, \dirBus, 110], ~inGroup);
~out = Synth(\out, [\dirBus, 110, \inBus, 120], ~outGroup);

~loopRec = Synth(\loopRec, [\myBuf, ~buf, \gate, 1, \loop, 0], ~recGroup);


y = { Out.ar(0, In.ar(100, 2)) }.play;
z = { Out.ar(100, SoundIn.ar([0,1])); }.play;
a = Synth(\rloop, [\myBuf, ~buf]);
a.free;
~buf.plot;
~buf.play;


b = { Out.ar(0, PlayBuf.ar(2, ~buf, 1, 1, 0, 1)) }.play;

b.free;
y.free;
z.free;
~loopPlay.free;

(
o = OSCFunc({
	| msg |
	msg[3].postln;
	if (msg[3] == 1,
		{
			"overdub!".postln;
			~loopRec.free;
			~loopPlay = Synth(\loopPlay, [\outBus, 120, \myBuf, ~buf], ~playGroup);
			~overdub = Synth(\rloop, [\myBuf, ~buf, \gate, 0, \loop, 1], ~recGroup);
		}
	)
}, '/tr'
);
)

