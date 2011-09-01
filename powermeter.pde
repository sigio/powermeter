/*
 * Analog input, serial output
 * Reads an analog input pin, prints the results to the serial monitor.
 */

// To be used with arduino-tiny
// Set board to: Attiny85 @ 8 Mhz - Internal oscilator, BOD disabled
// Fuses: -U lfuse:w:0xe2:m -U hfuse:w:0xdf:m -U efuse:w:0xff:m
 
// DEBOUNCE time in milliseconds;
#define DEBOUNCE 100

// Sleep time between read loops
#define SAMPLEDELAY 10

// Not used anymore, but might need it in future
#define LOOP 4294967000

// What we consider HIGH and LOW values. This is a bit site dependant
#define HV 1000
#define LV 900

// Setup serial port, wait a bit, and print that we are alive.
void setup() {
        Serial.begin(115200);
        delay( DEBOUNCE );
        Serial.println("Rebooted");
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
               
                // read the analog input into a variable:
                // We read from pin A2 on the attiny85
                value = analogRead(A2);
                
                // print the result:
                if ( value > high ) // No pulse detected
                {
                    ignore = 0;  // Reset ignore/debounce;
//                    Serial.print( "Debug high: " );
//                    Serial.println(value); 
                }
                else if( value < low )  // Do we detect a PULSE
                {
//                  Serial.print( "Debug LOW: " );
//                  Serial.println(value); 

                  if ( thistime > ignore )    // Have we passed the debounce time...
                  {
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
                
                // wait SAMPLEDELAY milliseconds between read-attempts:
                delay(SAMPLEDELAY);
        }
}

