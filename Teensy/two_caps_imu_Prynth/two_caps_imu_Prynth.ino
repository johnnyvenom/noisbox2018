#include <math.h>
#include <ADC.h>
#include <Prynth.h>
#include <Adafruit_MPR121_prynth.h>
#include <Adafruit_Sensor_prynth.h>
#include <Adafruit_LSM9DS1_prynth.h>
#include <Adafruit_Simple_AHRS.h>

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
Adafruit_MPR121 cap1 = Adafruit_MPR121(); // MPR121 Capacitive touch sensor
Adafruit_MPR121 cap2 = Adafruit_MPR121(); // MPR121 Capacitive touch sensor

uint16_t lasttouched1 = 0; // keys 1 - 10
uint16_t currtouched1 = 0;
uint16_t lasttouched2 = 0; // keys 11 - 20
uint16_t currtouched2 = 0;
uint16_t capVals[20] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

// ********** LSM9DS1 IMU instantiation and variables here **********
/* Assign a unique ID to the sensors */
Adafruit_LSM9DS1    lsm(1000); // LSM9DS1 IMU; ID #1000

// Create simple AHRS algorithm using the LSM9DS0 instance's accelerometer and magnetometer.
Adafruit_Simple_AHRS ahrs(&lsm.getAccel(), &lsm.getMag());

// Function to configure the sensors on the LSM9DS0 board.
// You don't need to change anything here, but have the option to select different
// range and gain values.
void configureLSM9DS1(void)
{
  // 1.) Set the accelerometer range
  lsm.setupAccel(lsm.LSM9DS1_ACCELRANGE_2G);
  //lsm.setupAccel(lsm.LSM9DS1_ACCELRANGE_4G);
  //lsm.setupAccel(lsm.LSM9DS1_ACCELRANGE_8G);
  //lsm.setupAccel(lsm.LSM9DS1_ACCELRANGE_16G);
  
  // 2.) Set the magnetometer sensitivity
  lsm.setupMag(lsm.LSM9DS1_MAGGAIN_4GAUSS);
  //lsm.setupMag(lsm.LSM9DS1_MAGGAIN_8GAUSS);
  //lsm.setupMag(lsm.LSM9DS1_MAGGAIN_12GAUSS);
  //lsm.setupMag(lsm.LSM9DS1_MAGGAIN_16GAUSS);

  // 3.) Setup the gyroscope
  lsm.setupGyro(lsm.LSM9DS1_GYROSCALE_245DPS);
  //lsm.setupGyro(lsm.LSM9DS1_GYROSCALE_500DPS);
  //lsm.setupGyro(lsm.LSM9DS1_GYROSCALE_2000DPS);
}
float ahrsVals[3] = {0.0, 0.0, 0.0};

void digitalSensorInit() {
  delay(500);

  /*************************************************************************/
  // MPR121 initialization
  /*************************************************************************/
//  Serial.println("Searching for first MPR121");
//  cap1.begin(0x5A);
//  Serial.println("First MPR121 found");
//  
//  Serial.println("Searching for second MPR121");
//  cap2.begin(0x5C);
//  Serial.println("Second MPR121 found");

  Serial.println("Searching for MPR121 (1)");
  if (!cap1.begin(0x5A)) {
    Serial.println("MPR121 (1) not found");
    while (1);
  }
  Serial.println("MPR121 (1) found");
  Serial.println();

  Serial.println("Searching for MPR121 (2)");
  if (!cap2.begin(0x5C)) {
    Serial.println("MPR121 (2) not found");
    while (1);
  }
  Serial.println("MPR121 (2) found");
  Serial.println();

  #define CAPLO_MUX 10  // cap touch 0 - 7
  #define CAPMID_MUX 11 // cap touch 8 - 15
  #define CAPHI_MUX 12  // cap touch 16 - 19

  /*************************************************************************/
  // LSM9DS1 initialization
  /*************************************************************************/

  Serial.println("Searching for LSM9DS1");
  if (!lsm.begin()) {
    Serial.println("LSM9DS1 not found");
    while (1);
  }
  Serial.println("LSM9DS1 found");
  Serial.println();
  
  configureLSM9DS1(); // setup the sensor gain and integration time
  
  #define IMU_MUX 13 // r/p/y on MUX 0/1/2
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
    currtouched1 = cap1.touched();

    for (uint8_t i = 0; i < 10; i++) {
      // it if *is* touched and *wasnt* touched before, alert!
      if ((currtouched1 & _BV(i)) && !(lasttouched1 & _BV(i)) ) {
        capVals[i+10] = 1;
      }
      // if it *was* touched and now *isnt*, alert!
      if (!(currtouched1 & _BV(i)) && (lasttouched1 & _BV(i)) ) {
        capVals[i+10] = 0;
      }
    }

    // reset our state
    lasttouched1 = currtouched1;

    // MPR121 read values
    currtouched2 = cap2.touched();

    for (uint8_t i = 0; i < 10; i++) {
      // it if *is* touched and *wasnt* touched before, alert!
      if ((currtouched2 & _BV(i)) && !(lasttouched2 & _BV(i)) ) {
        capVals[i] = 1;
      }
      // if it *was* touched and now *isnt*, alert!
      if (!(currtouched2 & _BV(i)) && (lasttouched2 & _BV(i)) ) {
        capVals[i] = 0;
      }
    }

    // reset our state
    lasttouched2 = currtouched2;

//    for (int k = 0; k < 20; k++)
//    {
//      Serial.print(capVals[k]);
//      Serial.print(", ");
//    }
//    Serial.println();

    /*******************************
     * IMU read values
     *******************************/ 
    sensors_vec_t   orientation;
  
    // Use the simple AHRS function to get the current orientation.
    if (ahrs.getOrientation(&orientation))
    {
      // normalize all values to 0-1 to send to Prynth
      ahrsVals[0] = constrain(map(orientation.roll, -180.0, 180.0, 0.0, 1.0), 0.0, 1.0);
      ahrsVals[1] = constrain(map(orientation.pitch, -180.0, 180.0, 0.0, 1.0), 0.0, 1.0);
      ahrsVals[2] = constrain(map(orientation.heading, -180.0, 180.0, 0.0, 1.0), 0.0, 1.0);
      /* 'orientation' should have valid .roll and .pitch fields */
//      Serial.print(F("Orientation: "));
//      Serial.print(orientation.roll);
//      Serial.print(F(" "));
//      Serial.print(orientation.pitch);
//      Serial.print(F(" "));
//      Serial.print(orientation.heading);
//      Serial.println(F(""));
    }   
    
    /*
    sensors_event_t accel_event;
    sensors_event_t mag_event;
    sensors_event_t bmp_event;
    sensors_vec_t   orientation;

    // Read the accelerometer and magnetometer
    accel.getEvent(&accel_event);
    mag.getEvent(&mag_event);

    // Use the new fusionGetOrientation function to merge accel/mag data
    if (dof.fusionGetOrientation(&accel_event, &mag_event, &orientation)) {
      // 'orientation' should have valid .roll and .pitch fields 
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
    // Get ambient temperature in C
      float temperature;
      bmp.getTemperature(&temperature);
      
      // Convert atmospheric pressure, SLP and temp to altitude
      float altitude = bmp.pressureToAltitude(seaLevelPressure, bmp_event.pressure, temperature);
  
      ahrsVals[3] = constrain(map(altitude, 0, 1000, 0.0, 1.0), 0.0, 1.0);
      ahrsVals[4] = constrain(map(temperature, 0, 100, 0.0, 1.0), 0.0, 1.0);
//      Serial.print("Environment:\t");
//      Serial.print(ahrsVals[3]);
//      Serial.print("\t");
//      Serial.println(ahrsVals[4]);
    }
    */

    digSensorTimer = currentTime;
  }
  

  /******************************************
    Write digital sensor data to SensorBuf
   ******************************************/
   
  if (mux == CAPLO_MUX) {
    //read inputs 0 - 7 and send to correct mux/sensor
    for (uint8_t j = 0; j <= 7; j++) {
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

  if (mux == CAPMID_MUX) {
    for (uint8_t j = 0; j <= 7; j++) {
      if (sensor == j) {
//        Serial.print(sensor);
//        Serial.print("\t");
//        Serial.print(mux);
//        Serial.print("\t");
//        Serial.println(capVals[j]);
        sensorBuf.bufWrite(sensor, mux, capVals[j + 8]);
      }
    }
  }

  if (mux == CAPHI_MUX) {
    for (uint8_t j = 0; j <= 3; j++) {
      if (sensor == j) {
//        Serial.print(sensor);
//        Serial.print("\t");
//        Serial.print(mux);
//        Serial.print("\t");
//        Serial.println(capVals[j]);
        sensorBuf.bufWrite(sensor, mux, capVals[j + 16]);
      }
    }
  }


  if (mux == IMU_MUX) {
    for (uint8_t j = 0; j < 3; j++) {
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


