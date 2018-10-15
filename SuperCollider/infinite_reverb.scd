(
// infinite feedback reverb..
~fb = {
	arg del = 0.006, feedback = 1, length = 10;
	var sig, local;

	sig = SoundIn.ar(0);
	local = LocalIn.ar(2)+sig.dup;

	15.do{ local = AllpassL.ar(local, 0.06, Rand(del.sqrt, del*del), length) };

	LocalOut.ar(local*feedback);

	Out.ar(0, Limiter.ar(sig + local, 0.5));
}.play;
)

~fb.set(\feedback, 0.1);
~fb.free;
s.meter;

(
// GUI control
w = Window.new.front;
b = ControlSpec(0.001, 1, \linear, 0.001);
c = NumberBox(w, Rect(20, 20, 150, 20));
a = Slider(w, Rect(20, 60, 150, 20))
    .value_(0.5)
    .action_({
	c.string_(b.map(a.value).asString);
	~fb.set(\feedback, a.value);
});
)

(
OSCdef.new( // del control doesn't doo much, but probably because of how its called in the SynthDef
	\delay,
	{
		arg msg;
		var spec = [0.001, 5, \lin].asSpec;
		~fb.set(\del, spec.map(msg[1]).postln);
	},
	'/3/fader3'
);
OSCdef.new(\feedback, {|msg| ~fb.set(\feedback, msg[1].postln)}, '/3/fader4' );
OSCdef.new(
	\length,
	{
		arg msg;
		var spec = [0.0, 10, \lin].asSpec;
		~fb.set(\length, spec.map(msg[1]).postln);
	},
	'/3/fader5'
);
)