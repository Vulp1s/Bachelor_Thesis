#!/bin/bash

# Configuration
BAUD="1500000"
# Automatically find the USB serial adapter
DEVICE=$(ls /dev/ttyUSB* 2>/dev/null | head -n 1)

if [ -z "$DEVICE" ]; then
    echo "Error: No USB Serial adapter found!"
    exit 1
fi

echo "Launching Minicom on $DEVICE at $BAUD baud..."
# -D: specify device
# -b: specify baud rate
# -o: skip initialization
# -w: wrap long lines
minicom -D "$DEVICE" -b "$BAUD" -o -w
