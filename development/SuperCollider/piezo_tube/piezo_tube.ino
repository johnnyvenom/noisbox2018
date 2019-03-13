int sensRaw = 0;
byte sensByte;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  
}

void loop() {
  // put your main code here, to run repeatedly:
  sensRaw = analogRead(A0); 
  sensByte = sensRaw/1024.0*256;
//  Serial.print(sensRaw);
//  Serial.print('a');
  Serial.write(sensByte);
  delay(10);
}
