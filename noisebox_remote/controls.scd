// **************************************
// OSC defs - inputs
// **************************************

// ***** Keyboard - I2C capacitive sensors x 2 *****
// 20 Notes total:
// /raspberrypi/10/0 - A
// /raspberrypi/10/1 - A#
// /raspberrypi/10/2 - B
// /raspberrypi/10/3 - C
// /raspberrypi/10/4 - C#
// /raspberrypi/10/5 - D
// /raspberrypi/10/6 - D#
// /raspberrypi/10/7 - E
// /raspberrypi/11/0 - F
// /raspberrypi/11/1 - F#
// /raspberrypi/11/2 - G
// /raspberrypi/11/3 - G#
// /raspberrypi/11/4 - A
// /raspberrypi/11/5 - A#
// /raspberrypi/11/6 - B
// /raspberrypi/11/7 - C
// /raspberrypi/12/0 - C#
// /raspberrypi/12/1 - D
// /raspberrypi/12/2 - D#
// /raspberrypi/12/3 - E#

5.do({ 0.1.wait; ". ".post;});
"Creating keyboard OSCdefs...".postln;
~oscAddrs = ["/10/0", "/10/1", "/10/2", "/10/3", "/10/4", "/10/5", "/10/6", 
	"/10/7", "/11/0", "/11/1", "/11/2", "/11/3", "/11/4", "/11/5", "/11/6", 
	"/11/7", "/12/0", "/12/1", "/12/2", "/12/3"];
~note = Array.fill(~numKeys,0);

~numKeys.do({
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
// /raspberrypi/0/0 - oct_down
// /raspberrypi/0/1 - oct_up
// /raspberrypi/0/2 - page_down
// /raspberrypi/0/3 - page_up
// /raspberrypi/0/4 - piezo_left (inactive)
// /raspberrypi/0/5 - piezo_right (inactive)
// /raspberrypi/0/6 - volume
// /raspberrypi/0/7 - none

5.do({ 0.1.wait; ". ".post;}); "Creating utility control OSCdefs...".postln;

~setUtilityDef = { | num |
	var defName;
	switch (num)
	{0} {defName = "oct_down"}
	{1} {defName = "oct_up"}
	{2} {defName = "page_down"}
	{3} {defName = "page_up"}
	{4} {defName = "piezo_left"}
	{5} {defName = "piezo_right"}
	{6} {defName = "volume"};	
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
			{"piezo_left"} { } // tbd...
			{"piezo_right"} { } // tbd...
			{"volume"} { ~vol_adjust.value(msg[1]) };
	}, addr);
});

// ***** buttons and knobs *****
// /raspberrypi/1/0 - button1
// /raspberrypi/1/1 - button2
// /raspberrypi/1/2 - button3
// /raspberrypi/1/3 - button4
// /raspberrypi/1/4 - knob1
// /raspberrypi/1/5 - knob2
// /raspberrypi/1/6 - knob3
// /raspberrypi/1/7 - knob4

5.do({ 0.1.wait; ". ".post;}); "next".postln; 
"Creating buttons and knobs OSCdefs...".postln;

~setCtrlDef = { | num |
	var defName;
	switch (num)
	{0} {defName = "button1"}
	{1} {defName = "button2"}
	{2} {defName = "button3"}
	{3} {defName = "button4"}
	{4} {defName = "knob1"}
	{5} {defName = "knob2"}
	{6} {defName = "knob3"}
	{7} {defName = "knob4"};
};

8.do({
	arg i;
	var addr = (~root++"/1/"++i);
	var defName = ~setCtrlDef.value(i);

	OSCdef.new(
		defName,
		{ | msg, time, addr, recvPort |
			switch (defName)
			{ "button1" } { ~button1.value(msg[1]); ~updateDisplay.value(1, msg[1]) }
			{ "button2" } { ~button2.value(msg[1]); ~updateDisplay.value(2, msg[1]) }
			{ "button3" } { ~button3.value(msg[1]); ~updateDisplay.value(3, msg[1]) }
			{ "button4" } { ~button4.value(msg[1]); ~updateDisplay.value(4, msg[1]) }
			{ "knob1" } { ~knob1.value(msg[1]); ~updateDisplay.value(5, msg[1]) }
			{ "knob2" } { ~knob2.value(msg[1]); ~updateDisplay.value(6, msg[1]) }
			{ "knob3" } { ~knob3.value(msg[1]); ~updateDisplay.value(7, msg[1]) }
			{ "knob4" } { ~knob4.value(msg[1]); ~updateDisplay.value(8, msg[1]) };
			// { "button1" } { ~button1.value(msg[1]) }
			// { "button2" } { ~button2.value(msg[1]) }
			// { "button3" } { ~button3.value(msg[1]) }
			// { "button4" } { ~button4.value(msg[1]) }
			// { "knob1" } { ~knob1.value(msg[1]) }
			// { "knob2" } { ~knob2.value(msg[1]) }
			// { "knob3" } { ~knob3.value(msg[1]) }
			// { "knob4" } { ~knob4.value(msg[1]) };
	}, addr);
});

"OSC assignments complete.".postln;
// *********************************
// End OSC assignments
// *********************************

// **************************************************************************** //

// ****************************
// OSC output to display
// ****************************
"Setting up display stuff.".postln;

// ~dMap is an array that holds all mappings [0 - n] for each page
// nested arrays contain: [0] = instrument, [1 - 4] = buttons, [5 -8] = knobs
~dMap = Array.newClear(5);
~dMap[0] = [\pSynth, // instrument
	\osc1sel, \osc2sel, nil, nil, // buttons
	\osc1tune, \osc2tune, \oscMix, \oscNoise // knobs
];

~dMap[1] = [\pSynth, // instrument
	nil, nil, nil, nil, // buttons
	\lpfCut, \lpfRes, \lpfEnv, \lpfMix // knobs
];

~dMap[2] = [\pSynth, // instrument
	nil, nil, nil, nil, // buttons
	\lpfAtt, \lpfDec, \lpfSus, \lpfRel // knobs
];

~dMap[3] = [\pSynth, // instrument
	nil, nil, nil, nil, // buttons
	\ampAtt, \ampDec, \ampSus, \ampRel // knobs
];

~dMap[4] = [\looper, // instrument
	\loopRecDub, \loopPlayStop, \loopClearBuf, \loopMuteExt, // buttons
	\loopRate, nil, nil, \loopSrcMix // knobs
];

~currentTitleVal = Array.newClear(2);
~currentKnobVals = Array.newClear(4);
~currentButtonVals = Array.newClear(4);
~newTitleVal = Array.newClear(2);
~newKnobVals = Array.newClear(4);
~newButtonVals = Array.newClear(4);


~updateDisplayTitle = {
	arg text;
	text = text.toUpper;
	~newTitleVal = ["/display/title", text];
	~send_to_display.value();
	// m.sendMsg("/display/title", text);
};

// knob and button updates
~updateDisplay = {
	// call with the following arguments: [1] index (buttons 1-4, knobs 5-8), [2] actual value, [3] label, [4] normalized value (0-1) for knob only
	arg index, val;
		
	var page, inst, ctl, type, outVal, normVal, addr;
	
	var knob = Array.newClear(3); // hold temp knob vals to send
	var button = Array.newClear(2); // hold temp button vals to send

	page = ~glob[\page];
	inst = ~dMap[page][0];
	ctl = ~dMap[page][index]; //**** <----- need to update the args when it is called!!!!!
	type = if (index < 5, {"button"}, {"knob"});
	
	
	if (ctl != nil, { // ignore if control is not mapped
		addr = "/display/"++type++"/"++(index-1%4+1);

		// m.sendMsg(addr++"label", ~d[inst][ctl].label);
		
		switch(type,
			"knob", {
				// do knob things
				knob[0] = ~d[inst][ctl].outVal;
				knob[1] = ~d[inst][ctl].normVal;
				knob[2] = ~d[inst][ctl].label;
				// knob.postln;

				~newKnobVals[index-5] = [addr, knob[0], knob[1], knob[2]];
				~send_to_display.value();
				// m.sendMsg(addr, knob[0], knob[1], knob[2]);
			},
			"button", {
				// do button things
				if (val == 1, {
					button[0] = ~d[inst][ctl].normVal;
					button[1] = ~d[inst][ctl].label;

					~newButtonVals[index-1] = [addr, button[0], button[1]];
					~send_to_display.value();
					// m.sendMsg(addr, button[0], button[1]);
				});
			}
		);


		[page, inst, ctl, type, addr, ~d[inst][ctl].outVal.round(0.001)].postln;
	}, {
		~glob[\pageName][~glob[\page]].toUpper.post;
		" ".post;
		type.post;
		index-1%4+1.post;
		" isn't mapped".postln;
	});
};

// SEND OSC MESSAGES ON A CONTROLLABLE SCHEDULE
m = NetAddr(~ip, ~port); // establish connection to display (Python)

~prevTime = 0.0; // global var to store the last OSC send interval
~sendInterval = 0.05; 

~send_to_display = {
	// check time and send messages
	var currentTime = thisThread.seconds;

	if(currentTime > (~prevTime + ~sendInterval), {
		if(~currentTitleVal != ~newTitleVal, { // if new value is present
			m.sendMsg(~newTitleVal[0], ~newTitleVal[1]); // send it
			~currentTitleVal = ~newTitleVal; // update current
			// "sending title".postln;
		});

		4.do({
			| i |			
			if(~currentKnobVals[i] != ~newKnobVals[i], { // if new value is present
				m.sendMsg(~newKnobVals[i][0], ~newKnobVals[i][1], ~newKnobVals[i][2], ~newKnobVals[i][3]); // send it
				~currentKnobVals[i] = ~newKnobVals[i]; // update current
				// "sending knob".postln;
			});
			if(~currentButtonVals[i] != ~newButtonVals[i], { // if new value is present
				m.sendMsg(~newButtonVals[i][0], ~newButtonVals[i][1], ~newButtonVals[i][2]); // send it
				~currentButtonVals[i] = ~newButtonVals[i]; // update current
				// "sending button".postln;
			});
		});
		// "Done OSC send".postln;	
		~prevTime = thisThread.seconds;
	});
}; 

// **********************************************************************

// Dictionary for control values
// "Creating Dictionary for input values...".postln;
~glob.add(\octave -> 2); //default octave for the synthesizer; range is -2 to 8.
~glob.add(\page -> 0); //page up/down through sets of controls.
~glob.add(\volume -> 0.5); // master vol
~glob.add(\piezo_left -> 0.0);
~glob.add(\piezo_right -> 0.0);
~glob.add(\pageName -> [
	"Synth osc",
	"Synth filter",
	"Synth fltr ADSR",
	"Synth amp ADSR",
	"Looper"]);

// page up/down for buttons & knobs
// *************
// Pages:
// 0 -> Synth - oscillators
// 1 -> Synth - filter
// 2 -> Synth - filter ADSR
// 3 -> Synth - amp ADSR
// 4 -> Looper -
// *************

// @TODO: the correct controls aren't showing up when the display is changed, but the correct title is. NEED TO FIX. 


// CHANGE PAGES OF CONTROLS
~page_shift = {
	arg dir, val; // dir = up or down; val = 1 pressed, 0 released (ignore)
	
	var knob = Array.newClear(3); // hold temp knob vals to send
	var button = Array.newClear(2); // hold temp button vals to send

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
			type = if (index < 4, {"button"}, {"knob"});
			addr = "/display/"++type++"/"++(index%4+1);
			if (~dMap[~glob[\page]][index+1] != nil,
				{
					inst = ~dMap[~glob[\page]][0];
					ctl = ~dMap[~glob[\page]][index+1];
					
					switch(type,
						"knob", {
							// update knobs to new page
							knob[0] = ~d[inst][ctl].outVal;
							knob[1] = ~d[inst][ctl].normVal;
							knob[2] = ~d[inst][ctl].label;
							knob.postln;

							~newKnobVals[index-4] = [addr, knob[0], knob[1], knob[2]];
							~send_to_display.value();
							// m.sendMsg(addr, knob[0], knob[1], knob[2]);
						},
						"button", {
							// update buttons to new page
							button[0] = ~d[inst][ctl].normVal;
							button[1] = ~d[inst][ctl].label;

							~newButtonVals[index] = [addr, button[0], button[1]];
							~send_to_display.value();
							// m.sendMsg(addr, button[0], button[1]);
							button.postln;
						}
					);
				},
				{
					// update blank controls when page is switched
					switch(type,
						"knob", {
							
							~newKnobVals[index-4] = [addr, 0, 0, "---"];
							~send_to_display.value();
							// m.sendMsg(addr, knob[0], knob[1], knob[2]);
						},
						"button", {
							~newButtonVals[index] = [addr, " ", "---"];
							~send_to_display.value();
							// m.sendMsg(addr, button[0], button[1]);
						}
					);
				}
			);
		});
	});
};

// CHANGE OCTAVES ON KEYBOARD
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

// ADJUST VOLUME
~vol_adjust = {
	arg val;
	~glob[\volume] = val.linlin(0, 1, 0.001, 1);
	~master.set(\masterVol, ~glob[\volume]);
	~glob[\volume].postln;
};

// KNOB AND BUTTON MAPPINGS
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
	{ 4 } { } // "Page 4 Knob 2 not assigned".postln; };
};

~knob3 = { arg val;
	switch(~glob[\page])
	{ 0 } { ~oscMix.value(val) }
	{ 1 } { ~lpfEnv.value(val) }
	{ 2 } { ~lpfSus.value(val) }
	{ 3 } { ~ampSus.value(val) }
	{ 4 } { } // "Page 4 Knob 3 not assigned".postln; };
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
		{ 1 } { } // "Page 1 Button 1 not assigned".postln; }
		{ 2 } { } // "Page 2 Button 1 not assigned".postln; }
		{ 3 } { } // "Page 3 Button 1 not assigned".postln; }
		{ 4 } { ~loopRecDub.value; };
	});
};

~button2 = { arg val;
	if (val == 1, {
		switch(~glob[\page])
		{ 0 } { ~osc2sel.value(val) }
		{ 1 } { } // "Page 1 Button 2 not assigned".postln; }
		{ 2 } { } // "Page 2 Button 2 not assigned".postln; }
		{ 3 } { } // "Page 3 Button 2 not assigned".postln; }
		{ 4 } { ~loopPlayStop.value; };
	});
};

~button3 = { arg val;
	if (val == 1, {
		switch(~glob[\page])
		{ 0 } { } // "Page 0 Button 3 not assigned".postln; }
		{ 1 } { } // "Page 1 Button 3 not assigned".postln; }
		{ 2 } { } // "Page 2 Button 3 not assigned".postln; }
		{ 3 } { } // "Page 3 Button 3 not assigned".postln; }
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

// *****************************************************************/	

"controls.scd LOADED.".postln;
