// simple bus example
s.boot;
s.plotTree;
s.meter;
s.reboot;
s.quit;
s === Server.default;
s === Server.local;
Server.default = Server.internal;
Server.default = Server.local;

(
~myBus = Bus.audio(s, 2);
~synthGroup = Group.new;

// sound source
SynthDef.new(\source, {
	arg out;
	var sig;
	sig = Saw.ar([200, 202]);
	Out.ar(out, sig);
}).add;

// master output
SynthDef.new(\master, {
	arg vol;
	var sig = In.ar(~myBus, 2) * vol;
	Out.ar(0, sig);
}).add;


b = Synth.new(\master, [\vol, 0.2], ~synthGroup, addAction: 'addToTail');
a = Synth.new(\source, [\out, ~myBus], ~synthGroup);
)

~myBus.free;

b.set(\vol, 0.1);

SynthDef.removeAt(\source);
SynthDef.removeAt(\master);
a.free;
s.freeAll;

0.8.linexp(0, 1, 0.001, 1);
s.options.numAudioBusChannels;
s.options.numOutputBusChannels;
s.options.numInputBusChannels;
~master.set(\masterVol, 1.0, \in, 100);
~master.free;
~sendToMaster;
~sendToMaster.free;
s.reboot;
~synthGroup.free;
~synthGroup = Group.new(s);






