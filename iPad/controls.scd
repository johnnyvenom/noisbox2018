// **************************************
// OSC defs - inputs
// **************************************

// ***** keyboard *****
"Creating keyboard OSCdefs...".postln;
~oscAddrs = ["/10/0", "/10/1", "/10/2", "/10/3", "/10/4", "/10/5", "/10/6", "/10/7", "/11/0", "/11/1", "/11/2", "/11/3", "/11/4", "/11/5", "/11/6", "/11/7", "/12/0", "/12/1", "/12/2", "/12/3", "/12/4", "/12/5", "/12/6", "/12/7"];
~note = Array.fill(24,0);

24.do({
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
"Creating utility control OSCdefs...".postln;
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
"Creating buttons and knobs OSCdefs...".postln;
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
			{ "knob1" } { ~knob1.value(msg[1]); ~updateDisplay.value(defName, msg[1]) }
			{ "knob2" } { ~knob2.value(msg[1]); ~updateDisplay.value(defName, msg[1]) }
			{ "knob3" } { ~knob3.value(msg[1]); ~updateDisplay.value(defName, msg[1]) }
			{ "knob4" } { ~knob4.value(msg[1]); ~updateDisplay.value(defName, msg[1]) }
			{ "button1" } { ~button1.value(msg[1]); ~updateDisplay.value(defName, msg[1]) }
			{ "button2" } { ~button2.value(msg[1]); ~updateDisplay.value(defName, msg[1]) }
			{ "button3" } { ~button3.value(msg[1]); ~updateDisplay.value(defName, msg[1]) }
			{ "button4" } { ~button4.value(msg[1]); ~updateDisplay.value(defName, msg[1]) };
	}, addr);
});

// ****************************
// OSC output to display
// ****************************
m = NetAddr(~ip, ~port);
// MODE status

// knob and button updates
"Setting up display output...".postln;
~updateDisplay = { | ctrl, val |
	switch (ctrl)
	{ "knob1" } {m.sendMsg("/display/knob1", val)}
	{ "knob2" } {m.sendMsg("/display/knob2", val)}
	{ "knob3" } {m.sendMsg("/display/knob3", val)}
	{ "knob4" } {m.sendMsg("/display/knob4", val)}
	{ "button1" } {m.sendMsg("/display/button1", val)}
	{ "button2" } {m.sendMsg("/display/button2", val)}
	{ "button3" } {m.sendMsg("/display/button3", val)}
	{ "button4" } {m.sendMsg("/display/button4", val)};
};

// *********************************
// End OSC assignments
// *********************************


// Dictionary for control values
// Don't need this for now...
"Creating Dictionary for input values...".postln;
~glob.add(\octave -> 2); //default octave for the synthesizer; range is -2 to 8.
~glob.add(\page -> 0); //page up/down through sets of controls.
~glob.add(\volume -> 0.5); // master vol
~glob.add(\piezo_left -> 0.0);
~glob.add(\piezo_right -> 0.0);

// page up/down for buttons & knobs
~page_shift = {
	arg dir, val; // dir = up or down; val = 1 pressed, 0 released (ignore)
	var min = 0, max = 3;
	if (val == 1, {
		~glob[\page] = switch (dir)
		{"up"} { if (~glob[\page] < max, ~glob[\page] + 1, ~glob[\page]) }
		{"down"} { if (~glob[\page] > min, ~glob[\page] - 1, ~glob[\page]) };
		("Page: " + ~glob[\page]).postln;
	});
};

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
	{ 3 } { ~ampAtt.value(val) };
};

~knob2 = { arg val;
	switch(~glob[\page])
	{ 0 } { ~osc2tune.value(val) }
	{ 1 } { ~lpfRes.value(val) }
	{ 2 } { ~lpfDec.value(val) }
	{ 3 } { ~ampDec.value(val) };
};

~knob3 = { arg val;
	switch(~glob[\page])
	{ 0 } { ~oscMix.value(val) }
	{ 1 } { ~lpfEnv.value(val) }
	{ 2 } { ~lpfSus.value(val) }
	{ 3 } { ~ampSus.value(val) };
};

~knob4 = { arg val;
	switch(~glob[\page])
	{ 0 } { ~oscNoise.value(val) }
	{ 1 } { ~lpfMix.value(val) }
	{ 2 } { ~lpfRel.value(val) }
	{ 3 } { ~ampRel.value(val) };
};

~button1 = { arg val;
	switch(~glob[\page])
	{ 0 } { ~osc1sel.value(val) }
	{ 1 } { "Page 1 Button 1 not assigned".postln; }
	{ 2 } { "Page 2 Button 1 not assigned".postln; }
	{ 3 } { "Page 3 Button 1 not assigned".postln; };
};

~button2 = { arg val;
	switch(~glob[\page])
	{ 0 } { ~osc2sel.value(val) }
	{ 1 } { "Page 1 Button 2 not assigned".postln; }
	{ 2 } { "Page 2 Button 2 not assigned".postln; }
	{ 3 } { "Page 3 Button 2 not assigned".postln; };
};

~button3 = { arg val;
	switch(~glob[\page])
	{ 0 } { "Page 0 Button 3 not assigned".postln; }
	{ 1 } { "Page 1 Button 3 not assigned".postln; }
	{ 2 } { "Page 2 Button 3 not assigned".postln; }
	{ 3 } { "Page 3 Button 3 not assigned".postln; };
};

~button4 = { arg val;
	switch(~glob[\page])
	{ 0 } { ~clearGroup.value(val); "freeing stuck notes".postln; }
	{ 1 } { ~clearGroup.value(val); "freeing stuck notes".postln; }
	{ 2 } { ~clearGroup.value(val); "freeing stuck notes".postln; }
	{ 3 } { ~clearGroup.value(val); "freeing stuck notes".postln; }
};

	