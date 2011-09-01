attiny85 based kwh-meter

	RST  -^- VCC
	TX   - - SCK
	READ - - MISO
	GND  - - MOSI

Connect to a cp2102 or pl2303 cable:

VCC (5V) to attiny85 VCC (3.3 or 5.0 volt)
RX to attiny85 TX (ttl levels)
GND to attiny85 GND

Wire the following sensor:
VCC --- 1K Ohm Resistor --- ATTINY READ PIN --- LDR Resistor --- GND

Then log everything from a system (pc/router/embedded board) serial port
and then put the data into rrdtool or something equivalent.
