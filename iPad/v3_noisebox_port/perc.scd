// This is the synth for the percussion that can be played with the piezos.. .

SynthDef(\perc, {
	| amp = 1.0, yTilt = 0.0, xTilt = 0.0 |
	var sig;
	var pulse = Impulse.ar(0)*amp;
	sig = (NTube.ar(pulse,`[0.97,1.0,1.0,1.0,1.0,0.97],`[0.5,xTilt,0.2,-0.4],`([0.01,0.02,0.01,0.005,0.05]*yTilt))*0.9);
	DetectSilence.ar(sig, doneAction: Done.freeSelf);
	OffsetOut.ar([0,1], sig!2);
}).add;

~perc_play_l = {
	arg amp;
	var xVal, yVal;
	var thresh = 0.2;
	amp.postln;

	if(amp > thresh, {
		yVal = ~glob[\accxyz][1].linexp(-1, 1, 0.001, 1.0);
		xVal = ~glob[\accxyz][0].linlin(-1, 1, -1.0, 1.0);

		Synth.grain(\perc, [\amp, amp, \yTilt, yVal, \xTilt, xVal], ~grp.perc);
		("left~" + yVal).postln;
	});
};

~perc_play_r = {
	arg amp;
	var xVal, yVal;
	var thresh = 0.2;

	if(amp > thresh, {
		yVal = ~glob[\accxyz][1].linexp(-1, 1, 1.0, 0.001);
		xVal = ~glob[\accxyz][0].linlin(-1, 1, -1.0, 1.0);

		Synth.grain(\perc, [\amp, amp, \yTilt, yVal, \xTilt, xVal], ~grp.perc);
		("right~" + yVal).postln;
	});
};

~updateXYvals = {
	arg accVals;
	var hmm;
};

~grp.perc.freeAll;