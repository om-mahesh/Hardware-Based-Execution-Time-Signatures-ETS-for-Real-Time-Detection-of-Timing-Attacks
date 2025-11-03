# Vivado TCL Build Script for ETS RISC-V Project
# Usage: vivado -mode batch -source build.tcl

set project_name "ets_riscv"
set project_dir "vivado_project"
set part "xc7z010clg400-1"

puts "=========================================="
puts "ETS RISC-V Project Build Script"
puts "=========================================="

# Create project
puts "Creating project: $project_name"
create_project $project_name $project_dir -part $part -force

# Add RTL sources
puts "Adding RTL sources..."
add_files -norecurse {
    rtl/ets_module/cycle_counter.v
    rtl/ets_module/signature_db.v
    rtl/ets_module/comparator.v
    rtl/ets_module/alert_controller.v
    rtl/ets_module/ets_monitor.v
    rtl/uart/uart_tx.v
    rtl/uart/uart_interface.v
    rtl/top/ets_riscv_top.v
    rtl/top/zybo_z7_top.v
}

# Add PicoRV32 (if available)
if {[file exists "rtl/riscv_core/picorv32/picorv32.v"]} {
    puts "Adding PicoRV32 core..."
    add_files -norecurse rtl/riscv_core/picorv32/picorv32.v
} else {
    puts "WARNING: PicoRV32 not found at rtl/riscv_core/picorv32/"
    puts "Please run: cd rtl/riscv_core && git clone https://github.com/YosysHQ/picorv32.git"
}

# Add constraints
puts "Adding constraints..."
add_files -fileset constrs_1 -norecurse constraints/zybo_z7.xdc

# Set top module
set_property top zybo_z7_top [current_fileset]

# Set Verilog version
set_property file_type {Verilog} [get_files *.v]

# Update compile order
update_compile_order -fileset sources_1

puts "\n=========================================="
puts "Running Synthesis..."
puts "=========================================="
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check synthesis status
set synth_status [get_property STATUS [get_runs synth_1]]
puts "Synthesis status: $synth_status"

if {$synth_status != "synth_design Complete!"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}

# Open synthesized design and report
open_run synth_1
puts "\nSynthesis Utilization:"
puts "=========================================="
report_utilization -file $project_dir/utilization_synth.rpt
report_utilization

puts "\n=========================================="
puts "Running Implementation..."
puts "=========================================="
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Check implementation status
set impl_status [get_property STATUS [get_runs impl_1]]
puts "Implementation status: $impl_status"

if {$impl_status != "write_bitstream Complete!"} {
    puts "ERROR: Implementation failed!"
    exit 1
}

# Open implemented design and generate reports
open_run impl_1
puts "\nImplementation Utilization:"
puts "=========================================="
report_utilization -file $project_dir/utilization_impl.rpt
report_utilization

puts "\nTiming Summary:"
puts "=========================================="
report_timing_summary -file $project_dir/timing.rpt
report_timing_summary -max_paths 10

puts "\nPower Report:"
puts "=========================================="
report_power -file $project_dir/power.rpt

# Copy bitstream to project root
file copy -force $project_dir/$project_name.runs/impl_1/zybo_z7_top.bit ./zybo_z7_top.bit

puts "\n=========================================="
puts "Build Complete!"
puts "=========================================="
puts "Bitstream: zybo_z7_top.bit"
puts "Reports:"
puts "  - Utilization: $project_dir/utilization_impl.rpt"
puts "  - Timing:      $project_dir/timing.rpt"
puts "  - Power:       $project_dir/power.rpt"
puts "=========================================="

