# TCL script to program Zybo Z7-10 FPGA
# Usage: vivado -mode batch -source program.tcl

set bitstream "zybo_z7_top.bit"

if {![file exists $bitstream]} {
    puts "ERROR: Bitstream file not found: $bitstream"
    puts "Please run build.tcl first to generate the bitstream"
    exit 1
}

puts "=========================================="
puts "Programming Zybo Z7-10 FPGA"
puts "=========================================="
puts "Bitstream: $bitstream"
puts ""

# Open hardware manager
open_hw_manager

# Connect to hardware server
puts "Connecting to hardware server..."
connect_hw_server -url localhost:3121 -allow_non_jtag

# Open target
puts "Opening hardware target..."
open_hw_target

# Get all devices and find the FPGA
set all_devices [get_hw_devices]
puts "Available devices: $all_devices"

# Find the FPGA device (xc7z010_1)
set fpga_device ""
foreach dev $all_devices {
    if {[string match "*xc7z010*" $dev]} {
        set fpga_device $dev
        break
    }
}

if {$fpga_device == ""} {
    puts "ERROR: FPGA device xc7z010 not found!"
    puts "Available devices: $all_devices"
    exit 1
}

puts "Target FPGA device: $fpga_device"

# Set bitstream
puts "Setting bitstream..."
set_property PROGRAM.FILE $bitstream [get_hw_devices $fpga_device]

# Program device
puts "Programming FPGA..."
program_hw_devices [get_hw_devices $fpga_device]

# Refresh device
puts "Refreshing device..."
refresh_hw_device [get_hw_devices $fpga_device]

puts ""
puts "=========================================="
puts "Programming Complete!"
puts "=========================================="
puts "Check LEDs on Zybo Z7-10:"
puts "  LED3: Should blink (heartbeat)"
puts "  LED2: Should flicker (CPU active)"
puts "=========================================="

# Close hardware manager
close_hw_manager

exit 0

