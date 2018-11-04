s.boot;
s.reboot;

~outBus  = Bus.audio(s, 2);
~abus = (); ~abus.rec = Bus.audio(s, 2);
~abus;
~outBus;

SynthDef(\input, {
	arg amp = 1, recBus, dirBus;
	var in, recSig, dirSig;
	in = SoundIn.ar([0,1]);
	recSig = in*amp;
	dirSig = in*amp;
	Out.ar(recBus, in);
}).add;

a = Synth.new(\input, [\recBus, ~abus.rec]);
a.set(\recBus, ~outBus);
a.set(\bus, ~outBus);
a.free;

SynthDef(\input, {
	arg amp = 1, recBus = ~abus.rec, dirBus = ~abus.dir;
	var in, recSig, dirSig;
	in = SoundIn.ar([0, 1]);
	recSig = in*amp;
	dirSig = in*amp;
	Out.ar(recBus, recSig);
	Out.ar(dirBus, dirSig);
}).add;

~abus.rec.free;
~abus;
s.freeAll;