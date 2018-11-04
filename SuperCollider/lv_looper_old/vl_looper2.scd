/*
Variable length looping sampler
Based on Eli F. Synchronous looping Environment (https://www.youtube.com/watch?v=0w2laxU2jfE)

Attributes:
- each loop stored in separate buffer (no overwriting/overdubbing)
- Use start/stop triggers to start/end
= Send timer information via control busses
*/
s = Server.local;
s.boot;

~maxLoops = 8;
~maxLoopLength = 30;

// create 8 buffers in ~buf array
~buf = nil!~maxLoops;
~maxLoops.do({
	arg i;
	i.postln;
	~buf[i] = Buffer.alloc(s, s.sampleRate*~maxLoopLength, 2);
});

//control buses
~kBus = ();
~kBus.timer = Bus.control(s, 1);
~kBus.length = Bus.control(s, 1);
~kBus.downbeat = Bus.control(s, 1);
//audio buses
~aBus = ();
~aBus.recSig = Bus.audio(s, 2);
~aBus.dirSig = Bus.audio(s, 2);
~aBus.in = Bus.audio(s, 2);
~aBus.out = Bus.audio(s, 2);

//input
SynthDef(\input, {
	arg amp = 1, recBus = ~aBus.recSig, dirBus = ~aBus.dirSig;
	var in, recSig, dirSig;
	in = SoundIn.ar([0,1]);
	recSig = in*amp;
	dirSig = in*amp;
	Out.ar(recBus, recSig);
	Out.ar(dirBus, dirSig);
}).add;

//master record synth
SynthDef(\recM, {
	arg t_start = 0, t_stop = 0, timerBus = ~kBus.timer, inBus = ~aBus.in, recLev = 1, preLev = 0, loop = 0, whichBuf;
	var in, isRec, timer;

	isRec = SetResetFF.kr(t_start, t_stop);
	in = In.ar(inBus, 2);
	timer = Timer.kr(t_start+t_stop);
	Out.kr(timerBus, timer);
	RecordBuf.ar(in, whichBuf, 0, recLev, preLev, isRec, loop);
}).add;

//overdub record synth
SynthDef(\recD, {
	arg t_start = 0, t_stop = 0, inBus = ~aBus.in, recLev = 1, preLev = 0, loop = 0, whichBuf;
	var in, isRec;
	isRec = SetResetFF.kr(t_start, t_stop);
	in = In.ar(inBus, 2);
	RecordBuf.ar(in, whichBuf, 0, recLev, preLev, isRec, loop);
}).add;

//master playback synth
SynthDef(\playM, {
	arg rate, whichBuf, amp = 1, timerBus = ~kBus.timer, lengthBus = ~kBus.length, downbeatBus = ~kBus.downbeat, outBus = ~aBus.out;
	var sig, length, timer, downbeat, bufStart, phasor;
	timer = In.kr(timerBus); // get Timer triggers from recM synth
	timer = timer%(~buf[0].numFrames/s.sampleRate);
	/*start = 0 // will always start at the beginning of the buffer.
	end = timer*s.sampleRate; */
	length = timer * s.sampleRate; // length in samples (account for 2 channels?)
	downbeat = Impulse.ar(s.sampleRate/length);
	bufStart = PulseDivider.kr(downbeat, 1, 0);
	phasor = Sweep.ar(bufStart, 1);
	sig = BufRd.ar(2, whichBuf, phasor, 1, 2);
	Out.kr(lengthBus, length);
	Out.kr(downbeatBus, downbeat);
	Out.ar(outBus, sig);
}).add;

// overdub playback synth
SynthDef(\playD, {
	arg rate = 1, t_jump = 0, whichBuf, amp = 1, lengthBus = ~kBus.length, downbeatBus  = ~kBus.downbeat, outBus = ~aBus.out;
	var sig, jumpTrig, start, end, mlength, length, downbeat, sync, phasor;
	length = In.kr(lengthBus);
	downbeat = In.kr(downbeatBus);
	end = length;
	sync = SetResetFF.kr(downbeat, 0);
	jumpTrig = EnvGen.kr(Env.adsr(0.001, 0.001, 0, 1, 1, 0), sync);
	phasor = Select.ar(sync, [Silent.ar, Phasor.ar(jumpTrig+t_jump, BufRateScale.kr(whichBuf), 0, end, 0)]);
	sig = BufRd.ar(2, whichBuf, phasor, 1, 2);
	sig = sig * amp;
	Out.ar(outBus, sig);
}).add;

//output synth
SynthDef(\output, {
	arg recBus = ~aBus.rec, dirBus = ~aBus.dir, recAmp = 1, dirAmp = 1, mainAmp = 1, out = 0;
	var recSig, dirSig, outSig;
	recSig = In.ar(recBus, 2) * recAmp;
	dirSig = In.ar(dirBus, 2) * dirAmp;
	outSig = (recSig + dirSig) * mainAmp;
	Out.ar(out, outSig);
}).add;

~inGroup = Group.new;
~recGroup = Group.after(~inGroup);
~playMGroup = Group.after(~recGroup);
~playDGroup = Group.after(~playMGroup);
~outGroup = Group.after(~playDGroup);

~setup = {
	Task {
		8.do({
			arg i;
			~buf[i].zero;
		});
		0.02.wait;
		~inGroup = Group.new;
		~recGroup = Group.after(~inGroup);
		~playMGroup = Group.after(~recGroup);
		~playDGroup = Group.after(~playMGroup);
		~outGroup = Group.after(~playDGroup);
		0.02.wait;
		~in = Synth(\input, [], ~inGroup);
		~out = Synth(\output, [], ~outGroup);
	}.start;
};

CmdPeriod.removeAll;
CmdPeriod.add(~setup);

s.freeAll;

~rec = Synth.new(\recM, [\whichBuf, ~buf[0]], ~recGroup);
~rec.set(\t_start, 1);
~rec.set(\t_stop, 1); ~playM = Synth.new(\playM, [\whichBuf, ~buf[0]], ~playMGroup);

~buf[0].plot;
~buf[0].play;