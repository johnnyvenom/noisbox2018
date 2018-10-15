#include <math.h>
#include <ADC.h>
#include <Prynth.h>
#include <Adafruit_MPR121_prynth.h>
#include <Adafruit_Sensor_prynth.h>
#include <Adafruit_LSM303_U_prynth.h>
#include <Adafruit_BMP085_U_prynth.h>
#include <Adafruit_L3GD20_U_prynth.h>
#include <Adafruit_10DOF_prynth.h>

int led = 13;

int numAdc = 16; //number of adcs used (number of muxes)
int numSensor = 8; // number of sensors (on each mux)

bool collectSensorData = LOW;

//sensor data arrays
float sensorArray[16][8];
float sensorArrayTemp[16][8];
bool sensorResolution[16][8] = {0};
bool sensorActive[16][8] = {0};

// Set sampling frequency in Hz . Each and every sensor will be sampled at this same rate.
float sampleFrequency = 10;

//Sensor Buffer initialization
SensorBuffer sensorBuf(10000);

// Filters for sensors
// No filtering by default - use setFilterParam() to set the filtering type and parameters in setup()
Filter sensorFilter[16][8];

int bufFullCount = 0;

void setup() {

  //Initialize serial coms
  Serial.begin(57600); // initialize this if you need to debug teensy via USB
  Serial1.begin(3000000, SERIAL_8N1); //Teensy to RPi
  //Serial3.begin(31250); //MIDI serial

  prynthInit(); // includes digitalSensorInit()

  //led pin output mode
  pinMode(led, OUTPUT);
  //turn led on
  digitalWrite(led, HIGH);

  // Setup complete, start collecting sensor data
  collectSensorData = true;

}

//Function to send MIDI control change messages via Serial3
void sendMidicc (int channel, int cc, float value) {
  Serial3.write(char(175 + channel));
  Serial3.write(char(cc));
  Serial3.write(char(value));
}

/////////////////MAIN LOOP/////////////////
void loop() {
  uint8_t sNum, mNum;
  float sVal;

  if (sensorBuf.bufAvailable() == 1)

  {
    //Read values from the buffer and filter them
    sensorBuf.bufRead(&sNum, &mNum, &sVal);
    if (mNum <= 9)  sVal /= pow(2, 12);
    sensorFilter[mNum][sNum].setRawValue(sVal);
    //    Serial.println(sensorBuf.getNElements());
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
      Serial.print(mNum);
      Serial.print("/");
      Serial.print(sNum);
      Serial.print("/");
      Serial.println(sensorArray[mNum][sNum]);

      // send to Raspberry Pi
      send2Rpi(res, mNum, sNum, sensorValue);

      //send if MIDI serial enabled
      //sendMidicc(1, 60 +sNum, float(adcArray[0][sNum])/1024 *127);
    }
  }

  // Control data from Raspberry Pi,  for setting filter parameters, sensor data resolution, sample rate, sensor mask, etc.
  if (Serial1.available())
  {
    noInterrupts();
    collectSensorData = false;  //Pause sensor data acquisition.
    digitalWrite(led, LOW);
    sensorBuf.bufClear(); //Clear previous values in the sensor data buffer.
    getSerial(); // Parse the received data and process.
    collectSensorData = true; //Resume sensor data acquisition.
    digitalWrite(led, HIGH);
    interrupts();
  }

}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Digital sensor handling
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
   First, the functions necessary for handling the I2C communication between the
   sensor and the microcontroller must be added.
   Second, initialize the sensors by calling the necessary functions in digitalSensorInit().
   Finally, read the sensors and queue them into the sensorBuf buffer using the appropriate
   mux and sensor values, within the digitalSensorRead() function.
*/

// Digital sensor setup

long digSensorTimer = 0;

// MPR121 Capacitive touch sensor
Adafruit_MPR121 cap = Adafruit_MPR121(); // MPR121 Capacitive touch sensor

uint16_t lasttouched = 0;
uint16_t currtouched = 0;
uint16_t capVals[12] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

// ********** 10dof IMU instantiation and variables here **********
/* Assign a unique ID to the sensors */
Adafruit_10DOF                dof   = Adafruit_10DOF();
Adafruit_LSM303_Accel_Unified accel = Adafruit_LSM303_Accel_Unified(30301);
Adafruit_LSM303_Mag_Unified   mag   = Adafruit_LSM303_Mag_Unified(30302);
Adafruit_BMP085_Unified       bmp   = Adafruit_BMP085_Unified(18001);

/* Update this with the correct SLP for accurate altitude measurements */
float seaLevelPressure = SENSORS_PRESSURE_SEALEVELHPA;

float ahrsVals[5] = {0.0, 0.0, 0.0, 0.0, 0.0};

void digitalSensorInit() {
  delay(500);

  /*************************************************************************/
  // MPR121 initialization
  /*************************************************************************/
  Serial.println("Searching for MPR121");

  if (!cap.begin(0x5A)) {
    Serial.println("MPR121 not found");
    while (1);
  }
  Serial.println("MPR121 found");
  Serial.println();

#define CAPLO_MUX 10  // cap touch 0 - 5
#define CAPHI_MUX 11  // cap touch 6 - 11

  /*************************************************************************/
  // 10dof initialization
  /*************************************************************************/
  Serial.println("Searching for 10DOF IMU");

  if (!accel.begin())
  {
    /* There was a problem detecting the LSM303 ... check your connections */
    Serial.println(F("Ooops, no LSM303 detected ... Check your wiring!"));
    while (1);
  } else {
    Serial.println(F("LSM303 accelerometer found"));
  }
  if (!mag.begin())
  {
    /* There was a problem detecting the LSM303 ... check your connections */
    Serial.println("Ooops, no LSM303 detected ... Check your wiring!");
    while (1);
  } else {
    Serial.println(F("LSM303 magnetometer found"));
  }
  if (!bmp.begin())
  {
    /* There was a problem detecting the BMP180 ... check your connections */
    Serial.println("Ooops, no BMP180 detected ... Check your wiring!");
    while (1);
  } else {
    Serial.println(F("BMP180 barometer & thermometer found"));
  }
  Serial.println(F("\n"));

#define IMU_MUX 12 // r/p/y on MUX 0/1/2
}


void digitalSensorRead(int mux, int sensor)
{
  /*
      Insert code to read data from I2C and SPI sensors.
      Integrate the digital sensor values into the sensorBuf queue writing the normalized values
      (0-1) to the buffer.
  */

  long currentTime = millis();

  if (currentTime > digSensorTimer + (1 / sampleFrequency) * 1000.0) { // Get the currently touched pads if one sampling period has passed

    // MPR121 read values
    currtouched = cap.touched();

    for (uint8_t i = 0; i < 12; i++) {
      // it if *is* touched and *wasnt* touched before, alert!
      if ((currtouched & _BV(i)) && !(lasttouched & _BV(i)) ) {
        capVals[i] = 1;
      }
      // if it *was* touched and now *isnt*, alert!
      if (!(currtouched & _BV(i)) && (lasttouched & _BV(i)) ) {
        capVals[i] = 0;
      }
    }

    // reset our state
    lasttouched = currtouched;

    /*******************************
     * IMU read values
     *******************************/ 
    sensors_event_t accel_event;
    sensors_event_t mag_event;
    sensors_event_t bmp_event;
    sensors_vec_t   orientation;

    /* Read the accelerometer and magnetometer */
    accel.getEvent(&accel_event);
    mag.getEvent(&mag_event);

    /* Use the new fusionGetOrientation function to merge accel/mag data */
    if (dof.fusionGetOrientation(&accel_event, &mag_event, &orientation)) {
      /* 'orientation' should have valid .roll and .pitch fields */
      ahrsVals[0] = constrain(map(orientation.roll, -180.0, 180.0, 0.0, 1.0), 0.0, 1.0);
      ahrsVals[1] = constrain(map(orientation.pitch, -180.0, 180.0, 0.0, 1.0), 0.0, 1.0);
      ahrsVals[2] = constrain(map(orientation.heading, -180.0, 180.0, 0.0, 1.0), 0.0, 1.0);
//      Serial.print("Orientation:\t");
//      Serial.print(ahrsVals[0]);
//      Serial.print("\t");
//      Serial.print(ahrsVals[1]);
//      Serial.print("\t");
//      Serial.println(ahrsVals[2]);
    }

    bmp.getEvent(&bmp_event);
    if (bmp_event.pressure) {
    /* Get ambient temperature in C */
      float temperature;
      bmp.getTemperature(&temperature);
      
      /* Convert atmospheric pressure, SLP and temp to altitude */
      float altitude = bmp.pressureToAltitude(seaLevelPressure, bmp_event.pressure, temperature);
  
      ahrsVals[3] = constrain(map(altitude, 0, 1000, 0.0, 1.0), 0.0, 1.0);
      ahrsVals[4] = constrain(map(temperature, 0, 100, 0.0, 1.0), 0.0, 1.0);
//      Serial.print("Environment:\t");
//      Serial.print(ahrsVals[3]);
//      Serial.print("\t");
//      Serial.println(ahrsVals[4]);
    }

    digSensorTimer = currentTime;
  }
  

  /******************************************
    Write digital sensor data to SensorBuf
   ******************************************/
   
  if (mux == CAPLO_MUX) {
    //read inputs 0 - 5 and send to correct mux/sensor
    for (uint8_t j = 0; j < 6; j++) {
      if (sensor == j) {
//        Serial.print(sensor);
//        Serial.print("\t");
//        Serial.print(mux);
//        Serial.print("\t");
//        Serial.println(capVals[j]);
        sensorBuf.bufWrite(sensor, mux, capVals[j]);
      }
    }
  }

  if (mux == CAPHI_MUX) {
    for (uint8_t j = 0; j < 6; j++) {
      if (sensor == j) {
//        Serial.print(sensor);
//        Serial.print("\t");
//        Serial.print(mux);
//        Serial.print("\t");
//        Serial.println(capVals[j]);
        sensorBuf.bufWrite(sensor, mux, capVals[j + 6]);
      }
    }
  }

  if (mux == IMU_MUX) {
    for (uint8_t j = 0; j < 5; j++) {
      if (sensor == j) {
//        Serial.print(sensor);
//        Serial.print("\t");
//        Serial.print(mux);
//        Serial.print("\t");
//        Serial.println(ahrsVals[j]);
        sensorBuf.bufWrite(sensor, mux, ahrsVals[j]);
      }
    }
  }
}


