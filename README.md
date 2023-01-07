# Tang Nano 9K Examples

This repository contains all the example projects for the tang nano 

### Counter
Introduction project from Part 1 of the TangNano9K series full article can be found [here](https://learn.lushaylabs.com/getting-setup-with-the-tang-nano-9k/)

### UART
UART module to send and receive data from the tang nano 9k using the onboard RV debugger, full article can be found [here](https://learn.lushaylabs.com/tang-nano-9k-debugging/)

### Screen
Contains a core to interface with a 0.96" Oled display, full article can be found [here](https://learn.lushaylabs.com/tang-nano-9k-graphics/)

### Text Engine
Continues the screen core and adds a module which converts text to pixels using a font file, full article can be found [here](https://learn.lushaylabs.com/tang-nano-9k-creating-a-text-engine/)

### Data Visualization
Different ways of converting binary numbers into visual representations that can be displayed to our OLED display, full article can be found [here](https://learn.lushaylabs.com/tang-nano-9k-data-visualization/) 

### Flash Hex Navigator
Article that goes over reading data from the onboard flash storage showing how to program the flash and building a flash navigator module which let's us navigate the memory displaying segments of the storage on screen in hex format. Full article can be found [here](https://learn.lushaylabs.com/tang-nano-9k-reading-the-external-flash/)

### Random Scrolling Graph
Article that goes through the process of generating pseudo "random" numbers using LFSRs and plotting them to the screen creating a scrolling graph. Full article can be found [here](https://learn.lushaylabs.com/tang-nano-9k-generating-random/)

### Arbiter
Implements a memory controller allowing for three modules to share a common memory. Full article can be found here [here](https://learn.lushaylabs.com/tang-nano-9k-sharing-resources/)

### I2C ADC (ADS1115)
Example project using 2 channels out of the 4 on the 16-bit ADC. This project reads two analog values and displays them on screen in both raw format and in volts. Full article can be found [here](https://learn.lushaylabs.com/i2c-adc-micro-procedures/)

### CPU Core
Project where we implement our first CPU, this project implements a basic instruction set as well as an assembler for compiling programs into bytecode to be run on the CPU core. Full article can be found [here](https://learn.lushaylabs.com/tang-nano-9k-first-processor/)