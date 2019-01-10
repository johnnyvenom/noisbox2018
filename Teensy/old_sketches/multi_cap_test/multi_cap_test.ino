#include <Adafruit_MPR121_prynth.h>

Adafruit_MPR121 cap1 = Adafruit_MPR121();
Adafruit_MPR121 cap2 = Adafruit_MPR121();
Adafruit_MPR121 cap3 = Adafruit_MPR121();
Adafruit_MPR121 cap4 = Adafruit_MPR121();

void setup() {
    while (!Serial);        // needed to keep leonardo/micro from starting too fast!

    Serial.begin(9600);
    Serial.println("Adafruit MPR121 Capacitive Touch sensor test");
   
    init_cap( cap1, 0x5A );
    init_cap( cap2, 0x5B );
    init_cap( cap3, 0x5C );
    init_cap( cap4, 0x5D );
}

void loop() {
  // nothing to do...
}

void init_cap ( Adafruit_MPR121 cap, uint8_t address ) {
    Serial.print( "looking for address " );
    Serial.println( address, HEX );
    if (!cap.begin( address )) {
      Serial.println("MPR121 not found, check wiring?");
      while (1);
    }
    Serial.println("MPR121 found!");
}
