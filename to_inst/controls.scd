// **************************************
// OSC defs - inputs
// **************************************

/* OSC addresses:

Keyboard - I2C capacitive sensors x 2
20 Notes total:
A-A#-B-C-C#-D-D#-E-F-F#-G-G#-A-A#-B-C-C#-D=D#-E
/raspberrypi/10/0
/raspberrypi/10/1
/raspberrypi/10/2
/raspberrypi/10/3
/raspberrypi/10/4
/raspberrypi/10/5
/raspberrypi/10/6
/raspberrypi/10/7
/raspberrypi/11/0
/raspberrypi/11/1
/raspberrypi/11/2
/raspberrypi/11/3
/raspberrypi/11/4
/raspberrypi/11/5
/raspberrypi/11/6
/raspberrypi/11/7
/raspberrypi/12/0
/raspberrypi/12/1
/raspberrypi/12/2
/raspberrypi/12/3

*/


// ***** keyboard *****
// "Creating keyboard OSCdefs...".postln;
~oscAddrs = ["/10/0", "/10/1", "/10/2", "/10/3", "/10/4", "/10/5", "/10/6", "/10/7", "/11/0", "/11/1", "/11/2", "/11/3", "/11/4", "/11/5", "/11/6", "/11/7", "/12/0", "/12/1", "/12/2", "/12/3"];
~note = Array.fill(20,0);

20.do({
	arg i;
	var addr = (~root++~oscAddrs[i]);
	var defName = ("note"++i);
	OSCdef.new(defName, { | msg, time, addr, recvPort |
		msg.postln;
		~note[i] = msg[1];
		~noteAction.value(~note[i], i, ~note); // args: this note on/off message, note ID, array of note on/offs
	}, addr);

});

// ***** accelerometer *****
/*OSCdef.new(\accelerometer, { | msg, time, addr, recvPort |
	msg.postln;
}, '/accxyz');*/

// ***** utility controls *****
// "Creating utility control OSCdefs...".postln;
~setUtilityDef = { | num |
	var defName;
	switch (num)
	{0} {defName = "oct_up"}
	{1} {defName = "oct_down"}
	{2} {defName = "page_down"}
	{3} {defName = "page_up"}
	{4} {defName = "volume"}
	{5} {defName = "piezo_left"}
	{6} {defName = "piezo_right"};
};

7.do({
	arg i;
	var addr = (~root++"/0/"++i);
	var defName = ~setUtilityDef.value(i);
	OSCdef.new(
		defName,
		{ | msg, time, addr, recvPort |
			switch (defName)
			{ "oct_down"} { ~oct_shift.value("down", msg[1]) }
			{ "oct_up"} { ~oct_shift.value("up", msg[1]) }
			{"page_down"} { ~page_shift.value("down", msg[1]) }
			{"page_up"} { ~page_shift.value("up", msg[1]) }
			{"volume"} { ~vol_adjust.value(msg[1]) }
			{"piezo_left"} { ~in[\piezo_left] = msg[1] } // tbd...
			{"piezo_right"} { ~in[\piezo_right] = msg[1] }; // tbd...
	}, addr);
});

// ***** buttons and knobs *****
// "Creating buttons and knobs OSCdefs...".postln;
~setCtrlDef = { | num |
	var defName;
	switch (num)
	{1} {defName = "knob1"}
	{2} {defName = "knob2"}
	{3} {defName = "knob3"}
	{4} {defName = "knob4"}
	{5} {defName = "button1"}
	{6} {defName = "button2"}
	{7} {defName = "button3"}
	{8} {defName = "button4"};
};

8.do({
	arg i;
	var addr = (~root++"/"++(i+1)++"/0");
	var defName = ~setCtrlDef.value(i+1);
	OSCdef.new(
		defName,
		{ | msg, time, addr, recvPort |
			switch (defName)
			{ "knob1" } { ~knob1.value(msg[1]); ~updateDisplay.value(1, msg[1]) }
			{ "knob2" } { ~knob2.value(msg[1]); ~updateDisplay.value(2, msg[1]) }
			{ "knob3" } { ~knob3.value(msg[1]); ~updateDisplay.value(3, msg[1]) }
			{ "knob4" } { ~knob4.value(msg[1]); ~updateDisplay.value(4, msg[1]) }
			{ "button1" } { ~button1.value(msg[1]); ~updateDisplay.value(5, msg[1]) }
			{ "button2" } { ~button2.value(msg[1]); ~updateDisplay.value(6, msg[1]) }
			{ "button3" } { ~button3.value(msg[1]); ~updateDisplay.value(7, msg[1]) }
			{ "button4" } { ~button4.value(msg[1]); ~updateDisplay.value(8, msg[1]) };
	}, addr);
});

// *********************************
// End OSC assignments
// *********************************



// ****************************
// OSC output to display
// ****************************
m = NetAddr(~ip, ~port);
// MODE status

~d = (); // hold all display values.

~storeCtlVals = {
	arg inst, ctl, outVal, normVal;
	~d[inst][ctl].put(\outVal, outVal);
	~d[inst][ctl].put(\normVal, normVal);
};

// array that holds all mappings [0 - n] for each page
// nested arrays [0] = instrument, [1 - 4] = knobs, [5 -8] = buttons
~dMap = Array.newClear(5);
~dMap[0] = [\pSynth, // instrument
	\osc1tune, \osc2tune, \oscMix, \oscNoise, // knobs
	\osc1sel, \osc2sel, nil, nil // buttons
];

~dMap[1] = [\pSynth, // instrument
	\lpfCut, \lpfRes, \lpfEnv, \lpfMix, // knobs
	nil, nil, nil, nil // buttons
];

~dMap[2] = [\pSynth, // instrument
	\lpfAtt, \lpfDec, \lpfSus, \lpfRel, // knobs
	nil, nil, nil, nil // buttons
];

~dMap[3] = [\pSynth, // instrument
	\ampAtt, \ampDec, \ampSus, \ampRel, // knobs
	nil, nil, nil, nil // buttons
];

~dMap[4] = [\looper, // instrument
	\loopRate, nil, nil, \loopSrcMix, // knobs
	\loopRecDub, \loopPlayStop, \loopClearBuf, \loopMuteExt // buttons
];


// knob and button updates
~updateDisplay = {
	// call with the following arguments: [1] index (knobs 1-4, buttons 5-8), [2] actual value, [3] label, [4] normalized value (0-1) for knob only
	arg index, val;
	var page, inst, ctl, type, label, outVal, normVal, addr;
	page = ~glob[\page];
	inst = ~dMap[page][0];
	ctl = ~dMap[page][index]; //**** <----- need to update the args when it is called!!!!!
	type = if (index < 5, {"knob"}, {"button"});

	addr = "/display/"++type++(index-1%4+1)++"/";

	m.sendMsg(addr++"label", ~d[inst][ctl].label);

	switch(type,
		"knob", {
			// do knob things
			m.sendMsg(addr++"val", ~d[inst][ctl].outVal.round(0.001));
			m.sendMsg(addr++type, ~d[inst][ctl].normVal);
		},
		"button", {
			// do button things
			if (val == 1, {
				m.sendMsg(addr++type, ~d[inst][ctl].normVal);
			});
		}
	);

	[page, inst, ctl, type, addr].postln;
};

~updateDisplayTitle = {
	arg text;
	text = text.toUpper;
	m.sendMsg("/display/text", text);
};

// Dictionary for control values
// "Creating Dictionary for input values...".postln;
~glob.add(\octave -> 2); //default octave for the synthesizer; range is -2 to 8.
~glob.add(\page -> 0); //page up/down through sets of controls.
~glob.add(\volume -> 0.5); // master vol
~glob.add(\piezo_left -> 0.0);
~glob.add(\piezo_right -> 0.0);
~glob.add(\pageName -> [
	"Synth - osc",
	"Synth - filter",
	"Synth - fltr ADSR",
	"Synth - amp ADSR",
	"Looper"]);

// page up/down for buttons & knobs
/* Pages:
0 -> Synth - oscillators
1 -> Synth - filter
2 -> Synth - filter ADSR
3 -> Synth - amp ADSR
4 -> Looper -
*/
~page_shift = {
	arg dir, val; // dir = up or down; val = 1 pressed, 0 released (ignore)
	var min = 0, max = 4;
	if (val == 1, {
		~glob[\page] = switch (dir)
		{"up"} { if (~glob[\page] < max, ~glob[\page] + 1, ~glob[\page]) }
		{"down"} { if (~glob[\page] > min, ~glob[\page] - 1, ~glob[\page]) };
		("Page: " + ~glob[\page]).postln;

		~updateDisplayTitle.value(~glob[\pageName][~glob[\page]]);

		8.do({
			| index |
			var type, addr, inst, ctl;
			type = if (index < 4, {"knob"}, {"button"});
			addr = "/display/"++type++(index%4+1)++"/";
			// index.postln;
			if (~dMap[~glob[\page]][index+1] != nil,
				{
					inst = ~dMap[~glob[\page]][0];
					ctl = ~dMap[~glob[\page]][index+1];
					[index, addr, inst, ctl, ~d[inst][ctl].label].postln;
					m.sendMsg(addr++"label", ~d[inst][ctl].label);
					m.sendMsg(addr++"val", ~d[inst][ctl].outVal);
					m.sendMsg(addr++type, ~d[inst][ctl].normVal);
				},
				{
					m.sendMsg(addr++"label", "---");
					m.sendMsg(addr++type, " ");
				}
			);
			// m.sendMsg(addr++"label", ~d[inst][ctl].label);
		});
	});
};

~glob[\pageName][~glob[\page]];

// manage octave shifting
~oct_shift = {
	arg dir, val; // dir = up or down; val = 1 pressed, 0 released (ignore)
	var min = -2, max = 8;
	if (val == 1, {
		~glob[\octave] = switch (dir)
		{"up"} { if (~glob[\octave] < max, ~glob[\octave] + 1, ~glob[\octave]) }
		{"down"} { if (~glob[\octave] > min, ~glob[\octave] - 1, ~glob[\octave]) };
		("Octave: " + ~glob[\octave]).postln;
	});
};

~vol_adjust = {
	arg val;
	~glob[\volume] = val.linexp(0, 1, 0.001, 1);
	~master.set(\masterVol, ~glob[\volume]);
	~glob[\volume].postln;
};

// knob and button mappings
~knob1 = { arg val;
	switch(~glob[\page])
	{ 0 } { ~osc1tune.value(val) }
	{ 1 } { ~lpfCut.value(val) }
	{ 2 } { ~lpfAtt.value(val) }
	{ 3 } { ~ampAtt.value(val) }
	{ 4 } { ~loopRate.value(val) };
};

~knob2 = { arg val;
	switch(~glob[\page])
	{ 0 } { ~osc2tune.value(val) }
	{ 1 } { ~lpfRes.value(val) }
	{ 2 } { ~lpfDec.value(val) }
	{ 3 } { ~ampDec.value(val) }
	{ 4 } { "Page 4 Knob 2 not assigned".postln; };
};

~knob3 = { arg val;
	switch(~glob[\page])
	{ 0 } { ~oscMix.value(val) }
	{ 1 } { ~lpfEnv.value(val) }
	{ 2 } { ~lpfSus.value(val) }
	{ 3 } { ~ampSus.value(val) }
	{ 4 } { "Page 4 Knob 3 not assigned".postln; };
};

~knob4 = { arg val;
	switch(~glob[\page])
	{ 0 } { ~oscNoise.value(val) }
	{ 1 } { ~lpfMix.value(val) }
	{ 2 } { ~lpfRel.value(val) }
	{ 3 } { ~ampRel.value(val) }
	{ 4 } { ~loopSrcMix.value(val) };
};

~button1 = { arg val;
	if (val == 1, {
		switch(~glob[\page])
		{ 0 } { ~osc1sel.value(val) }
		{ 1 } { "Page 1 Button 1 not assigned".postln; }
		{ 2 } { "Page 2 Button 1 not assigned".postln; }
		{ 3 } { "Page 3 Button 1 not assigned".postln; }
		{ 4 } { ~loopRecDub.value; };
	});
};

~button2 = { arg val;
	if (val == 1, {
		switch(~glob[\page])
		{ 0 } { ~osc2sel.value(val) }
		{ 1 } { "Page 1 Button 2 not assigned".postln; }
		{ 2 } { "Page 2 Button 2 not assigned".postln; }
		{ 3 } { "Page 3 Button 2 not assigned".postln; }
		{ 4 } { ~loopPlayStop.value; };
	});
};

~button3 = { arg val;
	if (val == 1, {
		switch(~glob[\page])
		{ 0 } { "Page 0 Button 3 not assigned".postln; }
		{ 1 } { "Page 1 Button 3 not assigned".postln; }
		{ 2 } { "Page 2 Button 3 not assigned".postln; }
		{ 3 } { "Page 3 Button 3 not assigned".postln; }
		{ 4 } { ~loopClearBuf.value; };
	});
};

~button4 = { arg val;
	if (val == 1, {
		switch(~glob[\page])
		{ 0 } { ~clearGroup.value(val); "freeing stuck notes".postln; }
		{ 1 } { ~clearGroup.value(val); "freeing stuck notes".postln; }
		{ 2 } { ~clearGroup.value(val); "freeing stuck notes".postln; }
		{ 3 } { ~clearGroup.value(val); "freeing stuck notes".postln; }
		{ 4 } { ~loopMuteExt.value; };
	});
};

	