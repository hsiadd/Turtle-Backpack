/****************************************************************************************************************************
 * GEN 3 Sensor Pack Logger with GPS and Temperature Sensor
 * Last updated May 13, 2020 by Luke Stuntz
 * 
 * REMOVE BATTERY BEFORE PLUGGING INTO COMPUTER
 ************************************************************************************************************************/


// First we include the libraries
#include <OneWire.h> 
#include <DallasTemperature.h>
#include <TinyGPS++.h>    
#include <LowPower.h> 
#include <SoftwareSerial.h>
#include <Wire.h>
#include <eepromi2c.h> 

/*******************( Case Specific Variables )***********************/

// how long will GPS receiver stay on at max?
int stay_on = 2 ; /*minutes*/

// how long is the data logging interval? (time between readings)
float logger_interval = 10; /*minutes*/

// how many GPS points do you want to take for max accuracy?
int fixes = 4 ;

/*******************( Defining pins )*****************/
#define temp_feed 2
#define gps_feed 3
#define transistor_eeprom 4
#define transistor_gps 5
#define transistor_temp 6
#define empty_pin 7

/****************( Creating Operational Variables )********************/
uint32_t feedDuration = stay_on * 60000;
uint32_t sleepInterval = (logger_interval * 60) / 8;
unsigned short address; //EEPROM adress
unsigned short address_location = 3999; 
uint32_t GPS_run = millis(), timer = millis();

// This is what all the data will be recorded in while reading from GPS and temperature sensor and writing to EEPROM
struct config {
  byte log_attempt;
  byte fixes;
  double lat;
  double lon;
  byte day;
  byte month;
  byte hour;
  byte minute;
  uint32_t sats;
  double temp;
} config;

/****************( Library specific object setups )********************/
TinyGPSPlus gps;

SoftwareSerial ss(gps_feed, empty_pin);

OneWire oneWire(temp_feed); 

DallasTemperature sensors(&oneWire);

/**********************( Functions )**************************/ 

// Runs GPS
bool feedGPS() {
    while (ss.available()) {
      if (gps.encode(ss.read()))
        return true;
        }
    return false;
}

// This is essentially a convoluted function to throw out GPS locations that are blatantly wrong
// During GPS sampling, multiple points are recorded
// If one point deviates from the mean more than twice the standard deviation, it is thrown out
// THIS IS NOT CURRENTLY USED - Has been succesfully integrated into past versions and is important to ensure elimination of significant errors
// Check to see the impact of including this function on battery life 
double outlying(double FixLats[], int points){
  double TrueLats[points];
  double sum = 0;
  double devsum = 0;
  double finalsum = 0;
    for (int i = 0; i < points; i++){
      sum += FixLats[i];
    }
    for (int i = 0; i < points; i++){
      double oavg = (sum - FixLats[i]) / (points - 1);
      devsum = 0;
      for (int g = 0; g < points; g++){
        double odev = abs(FixLats[g] - oavg);
        devsum += odev;
      }
      double stdev = devsum / points;
      if (abs(FixLats[i] - oavg) > 2 * stdev){
        TrueLats[i] = oavg;
      }
      else {
        TrueLats[i] = FixLats[i];
      }
    }
  for (int i = 0; i < points; i++){
    finalsum += TrueLats[i];
  }
  double fixedavg = finalsum / points;
  return fixedavg;
}

// Prints data to serial monitor when recorded
void printLocation() {

        Serial.print(config.fixes); Serial.print(",");
        Serial.print(config.sats); Serial.print(",");
        Serial.print(config.lat,6); Serial.print(",");
        Serial.print(config.lon,6); Serial.print(",");
        Serial.print(config.day); Serial.print("/");
        Serial.print(config.month);Serial.print(",");
        if (config.hour < 10) Serial.print("0");
        Serial.print(config.hour); Serial.print(":");
        if (config.minute < 10) Serial.print("0");
        Serial.print(config.minute);Serial.print(",");
        Serial.println(config.temp);
        delay(10);  
}

/**********************( Setup )**************************/ 

void setup() 
{ 
 // start serial port 
 Serial.begin(9600);
 ss.begin(9600);
 Wire.begin();

 Serial.println("Starting up Luke's sensor pack..."); 

 // Set transistor operating pins to output
 pinMode(transistor_eeprom, OUTPUT);
 pinMode(transistor_gps, OUTPUT);
 pinMode(transistor_temp, OUTPUT);
 pinMode(LED_BUILTIN, OUTPUT);

 for (int i = 0; i < 3; i++) {
        digitalWrite(LED_BUILTIN, HIGH);
        delay(400);
        digitalWrite(LED_BUILTIN, LOW);
        delay(400);
        }

 // Initialize EEPROM
 digitalWrite(transistor_eeprom, HIGH);
 eeRead(address_location, address);
 delay(10);
 digitalWrite(transistor_eeprom, LOW);

 // Blink three times to show that the unit has been setup
 for (int i = 0; i < 3; i++) {
        digitalWrite(LED_BUILTIN, HIGH);
        delay(1000);
        digitalWrite(LED_BUILTIN, LOW);
        delay(1000);
        }
}

/**************************( Loop )*******************************/
void loop() 
{ 

  Serial.println("Beginning data request...");

  digitalWrite(transistor_gps, HIGH);

  delay(1000);

  config.sats = 0;
  GPS_run = millis();
  int locs = 0;
  double RoughLats[fixes];
  double RoughLons[fixes];

  // Collect GPS Points and Number of Satellites
  while (millis() - GPS_run < feedDuration && locs < fixes){
      feedGPS();
      if (gps.location.isUpdated()){
        RoughLats[locs] = gps.location.lat();
        RoughLons[locs] = gps.location.lng();
        locs++ ;       
        config.sats = config.sats + gps.satellites.value();
        delay(5000);
        }  
    }  

  // Write data to config
  config.log_attempt = 1; 
  config.fixes = locs;
  config.lat = outlying(RoughLats, locs);
  config.lon = outlying(RoughLons, locs);
  config.day = gps.date.day();
  config.month = gps.date.month();
  config.hour = gps.time.hour();
  config.minute = gps.time.minute();
    
  digitalWrite(transistor_gps, LOW);

  // Collect temperature
  digitalWrite(transistor_temp, HIGH);
  delay(1000);
  sensors.requestTemperatures();
  config.temp = sensors.getTempCByIndex(0);
  delay(1000);
  digitalWrite(transistor_temp, LOW);

  delay(200);

  printLocation();

  delay(200);

  // Write data to EEPROM
  digitalWrite(transistor_eeprom, HIGH);
  delay(10);
  eeWrite(address,config);
  address += sizeof(config);
  eeWrite(address_location, address);
  delay(100);
  digitalWrite(transistor_eeprom, LOW);

  // Blinks mean point taken
  for (int i = 0; i < 3; i++) {
        digitalWrite(LED_BUILTIN, HIGH);
        delay(400);
        digitalWrite(LED_BUILTIN, LOW);
        delay(400);
        }

  // Sleep
  for (int i = 0; i < sleepInterval; i++){
      LowPower.powerDown(SLEEP_8S, ADC_OFF, BOD_OFF);
      } 
} 

/********************************************************************/
