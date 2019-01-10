fork{
	SynthDef(\test, { |freq = 220|
		var sig;
		sig = SinOsc.ar(freq, mul: 0.1);
		Out.ar([0,1], sig);
	}).add;

	s.sync;

	~testsynth = Synth(\test);

	s.sync;

	OSCdef(\test, {|msg, time, addr, recvPort|
		~testsynth.set(\freq, msg[1].linlin(0, 1, 100, 500));
		msg.postln;
	}, '/raspberrypi/2/0', n);
};


// Incoming OSC:
// 	/raspberrypi/10/0-5: keyboard C - F
//  /raspberrypi/11/0-5: keyboard F# - B
//	/raspberrypi/12/0-2: IMU roll, pitch, heading (x,y,z) (range: -180 - 180)
//  /raspberrypi/12/3: IMU altitudee (range: 0m - 1000m)
//  /raspberrypi/12/4: IMU temperature (range: 0degC - 100degC)

(
[0, 1, 2].do({
	arg mux;
	OSCdef.new(('\analog'++(mux+1)).asSymbol, {|msg| msg.postln;}, ('/raspberrypi/'++mux++'/0'))
});


[10, 11, 12].do({
	arg mux;
	switch (mux,
		10, {
			6.do({
				arg sensor;
				var defName = ('\keyboard'++(sensor+1)).asSymbol;
				var addr = ('/raspberrypi/10/'++sensor);
				OSCdef.new(defName, {|msg| msg.postln;}, addr);
			});
		},
		11, {
			6.do({
				arg sensor;
				var defName = ('\keyboard'++(sensor+6)).asSymbol;
				var addr = ('/raspberrypi/11/'++sensor);
				OSCdef.new(defName, {|msg| msg.postln;}, addr);
			});
		},
		12, {
			5.do({
				arg sensor;
				var defName = ('\imu'++(sensor+1)).asSymbol;
				var addr = ('/raspberrypi/12/'++sensor);
				OSCdef.new(defName, {|msg| msg.postln;}, addr);
			});
		}
	);
});
)

m = NetAddr("172.20.10.3", 5001);
m.sendMsg("/1/label4", "OK it works! Kinda....");
m.sendMsg("/raspberrypi/10/0", 1);


OSCdef(\inputs).free
OSCdef(\oneNote).free
OSCdef.freeAll
