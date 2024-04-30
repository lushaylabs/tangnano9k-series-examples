#!/bin/bash

# Start
echo "Running Formal Verification..."

# UART
echo "    uart"
sby -f uart.sby

# SCREEN
echo "    screen"
sby -f screen.sby

# TEXT
echo "    text"
sby -f text.sby

# ROWS
echo "    rows"
echo "        module uartTextRow()"
sby -f uartTextRow.sby
echo "        module progressRow()"
sby -f progressRow.sby
echo "        module hexDecRow()"
sby -f hexDecRow.sby