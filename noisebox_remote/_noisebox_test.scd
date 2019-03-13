fork{
	SynthDef(\test, { |freq = 220|
		var sig;
		sig = SinOsc.ar(freq, mul: 0.1);
		Out.ar([0,1], sig);
	}).add;

	s.sync;

	~testsynth = Synth(\test);

	s.sync;
	
	[0, 1, 10, 11, 12, 13].do({
		| mux |
		[mux].postln;
		
		8.do({
			| sensor |
			var testAddr = "/raspberrypi/"++mux++"/"++sensor;
			var defAddr = "sensor_post"++mux++"-"++sensor;
			testAddr.postln;
			OSCdef(defAddr, {|msg, time, addr, recvPort|
				msg.postln;
			}, testAddr, n);
		});
	});
	
	/*
	OSCdef(\test, {|msg, time, addr, recvPort|
		~testsynth.set(\freq, msg[1].linlin(0, 1, 100, 500));
		msg.postln;
	}, '/raspberrypi/1/2', n);
	*/
};
