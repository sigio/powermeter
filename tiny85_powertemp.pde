/*
 * Analog input, serial output
 * Reads an analog input pin, prints the results to the serial monitor.
 */

#include <OneWire.h>

#define ONEWIREPIN PB0
#define LEDPIN PB1
// #define TXPIN PB3 // Can't choose this one, it's hardcoded in the library  

// We store known ds18b20 sensor addresses here
struct sensor {
  byte             addr[8];
  struct sensor * next;
};

// Instantiate sensors
struct sensor *head = (struct sensor *) NULL;
struct sensor *end = (struct sensor *) NULL;
struct sensor *cur = (struct sensor *) NULL;

// DS18B20 Sensor nr1
// sensor1[8] = { 0x28, 0x99, 0xb4, 0xa9, 0x02, 0x00, 0x00, 0x1c };
// sensor2[8] = { 0x28, 0x3B, 0x9B, 0xa9, 0x02, 0x00, 0x00, 0xB9 };

int temp;

// Which pin is the 1w bus
OneWire ds(ONEWIREPIN);

byte step = 0;     // Which step in temperature-reading state machine are we

// To be used with arduino-tiny
// Set board to: Attiny85 @ 8 Mhz - Internal oscilator, BOD disabled
// Fuses: -U lfuse:w:0xe2:m -U hfuse:w:0xdf:m -U efuse:w:0xff:m
 
// DEBOUNCE time in milliseconds;
#define DEBOUNCE 250

// Sleep time between read loops
#define SAMPLEDELAY 10

// Not used anymore, but might need it in future
#define LOOP 4294967000

// Amount of ms per second, minute and hour;
// #define SECONDS 1000
// #define MINUTES 60 * SECONDS
// #define HOURS 60 * MINUTES

// What we consider HIGH and LOW values. This is a bit site dependant
// For EW: 1000 / 980
// For RS: ???? / ???

#define HV 1000
#define LV 900

void printsensoraddr(byte addr[8])
{
  byte i;
  for( i = 0; i<8; i++)
  {
    if (addr[i] < 0x10 )
    {
      Serial.print( "0" );
    }
    Serial.print( addr[i], HEX );
  }
}

struct sensor * initsensor( byte addr[8] )
{
   struct sensor *ptr;
   ptr = (struct sensor *) calloc( 1, sizeof(struct sensor ) );
   if( ptr == NULL )                       /* error allocating node?      */
   {
     Serial.println( "Calloc failed");
     return (struct sensor *) NULL;      /* then return NULL, else      */
   }
   else {                                  /* allocated node successfully */
       ptr->addr[0] = addr[0];
       ptr->addr[1] = addr[1];
       ptr->addr[2] = addr[2];
       ptr->addr[3] = addr[3];
       ptr->addr[4] = addr[4];
       ptr->addr[5] = addr[5];
       ptr->addr[6] = addr[6];
       ptr->addr[7] = addr[7];
       return ptr;                         /* return pointer to new node  */
   }
}

void addsensor( struct sensor *newsensor )  /* adding to end of list */
{
   if( head == NULL )      /* if there are no nodes in list, then         */
       head = newsensor;         /* set head to this new node                   */
   end->next = newsensor;        /* link in the new node to the end of the list */
   newsensor->next = NULL;       /* set next field to signify the end of list   */
   end = newsensor;              /* adjust end to point to the last node        */
}

void scan1w()
{
  byte addr[8];
  byte i;

  while( 1==1 )
  {
    if ( !ds.search(addr))
    {
//      Serial.println("Done scanning" );
      return;
    }
  
//    Serial.print( "F 1W: " );
//    printsensoraddr( addr );
//    Serial.println( "" );
    if ( OneWire::crc8( addr, 7) == addr[7] )
    {
      // CRC Valid
      if(( addr[0] != 0x28 ) && ( addr[0] != 0x10 ) )
      {
        // Check for DS18S20 (0x10) or DS18B20 (0x28)
        Serial.print( "Not a DS18(S/W)20 sensor: ");
        printsensoraddr( addr );
        Serial.println();
      }
      else
      {
        addsensor(initsensor(addr));
      }    
    }
    else
    {
      Serial.print( "Incalid crc on 1w sensor: ");
      printsensoraddr( addr);
      Serial.println();
    }
  }
}

/*
void printlist( struct sensor *ptr )
{
   byte i;
   Serial.println( "All detected sensors");
   while( ptr != NULL )           // continue whilst there are nodes left
   {
     printsensoraddr(ptr->addr);
     Serial.println("");
     ptr = ptr->next;            //goto the next node in the list       
   }
   Serial.println( "End" );
}
*/

// Setup serial port, wait a bit, and print that we are alive.
void setup() {
        Serial.begin(115200);
        delay( DEBOUNCE );
        Serial.println("Rebooted");
        pinMode(LEDPIN, OUTPUT );
        head = NULL;                  // Initialize sensor-list
        scan1w();                     // Scan for 1-wire temperature sensors
        cur = head;                   // Begin at the beginning
}

// The main loop, setup some basic variables, and loop again.
// These could be globals, and then we could skip the loop
// but I prefer this currently :P
void loop()
{
        unsigned long ignore = 0;    // Keep debounce time here
        unsigned long lastpulse = 0; // Millis value of last pulse;
        unsigned long thispulse = 0; // Millis value of current pulse;
        unsigned long thistime = 0;  // Millis value for this loop
        unsigned long mlasttime = 0; // Millis value for last full minute
        unsigned long hlasttime = 0; // Millis value for last full hour
        unsigned long sensortime = 0;// Millis value for last sensorloop run

        unsigned int hourcount = 0;  // Pulse count per hour        
        unsigned int mincount = 0;   // Pulse count per minute
        
        const unsigned int low = LV;
        const unsigned int high = HV;
        
        unsigned int value;          // Last value read
        
        while( 1 == 1)
        {
                thistime = millis(); // Get time for this loop
                
                if ( ( mlasttime + 60000 ) < thistime )
                {  // A minute (or more) has passed
                  mlasttime = thistime;
                  Serial.print( "Pulses last minute: ");
                  Serial.println( mincount );
                  mincount = 0;
                }
                if ( ( hlasttime + 3600000 ) < hlasttime )
                {
                  hlasttime = thistime;
                  Serial.print( "Pulses last hour: " );
                  Serial.println( hourcount );
                  hourcount = 0;
                }
                if ( ignore < thistime )
                {
                  digitalWrite( LEDPIN, LOW);
                }
               
                // read the analog input into a variable:
                // We read from pin A2 on the attiny85
                value = analogRead(A2);
//                Serial.println( value );
                
                // print the result:
                if ( value > high ) // No pulse detected
                {
//                    ignore = 0;  // Reset ignore/debounce;
//                    Serial.print( "Debug high: " );
//                    Serial.println(value); 
                }
                else if( value < low )  // Do we detect a PULSE
                {

//                  Serial.print( "Debug LOW: " );
//                  Serial.println(value); 

                  if ( thistime > ignore )    // Have we passed the debounce time...
                  {
                    digitalWrite(LEDPIN, HIGH);
                    lastpulse = thispulse;
                    thispulse = millis();
                    mincount++;    // Increment pulses seen this minute
                    hourcount++;   // Increment pulses seen this hour

                    if ( thispulse < lastpulse )
                    {
                      lastpulse = 0;    // In case it loops (50 days) 
                    }

                    Serial.print( "PULSE: t(" );
                    Serial.print( thistime );
                    Serial.print( "), value: " );
                    Serial.print( value );
                    Serial.print( " (" );
                    Serial.print( mincount ) ;
                    Serial.print( "/" );
                    Serial.print( hourcount );
                    Serial.println( ")" );
                    
                    ignore = thistime + DEBOUNCE;  // Set debounce time
                    Serial.print( "Time since laste pulse (in ms): " );
                    Serial.println( thispulse - lastpulse );
                  }
//                  else
//                  {
//                    Serial.println( "Still in debounce !!!!" ); 
//                  }
                }
//                else
//                {
//                  Serial.print( "Debug middle value: " );
//                  Serial.println( value );
//                }
                
                // We ignore values between > low and < high
                // as these are usually the rising or lowering edge
                // and we detected these in the previous or next cycle

                if (( sensortime + 1500 ) < thistime )
                {
                  sensorloop();
                  sensortime = thistime;
                }
                
                delay(SAMPLEDELAY);
        }
}

void prepare1w( byte dev[8] )
{
  ds.reset();
  ds.select(dev);
  ds.write(0x44,1);
}

int readtemp1w( byte dev[8] )
{
  int reading,tc100;
  byte data[2];  // Store temperature

  ds.reset();
  ds.select(dev);
  ds.write(0xBE);
  

  data[0] = ds.read();
  data[1] = ds.read();
  
  // Use tc100 as temporary counter
  for( tc100 = 2;tc100 < 9; tc100++ )
  {
    ds.read();
  }
  
  if (( data[0] == 0xFF ) && ( data[1] == 0xFF ) )
  {
    // Serial.println( "Bad temp received, retry" );
    return 0;
  }
  
  reading = ( data[1] << 8) + data[0];

  if ( reading == 1360 )
  {
    // Error value received
    return 0;
  }
  
  // Use tc100 still as temporary value
  // Check for negative
  tc100 = reading & 0x8000;
  if (tc100)
  {
    reading = -reading;
  }
  
  tc100 = ( 6 * reading ) + reading / 4; // Multiply with 6.25

  return tc100;
}

void sensorloop()
{
  if( cur == NULL )
    return;
    
  if ( step == 0 )
  {
    // Ask sensor for a read
    prepare1w(cur->addr); // Takes about 10 ms to call this
    step++;
    return;
  }
    
  if ( step == 1 )
  {
    // Read back and parse data
    temp = readtemp1w(cur->addr);
    step++;
    return;
  }
    
  if ( step == 2 )
  {
    byte i;

    if ( temp != 0 )
    {    
      Serial.print( "TEMP(" );
      printsensoraddr(cur->addr);
      Serial.print(") " );
      Serial.println( temp );
    }

    // Take next sensor and loop back to step 0
    if( cur->next == NULL )
    {
      cur = head;  // We were at the end, start over
    }
    else
    {    
      cur = cur->next;
    }
    step = 0;
    return;
  }
}
