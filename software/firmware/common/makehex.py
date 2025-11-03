#!/usr/bin/env python3
"""
makehex.py

Converts binary firmware file to Verilog hex format for memory initialization.
Usage: python3 makehex.py firmware.bin > firmware.hex
"""

import sys

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 makehex.py <binary_file>", file=sys.stderr)
        sys.exit(1)
    
    binary_file = sys.argv[1]
    
    try:
        with open(binary_file, 'rb') as f:
            data = f.read()
    except FileNotFoundError:
        print(f"Error: File '{binary_file}' not found", file=sys.stderr)
        sys.exit(1)
    
    # Pad to word boundary
    while len(data) % 4 != 0:
        data += b'\x00'
    
    # Convert to 32-bit words and output as hex
    for i in range(0, len(data), 4):
        word = data[i:i+4]
        # Little-endian format
        value = (word[0] | (word[1] << 8) | (word[2] << 16) | (word[3] << 24))
        print(f"{value:08x}")

if __name__ == "__main__":
    main()

