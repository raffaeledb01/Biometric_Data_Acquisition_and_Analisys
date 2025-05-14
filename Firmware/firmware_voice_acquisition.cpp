#include "mbed.h" 
#include <vector> 
 
// Define an analog input for the microphone (A1) 
AnalogIn analog_value(A1); 
 
// Number of samples to acquire 
#define NUM_ACQUISIZIONI 8000 
 
// Timer to measure the total acquisition time 
Timer t; 
 
// Array to store the acquired samples 
uint16_t misure[NUM_ACQUISIZIONI]; 
 
int main() { 
 
    // Start the timer 
    t.start(); 
 
    // Acquire 8000 samples from the microphone 
    for (int i = 0; i < NUM_ACQUISIZIONI; i++) { 
        misure[i] = analog_value.read_u16();  // Read 16-bit analog value 
        wait_us(250); // Wait 250 microseconds (sample rate ~4 kHz) 
    } 
 
    // Stop the timer 
    t.stop(); 
 
    // Print acquired data in millivolts 
    for (int i = 0; i < NUM_ACQUISIZIONI; i++) { 
        printf("%d\n", misure[i] * 3300 / 65535); 
    } 
 
    // Print the total acquisition time 
    printf("Tempo totale: %f secondi\n\r", t.read()); 
} 
