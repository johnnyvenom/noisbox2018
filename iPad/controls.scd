// **************************************
// OSC defs - inputs
// **************************************


// ~ip = "192.168.1.5"; // iPad IP address (home)
~ip = "192.168.1.148"; // iPad IP address (IDMIL - bodysuit1)
~port = 5001;
~root = "/raspberrypi";

// keyboard
"Creating keyboard OSCdefs...".postln;
~keys = ["/10/0", "/10/1", "/10/2", "/10/3", "/10/4", "/10/5", "/10/6", "/10/7", "/11/0", "/11/1", "/11/2", "/11/3", "/11/4", "/11/5", "/11/6", "/11/7", "/12/0", "/12/1", "/12/2", "/12/3", "/12/4", "/12/5", "/12/6", "/12/7"];
~note = Array.fill(24,0);

24.do({
	arg i;
	var addr = (~root++~keys[i]);
	var defName = ("note"++i);
	OSCdef.new(defName, { | msg, time, addr, recvPort |
		msg.postln;
		~note[i] = msg[1];
		// ~note.postln;
		~noteAction.value(~note[i], i, ~note); // args: this note on/off message, note ID, array of note on/offs
	}, addr);

});

//accelerometer
/*OSCdef.new(\accelerometer, { | msg, time, addr, recvPort |
	msg.postln;
}, '/accxyz');*/

//utility controls
"Creating utility control OSCdefs...".postln;
~setUtilityDef = { | num |
	var defName;
	switch (num)
	{0} {defName = "oct_up"}
	{1} {defName = "oct_down"}
	{2} {defName = "mode_down"}
	{3} {defName = "mode_up"}
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
			{"mode_down"} { ~page_shift.value("down", msg[1]) }
			{"mode_up"} { ~page_shift.value("up", msg[1]) }
			{"volume"} { ~in[\volume] = msg[1] }
			{"piezo_left"} { ~in[\piezo_left] = msg[1] } // tbd...
			{"piezo_right"} { ~in[\piezo_right] = msg[1] }; // tbd...
	}, addr);
});

// buttons and knobs
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
			{ "knob1" } { ~in[\knob1] = msg[1]; ~updateDisplay.value(defName, msg[1])}
			{ "knob2" } { ~in[\knob2] = msg[1]; ~updateDisplay.value(defName, msg[1])}
			{ "knob3" } { ~in[\knob3] = msg[1]; ~updateDisplay.value(defName, msg[1])}
			{ "knob4" } { ~in[\knob4] = msg[1]; ~updateDisplay.value(defName, msg[1])}
			{ "button1" } { ~in[\button1] = msg[1]; ~updateDisplay.value(defName, msg[1])}
			{ "button2" } { ~in[\button2] = msg[1]; ~updateDisplay.value(defName, msg[1])}
			{ "button3" } { ~in[\button3] = msg[1]; ~updateDisplay.value(defName, msg[1])}
			{ "button4" } { ~in[\button4] = msg[1]; ~updateDisplay.value(defName, msg[1]); ~clearGroup.value(msg[1]) };
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


// Dictionary for input values
"Creating Dictionary for input values...".postln;
~in = Dictionary.new(15);
~in.add(\oct_up -> 0.0);
~in.add(\oct_down -> 0.0);
~in.add(\mode_down -> 0.0);
~in.add(\mode_up -> 0.0);
~in.add(\volume -> 0.0);
~in.add(\piezo_left -> 0.0);
~in.add(\piezo_right -> 0.0);
~in.add(\knob1 -> 0.0);
~in.add(\knob2 -> 0.0);
~in.add(\knob3 -> 0.0);
~in.add(\knob4 -> 0.0);
~in.add(\button1 -> 0.0);
~in.add(\button2 -> 0.0);
~in.add(\button3 -> 0.0);
~in.add(\button4 -> 0.0);

// page up/down for buttons & knobs
~mode = 0;
~modeSwitch = {
	var maxMode = 7;
	if (~in[\mode_up] == 1, {
		"up".postln;
		if (~mode < maxMode, { ~mode = ~mode + 1 });
	});
	if (~in[\mode_down] == 1, 	{
		"down".postln;
		if (~mode > 0, { ~mode = ~mode - 1 });
	});
	~mode.postln;
};

// manage octave shifting
~oct_shift = {
	arg dir, val; // dir = up or down; val = 1 pressed, 0 released (ignore)
	var min = -2, max = 8;
	if (val == 1, {
		~octave = switch (dir)
		{"up"} { if (~octave < max, ~octave + 1, ~octave) }
		{"down"} { if (~octave > min, ~octave - 1, ~octave) };
		("Octave: " + ~octave).postln;
	});
};

~page_shift = {
	arg dir, val; // dir = up or down; val = 1 pressed, 0 released (ignore)
	var min = 0, max = 3;
	if (val == 1, {
		~page = switch (dir)
		{"up"} { if (~page < max, ~page + 1, ~page) }
		{"down"} { if (~page > min, ~page - 1, ~page) };
		("Page: " + ~page).postln;
	});
};

	