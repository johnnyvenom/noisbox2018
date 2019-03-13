Noisebox 2018 build steps and notes
===================================

<br/><hr/>

### Table of Contents

<!-- MarkdownTOC -->

- [Hardware](#hardware)
    - [Enclosure](#enclosure)
    - [Processing](#processing)
    - [Sensors](#sensors)
    - [Display](#display)
    - [Power and connections](#power-and-connections)
- [Software](#software)
    - [Disk image](#disk-image)
    - [Teensy](#teensy)
    - [Additional libraries and scripts to install](#additional-libraries-and-scripts-to-install)
    - [Display](#display-1)
- [NOTES: Noisebox 2018 proto 1](#notes-noisebox-2018-proto-1)
    - [Current Status 18-Dec 2018](#current-status-18-dec-2018)

<!-- /MarkdownTOC -->
<hr/><br/>

## Hardware 

### Enclosure

- Fusion 360 parts: 
    - 3D print frame for modular design: 
        - Corner brackets (with tabs for screws)
        - Straight (or bent) frame pieces
    - Panels for lasercutting:
        - Create sketches to export to AI —> CorelDraw for cutting
- 3D print frame parts
- Lasercut acrylic panels 6mm. Can etch to clear out depths where needed
    - Cutouts for audio inputs/outputs
- \#6 x 1/2” phillips/slotted round head wood screws for construction

### Processing
    
- Raspberry Pi
- Assemble Prynth control board w/ Teensy
- FePi Zero audio board with Pi Mirror board (Edu’s design)
- Pimoroni On/Off shim

### Sensors

- Analog sensors: 
    - Analog sensor acquisition: 
        - 2x Prynth multiplexer boards for analog sensors (10k resistors for buttons)
    - Analog sensors: 
        - 4x knobs, 4x buttons (main controls)
        - 4x buttons, 1x knob, 2x piezo-TBD (page, octave, vol, TBD)
- Digital sensors (I2C): 
    - Capacitive touch keyboard: 
        - 2x MPR121 capacitive touch acquisition boards
        - 20x copper tape leads for keyboard
    - Motion:
        - LSM9DS1 9DOF board (Adafruit)
- Wiring - wire it all together…

### Display

- OLED 2.7” 128x64 Monochrome display
    - Wire to RPi gpio
    
### Power and connections

- 6600 mAh LiPo battery
- Adafruit Powerboost stepup converter/charger
- Powerboost to On/Off shim (USB)
- Power button to On/Off shim (momentary w/ LED - wire to any VIN/gnd pair)
- USB panel mount to Powerboost for battery charging
- Ethernet panel mount to RPi ethernet for programming

<br/><hr/><br/>

## Software

### Disk image

- http://idmil.org/pub/software/prynth/2018-10-30-prynth-v051.img.zip
    - Write to SD card using command line directions here: https://www.raspberrypi.org/documentation/installation/installing-images/mac.md
    - (or use balenaEtcher app for MacOS)

### Teensy

- Upload via Arduino IDE
- Custom code for digital sensor acquisition (see note below for WIP steps)

### Additional libraries and scripts to install

- Pimoroni On/Off shim. 
    - Once logged in via SSH, run `curl https://get.pimoroni.com/onoffshim | bash`

### Display

- Luma.OLED display drivers: 
    - Installation instructions at: https://luma-oled.readthedocs.io/en/latest/
    - Install for python3
    - Need to install `sudo apt-get install libopenjp2-7-dev` for use with python3
- enable SPI driver: 
    - Option 1 (raspi-config): `sudo raspi-config` -> Interfacing Options
    - Option 2 (command line): `sudo nano /boot/config.txt` -> uncomment `dtparam=spi=on`
        - (https://elinux.org/R-Pi_configuration_file)
        - (https://elinux.org/RPiconfig#Device_Tree)
    - For either option: add your user to the spi and gpio groups:
        - `$ sudo usermod -a -G spi,gpio pi`
    - luma.examples: https://github.com/rm-hull/luma.examples
- Python 3 OSC library: osc4py3
    - https://pypi.org/project/osc4py3/
- To make display load on startup, need to do the following: 
    + for some reason the `osc4py3` library is default installed in a different directory from the default python path. (Maybe by default all pip3 installs go here.. so could set $PYTHONPATH to this directory and use it instead for all the other libraries? Really doesn't matter except for making sudo check that directory.)
        * (The following steps would set up the default pip3 packages location as your PYTHONPATH).. not necessary tho if you follow the directions below these steps
        * To set $PYTHONPATH, add the following line to ~/.bashrc: 
            - `export PYTHONPATH=/home/pi/.local/lib/python3.5`
        * run `source ~/.bashrc`
        * Add the following line to `/etc/sudoers`:
            - `Defaults env_keep += "PYTHONPATH`
        * Check that correct PYTHONPATH is set by running these 2 commands: 
            - `echo $PYTHONPATH` and
            - `sudo $PYTHONPATH`
    + copy the `osc4py3` library from default location to python path: 
        * `sudo cp -r ~/.local/lib/python3.5/site-packages/osc4py3 /usr/local/lib/python3.5/dist-packages`
    + then add the following line to `/etc/rc.local` above `exit 0`:
        * `sudo python3 /home/pi/Display/display.py &`

<br/><hr/><br/>

## NOTES: Noisebox 2018 proto 1

### Current Status 18-Dec 2018 

- Hardware: 
    - (18-Dec 2018) Need different screws # 6, 1/2 in wood screw, round head, phillips or slotted 
    - (10-Jan 2019) Waiting on screws...
- Wiring: 
    - [x] Troubleshoot analog inputs
        - (18-Dec 2018) need to connect A B C muxi to ctl Prynth
        - (10- Jan 2019) all working now. Some noise on analog inputs (maybe better wiring, maybe just the way it is...)
    - [x] Digital inputs: multiple cap sensors
        - (18-Dec 2018) Cap sensor (use old sketch) working - need to cut jumper to change board address
        - (10-Jan 2019) all working now. 
    - [x] Digital inputs: IMU 
        + (18-Dec 2018) Working but need custom code for LSM9DS1 --> AHRS
            - See also Adafruit version: https://learn.adafruit.com/adafruit-lsm9ds1-accelerometer-plus-gyro-plus-magnetometer-9-dof-breakout?view=all
            - STATUS: Working. Now need to write correct code to convert raw 9DOF info to AHRS output. Need to combine LSM9DS1 Adafruit code with Mahoney filter (see also Adafruit - may be possible to combine that with Ivan’s existing Sparkfun code)
                + https://github.com/PaulStoffregen/MahonyAHRS
                + https://learn.adafruit.com/ahrs-for-adafruits-9-dof-10-dof-breakout?view=all
                + https://learn.adafruit.com/adafruit-lsm9ds1-accelerometer-plus-gyro-plus-magnetometer-9-dof-breakout?view=all
        + (10-Jan 2019) all working now. 
            * Used Adafruit LSM9DS1 code (updated for Prynth/2nd serial bus) combined with Adafruit AHRS library. 
            * Could add Madgwick filter if needed. 
- Power: 
    - Remove power LED on PowerBoost breakout. 
    - Could still experiment with latching button instead of momentary (better UX)
    - Eventually use rotary encoders instead of potentiometers! 
- Software: 
    - Migrate iPad code over to instrument. 
    - Implement motion controls 
    - Implement FX
    - Write Python OSC display code (use osc4py3 for Python 3 implementation)
- [x] Troubleshoot display. 
    - STATUS: should work with luma.oled update (see most recent Git Commit.)
    - Problem: luma.oled examples don’t run w/ Python 3. 
    - Troubleshooting step (current): Trying standard Rasbian install (Stretch Lite), with luma examples loaded via SFTP. 
    - SFTP usage: 
        - `sftp pi@192.168.1.XX`
        - `put -r path/to/local/luma.examples path/to/target/directory`
        - https://www.digitalocean.com/community/tutorials/how-to-use-sftp-to-securely-transfer-files-with-a-remote-server
        
        
Display wiring: | 1 2 - 4 - - 7 8 - - - - - - 15 16 - - - - | 


### Resources for Python display: 

- https://pillow.readthedocs.io/en/latest/reference/ImageFont.html#module-PIL.ImageFont
- https://pillow.readthedocs.io/en/latest/reference/ImageDraw.html
- https://luma-oled.readthedocs.io/en/latest/python-usage.html
- osc4py3: https://osc4py3.readthedocs.io/en/latest/msgbund.html







