/****************************************************************************************************************************
 * GEN 3 Sensor Pack Reader
 * Last updated May 13, 2020 by Luke Stuntz
 * 
 * REMOVE BATTERY BEFORE PLUGGING INTO COMPUTER
 * 
 * Read data into serial monitor by entering 'R'
 * This data can then be easily copied into a .txt file for conversion to .csv (or directly converted to .csv through delimination in Excel)
 * This could be improved by writing code to directly output a .csv
 * 
 * Clear data on sensor pack by entering 'C'
 ************************************************************************************************************************/

// First we include the libraries
#include <Wire.h>
#include <eepromi2c.h>

/*******************( Defining pins )*****************/
#define transistor_eeprom 4
#define transistor_gps 5
#define transistor_temp 6

/****************( Creating Operational Variables )********************/

// This is what all data will be stored in while reading from EEPROM to serial monitor
struct config {
  byte log_attempt;
  byte fixes;
  uint32_t sats;
  double lat;
  double lon;
  byte day;
  byte month;
  byte hour;
  byte minute;
  double temp;
  double a = 0;
  double b = 0;
  byte c = 0;
  byte d = 0;
} config;

unsigned short address_temp;
int address;

// used in Z case. Force prints x number of lines.
int numberLines = 25;  

/**********************( Functions )**************************/ 
// This prints the data to the serial monitor
void printLocation() {
        Serial.print(config.fixes); Serial.print(",");
        Serial.print(config.sats); Serial.print(",");
        Serial.print(config.lat,6); Serial.print(",");
        Serial.print(config.lon,6); Serial.print(",");
        Serial.print(config.day); Serial.print(",");
        Serial.print(config.month);Serial.print(",");
        if (config.hour < 10) Serial.print("0");
        Serial.print(config.hour); Serial.print(",");
        if (config.minute < 10) Serial.print("0");
        Serial.print(config.minute);Serial.print(",");
        Serial.println(config.temp, 4);
        delay(10);  
}

// This prints the menu of options
void menu() {
  Serial.println("___________MENU___________");
  Serial.println("Please type:");
  Serial.println("C - clear memory");
  Serial.println("R - Read locations (Reads each location)");
  Serial.print("Z - force print the first "); Serial.print(numberLines);Serial.println(" lines");
}

/**********************( Setup )**************************/ 
void setup(){
  
    Serial.begin(9600);
    Wire.begin();

    pinMode(transistor_eeprom, OUTPUT);
    pinMode(transistor_gps, OUTPUT);
    pinMode(transistor_temp, OUTPUT);
    pinMode(LED_BUILTIN, OUTPUT);
    digitalWrite(transistor_eeprom, HIGH); 
    digitalWrite(transistor_gps, LOW); 
    digitalWrite(transistor_temp, LOW);

    
    // blinks fast means read/clear sketch is loaded
    for (int i = 0; i < 5; i++) {
        digitalWrite(LED_BUILTIN, HIGH);
        delay(250);
        digitalWrite(LED_BUILTIN, LOW);
        delay(250);
        }

    menu();
}

/**************************( Loop )*******************************/
void loop(){

    if (Serial.available() == 1) {
      switch (toUpperCase(Serial.read())) {
        
        /************************* reads EEPROM *********************/
        case 'R':{
          digitalWrite(LED_BUILTIN, HIGH);
          
         // Reset flag and start address
          int x = 0; address = 0;

          Serial.println();
          Serial.println("************* COPY Begin *****************");
          Serial.println("Fixes,Total Sats,Lat,Lon,Day,Month,Hour,Minute,Temperature");

          while (x == 0) {
            eeRead(address, config);    //Read the first location into structure 'config'
            delay(1000);

            if (config.log_attempt == 0) {
              Serial.println();
              Serial.println("No more locations were recorded");
              Serial.println();
              x = 1;
            }
  
            else {
                printLocation(); 
              }

            address += sizeof(config);
            delay(5);
            }

          digitalWrite(LED_BUILTIN, LOW);
          Serial.println("************* Finished *****************"); Serial.println();
          menu();
        }   
        break;

        /****** clears EEPROM by writing a '0' to each address *******/
        case 'C':{ 
          digitalWrite(LED_BUILTIN, HIGH);

          Serial.println("");
          Serial.println("--------Clearing I2C EEPROM--------");
          Serial.print("Pleast wait until light turns off...");
  
          for (int i = 0; i < 4000; i++) {
            eeWrite(i, 0); delay(6);
          }
          
          Serial.println("Done"); 
          Serial.println("---------Done Clearing---------");
          digitalWrite(LED_BUILTIN, LOW); Serial.println();
          menu(); 
        }
        break;
         /*---------------------------------------------------------------*/

         /********************** for testing (force prints X lines of memory) *****************************/
        case 'Z':{ 
          digitalWrite(LED_BUILTIN, HIGH);

          eeRead(3999, address_temp);

          address = 0;
          Serial.println("************* Begin *****************");          
          for (int i = 0 ; i < numberLines; i++){
            eeRead(address, config); delay(100);
            printLocation(); 
            address += sizeof(config); 
          }


          Serial.print("Last address: ");Serial.println(address_temp);
          digitalWrite(LED_BUILTIN, LOW); 
          Serial.println("************* End *****************");
          Serial.println();
          menu(); 
        }
        break;
        /*---------------------------------------------------------------*/

        default:
          menu();
        break;
      }
    }
}
