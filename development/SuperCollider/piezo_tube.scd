/*

This will play a percussive tube physical model based on piezo input.
See Arduino sketch in folder.
(For Noisebox, can use basic Prynth analog inputs.)

*/



// use this
{(NTube.ar(Impulse.ar(1),`[0.97,1.0,1.0,1.0,1.0,0.97],`[0.5,MouseY.kr(-1.0,1.0),0.2,-0.4],`([0.01,0.02,0.01,0.005,0.05]*MouseX.kr(0.001,1.0,'exponential')))*0.5).dup}.play

// establish serial connection
SerialPort.devices;
// ~port = SerialPort("/dev/tty.SLAB_USBtoUART", 115200);
~port = SerialPort("/dev/tty.usbserial-AL00UBPE", 115200);


// SynthDef for Impulse
(
SynthDef(\tap, {
	| amp = 1.0 |
	var sig = Impulse.ar(0)*amp;
	OffsetOut.ar(0, sig);
	FreeSelf.kr(Impulse.kr(0));
}).add;
)

(
SynthDef(\tap, {
	| amp = 1.0 |
	var sig;
	var pulse = Impulse.ar(0)*amp;
	sig = (NTube.ar(pulse,`[0.97,1.0,1.0,1.0,1.0,0.97],`[0.5,MouseY.kr(-1.0,1.0),0.2,-0.4],`([0.01,0.02,0.01,0.005,0.05]*MouseX.kr(0.001,1.0,'exponential')))*0.5);
	DetectSilence.ar(sig, doneAction: Done.freeSelf);
	OffsetOut.ar([0,1], sig!2);
	// FreeSelf.kr(sig); // need to delay this to allow synth to play through before freeing!!! (don't know how...)
}).add;
)

// routine to fire impulse when sensor is tapped.
(
~getValues = Routine({
	var thresh = 0.01;
	var valByte;
	var lastVal = 0;
	var diff;
	{
		valByte = ~port.read;
		valByte = valByte/255.0;
		// valByte.postln;
		diff = (valByte - lastVal);
		if (diff > thresh, {
			valByte.postln;
			Synth.grain(\tap, [\amp, valByte]);
		});
		lastVal = valByte;
	}.loop;
}).play;
)

~port.close;
~getValues.stop; // close connection & stop routine when done
