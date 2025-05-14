#include "mbed.h" 
#include <cstdint> 
#include <cstdio> 
 
// Sensor I2C address 
#define SENSOR_ADDRESS 0xD6 
 
// Register addresses 
#define WHO_AM_I 0x0F 
#define CTRL1_XL 0x10 
#define POWER_DOWN 0x0000 
#define ODR_12Hz 0b00010000 // Output data rate 12Hz 
#define FS_2G 0b00000000    // ±2g range 
#define FS_4G 0b00010000    // ±4g range 
#define FS_8G 0b00011000    // ±8g range 
#define FS_16G 0b00000100   // ±16g range 
 
// Sensitivity values (mg/LSB) 
#define SENS_2G 0.061 
#define SENS_4G 0.122 
#define SENS_8G 0.244 
#define SENS_16G 0.732 
 
// Output registers for acceleration 
#define OUTX_L_XL 0x28 
#define OUTX_H_XL 0x29 
#define OUTY_L_XL 0x2A 
#define OUTY_H_XL 0x2B 
#define OUTZ_L_XL 0x2C 
#define OUTZ_H_XL 0x2D 
 
// Output registers for temperature (unused) 
#define OUT_TEMP_L 0x20 
#define OUT_TEMP_H 0x21 
 
// Terminal clear command 
#define CLEAR "\f\033[?25I" 
 
// Initialize I2C communication 
I2C i2c(I2C_SDA, I2C_SCL); 
 
// Function to read a register from the accelerometer 
char read_reg(char reg_address) { 
    char data_write[1]; 
    char data_read[1]; 
    data_write[0] = reg_address; 
 
    // Send register address and read back value 
    i2c.write(SENSOR_ADDRESS, data_write, 1, 0); 
    i2c.read(SENSOR_ADDRESS, data_read, 1, 0); 
 
    return data_read[0]; 
} 
 
// Function to write a value to a register 
void write_reg(char reg_address, char data) { 
    char data_write[2]; 
    data_write[0] = reg_address; 
    data_write[1] = data; 
 
    // Send register address and data 
    i2c.write(SENSOR_ADDRESS, data_write, 2, 0); 
} 
 
int main() { 
    // Clear terminal and print a new line 
    printf(CLEAR "\n\r"); 
 
    char value; 
    short buf[4]; 
    float a = SENS_2G, x = 0, y = 0, z = 0; 
 
    // Read "Who am I?" register to check sensor identity 
    value = read_reg(WHO_AM_I); 
    printf("Who am I? %X \n\r", value); 
 
    // Configure accelerometer: 12Hz output rate, ±2g range 
    write_reg(CTRL1_XL, ODR_12Hz | FS_2G); 
 
    // Start timer to limit execution to 10 seconds 
    Timer timer; 
    timer.start(); 
 
    // Read accelerometer data for 10 seconds 
    while (timer.read() < 10.0) { 
        // Read acceleration X-axis 
        buf[0] = read_reg(OUTX_H_XL); 
        buf[0] <<= 8; 
        buf[0] |= read_reg(OUTX_L_XL); 
 
        // Read acceleration Y-axis 
        buf[1] = read_reg(OUTY_H_XL); 
        buf[1] <<= 8; 
        buf[1] |= read_reg(OUTY_L_XL); 
 
        // Read acceleration Z-axis 
        buf[2] = read_reg(OUTZ_H_XL); 
        buf[2] <<= 8; 
        buf[2] |= read_reg(OUTZ_L_XL); 
 
        // Convert raw data to acceleration values in mg 
        x = buf[0] * a; 
        y = buf[1] * a; 
        z = buf[2] * a; 
 
        // Print acceleration data 
        printf(" ACC(xyz):%.1f %.1f %.1f \n\r", x, y, z); 
    } 
 
    // Print end message 
    printf("------------------------End of Walk ---------------------------------"); 