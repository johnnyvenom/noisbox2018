
// Prynth v05

#include "ADC.h"
#include <math.h>
#include "Prynth.h"
#include <i2c_t3.h>
//#include <Wire.h>
#include "Adafruit_MPR121.h"

int led = 13;

int numAdc = 16; //number of adcs used (number of muxes)
int numSensor = 8; // number of sensors (on each mux)

bool collectSensorData = LOW;

//sensor data arrays
float sensorArray[16][8];
float sensorArrayTemp[16][8];
bool sensorResolution[16][8] = {0};
bool sensorActive[16][8]= {0};

// Set sampling frequency in Hz . Each and every sensor will be sampled at this same rate.
float sampleFrequency = 10;

//Sensor Buffer initialization
SensorBuffer sensorBuf(10000);

// Filters for sensors
// No filtering by default - use setFilterParam() to set the filtering type and parameters in setup()
Filter sensorFilter[16][8];

int bufFullCount = 0;

void setup()
{
	

	//Initialize serial coms
  //Serial.begin(57600); // initialize this if you need to debug teensy via USB
	Serial1.begin(3000000, SERIAL_8N1); //Teensy to RPi
	//Serial3.begin(31250); //MIDI serial

	prynthInit();

	//led pin output mode
	pinMode(led, OUTPUT);
	//turn led on
	digitalWrite(led, HIGH);

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Initialize sensors here.
	// By default, all sensors are of LOW resolution and no filtering is applied.
	//
	// Sensor Resolution:
	// LOW - Range: 0-255
	// HIGH - Range: range of float
	// Example: sensorResolution[0][0] = HIGH;
	//
	// Available Filter types:
	// 0 - No filter
	// 1 - Low Pass Filter (Only enter filter_type and filter_cutoff. Enter 0 for 1euro_beta_value and difference_signal_cutoff)
	// 2 - One-Euro Filter (One Euro Filter by Géry Casiez, Nicolas Roussel and Daniel Vogel. More info: http://cristal.univ-lille.fr/~casiez/1euro/).

	// Example: sensorFilter[0][0].setFilterParam(filter_type, filter_cutoff, 1euro_beta_value, difference_signal_cutoff);

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	// Setup complete, start collecting sensor data
	collectSensorData = true;
}

//Function to send MIDI control change messages via Serial3
void sendMidicc (int channel, int cc, float value){
	Serial3.write(char(175 + channel));
	Serial3.write(char(cc));
	Serial3.write(char(value));
}

/////////////////MAIN LOOP/////////////////
void loop(){
	uint8_t sNum, mNum;
	float sVal;

  

	if(sensorBuf.bufAvailable() == 1)

  Serial.print("sensorBuf.bufAvailable: ");
  Serial.println(sensorBuf.bufAvailable());
 
	{
		//Read values from the buffer and filter them
		sensorBuf.bufRead(&sNum, &mNum, &sVal);
		if (mNum <= 9)  sVal /= pow(2,12);
		sensorFilter[mNum][sNum].setRawValue(sVal);

		if (sensorResolution[mNum][sNum] == HIGH) //High resolution - send float values
		{
			sensorArrayTemp[mNum][sNum] = sensorFilter[mNum][sNum].getFilteredOutput();
		}
		else  //Low resolution - send byte values
		{
			sensorArrayTemp[mNum][sNum] = round((float)sensorFilter[mNum][sNum].getFilteredOutput() * 255);
		}

		//if it's different from past values send via serial to RPi
		if (sensorArrayTemp[mNum][sNum] != sensorArray[mNum][sNum])
		{
			sensorArray[mNum][sNum] = sensorArrayTemp [mNum][sNum];

			bool res = sensorResolution[mNum][sNum];
			float sensorValue = sensorArray[mNum][sNum];

			//debug (requires uncommenting USB serial on top)
			//Serial.print(mNum);
			//Serial.print("/");
			//Serial.print(sNum);
			//Serial.print("/");
			//Serial.println(sensorArray[mNum][sNum]);

			// send to Raspberry Pi
			send2Rpi(res, mNum, sNum, sensorValue);

			//send if MIDI serial enabled
			//sendMidicc(1, 60 +sNum, float(adcArray[0][sNum])/1024 *127);
		}
	}

//  Serial.print("Serial1.available: ");
//  Serial.println(Serial1.available());
//  Serial.print("sensorBuf.bufAvailable: ");
//  Serial.println(sensorBuf.bufAvailable());
//  delay(100);
//  
	// Control data from Raspberry Pi,  for setting filter parameters, sensor data resolution, sample rate, sensor mask, etc.
	if(Serial1.available())
	{
		noInterrupts();
		collectSensorData = false;  //Pause sensor data acquisition.
		digitalWrite(led, LOW);
		sensorBuf.bufClear(); //Clear previous values in the sensor data buffer.
		getSerial(); // Parse the received data and process.
		collectSensorData = true; //Resume sensor data acquisition.
		digitalWrite(led,HIGH);
		interrupts();
	}
 
//  Serial.println(collectSensorData);
//  delay(500);
 
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Digital sensor handling
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 * First, the functions necessary for handling the I2C communication between the
 * sensor and the microcontroller must be added.
 * Second, initialize the sensors by calling the necessary functions in digitalSensorInit().
 * Finally, read the sensors and queue them into the sensorBuf buffer using the appropriate
 * mux and sensor values, within the digitalSensorRead() function.
 */

///////////////////////
// Example I2C Setup //
///////////////////////



Adafruit_MPR121 cap = Adafruit_MPR121();
// Keeps track of the last pins touched
// so we know when buttons are 'released'
uint16_t lasttouched = 0;
uint16_t currtouched = 0;

uint16_t capVals[12] = {0,0,0,0,0,0,0,0,0,0,0,0};

void digitalSensorInit()
{
  /*
   * Insert code to initialize I2C and SPI sensors.
   * mux numbers from 10-15 (=6) are dedicated for digital sensors.
   * sensor numbers 0-7 (=8) are to send the sensor data (raw or cooked)
   */

  delay(500);

  /* Connect to cap. touch sensor */
  Serial.println("Searching for MPR121");
  if(!cap.begin(0x5A)) {
    Serial.println("MPR121 not found.");
    while(1);
  }
  Serial.println("MPR121 found!");
  Serial.println();

  #define CAPLO_MUX 10  // cap touch 0 - 5
  #define CAPHI_MUX 11  // cap touch 6 - 11
}

void digitalSensorRead(int mux, int sensor)
{
 /*
  *  Insert code to read data from I2C and SPI sensors.
  *  Integrate the digital sensor values into the sensorBuf queue writing the normalized values
  *  (0-1) to the buffer.
  */

  Serial.println("digitalSensorRead");

  // Get the currently touched pads
  currtouched = cap.touched();
  
  for (uint8_t i=0; i<12; i++) {
    // it if *is* touched and *wasnt* touched before, alert!
    if ((currtouched & _BV(i)) && !(lasttouched & _BV(i)) ) {
      capVals[i] = 1; 
      Serial.print(i); Serial.println(" touched");
    }
    // if it *was* touched and now *isnt*, alert!
    if (!(currtouched & _BV(i)) && (lasttouched & _BV(i)) ) {
      capVals[i] = 0;
      Serial.print(i); Serial.println(" released");
    }
  }

  // reset our state
  lasttouched = currtouched;

  // return;

  if (mux == CAPLO_MUX)
    //read inputs 0 - 5 and send to correct mux/sensor
    // for loop through sensors
    // 0, 1, 2, 3, 4, 5... 
    // get values (what are they? on/off - 0/1?) and normalize if needed (nope). 
    // do i need a schmitt trigger filter? nah... the Ada lib. should already do that
    // write to sensorBuf
  {
    if (sensor==0) {
      sensorBuf.bufWrite(sensor, mux, capVals[0]);
    }
//    for (uint8_t j=0; j<6; j++) {
//      if (sensor == j)
//      {
//        sensorBuf.bufWrite(sensor, mux, capVals[j]);
//      }
//    }
  }

//  if (mux == CAPHI_MUX)
//  //read inputs 6-11 and send to correct mux/sensor (same as above)
//  {
//    for (uint8_t j=0; j<6; j++) {
//      if (sensor == j)
//      {
//        sensorBuf.bufWrite(sensor, mux, capVals[j+6]);
//      }
//    }
//  }
}
