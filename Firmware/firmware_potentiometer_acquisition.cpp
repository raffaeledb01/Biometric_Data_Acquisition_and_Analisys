#include "mbed.h" 
#include <cstdio> 

// Define an analog input pin (A2) 
AnalogIn analog_value(A2); 
// Define a PWM output pin (D11)
 
PwmOut output(D11); 

int main(){ 

	float meas;  // Variable to store the measured value
 
	// Set the PWM period to 0.1 seconds 
	output.period(0.1); 

	while(1){ 

		// Read the analog input (returns a value between 0.0 and 1.0) 
		meas = analog_value.read(); 

		// Set the PWM duty cycle based on the measured value 
		output.write(meas); 

		// Convert the value to millivolts (assuming a 3.3V reference) 
		meas = 3300 * meas; 

		// Print the measured value in millivolts 
		printf("%0.1f \r\n", meas); 
	} 
} 