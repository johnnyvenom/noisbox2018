s.waitForBoot{
	~path = "/home/pi/prynth/server/public/supercolliderfiles/";
// 	(~path++"_prynth_extras_chime.scd").load;
//	(~path++"_noisebox_extras/main.scd").load;
	(~path++"main.scd").load;
};
