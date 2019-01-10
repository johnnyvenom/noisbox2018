s.reboot;
(
~loop = Buffer.alloc(s, 60*s.sampleRate, 2);

~abus = ();
~abus.dir = Bus.audio(s, 2);
~abus.rec = Bus.audio(s, 2);
~abus.phasor = Bus.audio(s, 1);
~abus.fb = Bus.audio(s, 2);
~abus.out = Bus.audio(s, 2);

g = (); //groups
g.in = Group.head;
g.phasor = Group.after(g.in);
g.playBus = Group.after(g.phasor);
g.recBus = Group.after(g.playBus);
g.out = Group.after(g.recBus);

SynthDef(\in, {
	arg dirBus, recBus;
	var inSig, dirSig, recSig;
	inSig = SoundIn.ar([0, 1]);
	dirSig = inSig;
	recSig = inSig;
	Out.ar(dirBus, dirSig);
	Out.ar(recBus, recSig);
}).add;

SynthDef(\phasor, {
	arg rate, phasorBus, t_trig = 0, start = 0, end = 220500;
	var sig;
	sig = Phasor.ar(t_trig, 1, start, end);
	sig.poll(label: \phasor);
	Out.ar(phasorBus, sig);
}).add;

SynthDef(\rec, {
	arg whichBuf, phasorBus, recBus, fbBus;
	var recSig, fbSig, writeSig, phasor;
	phasor = In.ar(phasorBus);
	recSig = In.ar(recBus, 2);
	fbSig = In.ar(fbBus);
	writeSig = [recSig, fbSig].sum;
	// Out.ar(fbBus, writeSig);
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
	arg inBus, dirBus, dirGate = 1, amp = 1;
	var inSig, dirSig;
	inSig = In.ar(inBus, 2); // from playback
	dirSig = Gate.ar(In.ar(dirBus, 2), dirGate); // from direct
	Out.ar(0, [inSig, dirSig].sum * 0.5 * amp);
}).add;
)

~in = Synth(\in, [\dirBus, ~abus.dir, \recBus, ~abus.rec], g.in);
~out = Synth(\out, [\inBus, ~abus.out, \dirBus, ~abus.dir, \dirGate, 1], g.out);
~out.set(\dirGate, 0);


~in.free;
~out.free;
~phasor = Synth(\phasor, [\phasorBus, ~abus.phasor], g.phasor);
~phasor.set(\t_trig, 1);
~phasor.free;

( // RECORD a new loop
s.bind {
	// ~phasor.set(\t_trig, 1);
	~rec = Synth(\rec,
		[
			\whichBuf, ~loop,
			\phasorBus, ~abus.phasor,
			\recBus, ~abus.rec,
			\fbBus, ~abus.fb
		],
		g.recBus
	);
};
)
~rec.free;
s.sendMsg('/n_free', 1043);


( // PLAYBACK: 1. reset phasor, 2. play playback synth
s.bind {
	~phasor.set(\t_trig, 1);
	~play = Synth(\play,
		[
			\whichBuf, ~loop,
			\phasorBus, ~abus.phasor,
			\fbBus, ~abus.fb,
			\outBus, ~abus.out
		],
		g.playBus
	);
};
)
~play.free;

~loop.plot;
~loop.play;


~out.set(\inBus, ~abus.out, \amp, 1);

f = { Out.ar(~abus.fb, SoundIn.ar([0, 1])) }.play;
f = { Out.ar(0,  In.ar(~abus.fb, 2)) }.play;
f.free;

~loop.plot;
s.reboot;

s.options.blockSize;
s.options.headphoneLevel;