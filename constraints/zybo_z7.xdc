# Zybo Z7-10 Constraints for ETS RISC-V Processor
# Board: Digilent Zybo Z7-10 (XC7Z010-1CLG400C)
# Reference: https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual

###############################################################################
# Clock
###############################################################################
# 125 MHz system clock
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 8.000 -name sys_clk [get_ports clk]

###############################################################################
# Reset Button
###############################################################################
# BTN0 - Active LOW reset
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports rst_n]
set_property PULLUP true [get_ports rst_n]

###############################################################################
# LEDs - For ETS Status
###############################################################################
# LED0 - ETS Alert Flag
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports ets_alert_flag]

# LED1 - Debug: Anomaly Detected
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports dbg_anomaly]

# LED2 - Debug: System Active
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports led_active]

# LED3 - Debug: Heartbeat
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports led_heartbeat]

###############################################################################
# Switches - For Configuration
###############################################################################
# SW0 - Enable ETS monitoring
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports sw_ets_enable]

# SW1 - ETS Learning Mode
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports sw_learning_mode]

###############################################################################
# Buttons - For Control
###############################################################################
# BTN1 - Clear ETS counters
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports btn_clear_ets]

# BTN2 - Trigger test anomaly
set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS33} [get_ports btn_test_anomaly]

###############################################################################
# UART - For Console/Debugging (PS side - not used in PL-only design)
###############################################################################
# NOTE: UART is on PS side of Zynq, not available for PL-only design
# Commented out to avoid placement errors
# set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports uart_tx]
# set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports uart_rx]

###############################################################################
# Pmod Header JA - UART TX Output
###############################################################################
# JA1 - UART TX (connect to USB-UART adapter RX pin)
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports uart_tx]

###############################################################################
# Pmod Header JE - For External Debug/Logic Analyzer
###############################################################################
# JE1 - ETS Alert Interrupt (debug)
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports pmod_ets_irq]

# JE2 - Instruction Valid (debug)
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33} [get_ports pmod_instr_valid]

# JE3 - Instruction Done (debug)
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports pmod_instr_done]

# JE4 - Anomaly Detected (debug)
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports pmod_anomaly]

###############################################################################
# Timing Constraints
###############################################################################
# Input delays for asynchronous inputs
set_input_delay -clock [get_clocks sys_clk] -min 0.000 [get_ports rst_n]
set_input_delay -clock [get_clocks sys_clk] -max 2.000 [get_ports rst_n]

set_input_delay -clock [get_clocks sys_clk] -min 0.000 [get_ports sw_*]
set_input_delay -clock [get_clocks sys_clk] -max 2.000 [get_ports sw_*]

set_input_delay -clock [get_clocks sys_clk] -min 0.000 [get_ports btn_*]
set_input_delay -clock [get_clocks sys_clk] -max 2.000 [get_ports btn_*]

# Output delays
set_output_delay -clock [get_clocks sys_clk] -min -1.000 [get_ports led_*]
set_output_delay -clock [get_clocks sys_clk] -max 2.000 [get_ports led_*]

set_output_delay -clock [get_clocks sys_clk] -min -1.000 [get_ports ets_*]
set_output_delay -clock [get_clocks sys_clk] -max 2.000 [get_ports ets_*]

set_output_delay -clock [get_clocks sys_clk] -min -1.000 [get_ports pmod_*]
set_output_delay -clock [get_clocks sys_clk] -max 2.000 [get_ports pmod_*]

set_output_delay -clock [get_clocks sys_clk] -min -1.000 [get_ports uart_tx]
set_output_delay -clock [get_clocks sys_clk] -max 2.000 [get_ports uart_tx]

# False paths for asynchronous resets
set_false_path -from [get_ports rst_n] -to [all_registers]

###############################################################################
# Configuration
###############################################################################
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

###############################################################################
# Additional Constraints for ETS Timing
###############################################################################
# ETS monitoring should not add critical path delay
# Set multicycle path for ETS register access (non-critical)
set_multicycle_path -setup 2 -from [get_pins ets_*/reg_*] -to [get_pins ets_*/comparator/*]
set_multicycle_path -hold 1 -from [get_pins ets_*/reg_*] -to [get_pins ets_*/comparator/*]

# Cycle counter is synchronous to instruction execution
set_max_delay -from [get_pins */cycle_counter/counter_reg*] -to [get_pins */comparator/actual_*] 5.000

