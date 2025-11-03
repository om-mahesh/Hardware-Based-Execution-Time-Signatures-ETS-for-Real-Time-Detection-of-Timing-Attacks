# Zybo Z7-10 Implementation Guide

## Board Specifications

### Zynq-7000 SoC
- **Part Number**: XC7Z010-1CLG400C
- **Architecture**: Dual-core ARM Cortex-A9 + FPGA fabric
- **FPGA Logic**: 28,000 logic cells (17,600 LUTs, 35,200 FFs)
- **Block RAM**: 2.1 Mb (60 × 36Kb BRAMs)
- **DSP Slices**: 80
- **Clock**: 125 MHz oscillator

### Memory
- **DDR3**: 512 MB (PS side, not used in this project)
- **Flash**: 16 MB Quad-SPI
- **MicroSD**: Card slot for storage

### I/O
- **LEDs**: 4 user LEDs
- **Switches**: 4 slide switches
- **Buttons**: 4 push buttons
- **UART**: USB-UART bridge (115200 baud)
- **Pmod**: 6 Pmod connectors (GPIO expansion)

---

## Implementation Strategy

### Option 1: Pure PL (FPGA Fabric) Implementation ⭐ RECOMMENDED

**What we're doing**: Implement RISC-V + ETS entirely in programmable logic, ignore ARM cores.

**Advantages**:
- ✅ Full control over timing
- ✅ Simpler - no PS-PL interaction
- ✅ Better for ETS timing precision
- ✅ Easier debugging with ILA

**Resource Usage**:
| Component | LUTs | FFs | BRAMs |
|-----------|------|-----|-------|
| PicoRV32 | ~2000 | ~1500 | 2-4 |
| ETS Module | ~500 | ~300 | 2 |
| Memory (16KB) | - | - | 4 |
| Peripherals | ~200 | ~100 | 0 |
| **Total** | **~2700** | **~1900** | **8** |
| **Available** | 17,600 | 35,200 | 60 |
| **Utilization** | 15% | 5% | 13% |

**Conclusion**: Plenty of headroom!

---

### Option 2: Hybrid (ARM + RISC-V)

Use ARM cores for control/monitoring, RISC-V in PL for crypto/secure tasks.

**Not recommended for this project** - adds complexity without benefit.

---

## Vivado Project Setup

### Step 1: Create Project

```tcl
# Open Vivado 2020.1 or later
# Create new project:
#   Project name: ets_riscv
#   Location: <your_workspace>/time_bound_processor
#   Project type: RTL Project
#   Part: xc7z010clg400-1
```

### Step 2: Add Source Files

Add these files to the project:

**RTL Sources**:
```
rtl/ets_module/cycle_counter.v
rtl/ets_module/signature_db.v
rtl/ets_module/comparator.v
rtl/ets_module/alert_controller.v
rtl/ets_module/ets_monitor.v
rtl/top/ets_riscv_top.v
rtl/top/zybo_z7_top.v (set as top module)
```

**Constraints**:
```
constraints/zybo_z7.xdc
```

**Memory Initialization** (optional):
```
software/firmware/tests/test_basic.hex
```

### Step 3: Synthesize & Implement

```tcl
# Run synthesis
launch_runs synth_1
wait_on_run synth_1

# Check resource utilization
open_run synth_1
report_utilization

# Run implementation
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

# Check timing
open_run impl_1
report_timing_summary
report_utilization
```

### Step 4: Generate Bitstream

```tcl
# Bitstream is generated in:
# ets_riscv.runs/impl_1/zybo_z7_top.bit

# Program FPGA
open_hw_manager
connect_hw_server
open_hw_target
set_property PROGRAM.FILE {ets_riscv.runs/impl_1/zybo_z7_top.bit} [get_hw_devices xc7z010_1]
program_hw_devices [get_hw_devices xc7z010_1]
```

---

## TCL Build Script

Create `build.tcl` for automated builds:

```tcl
# Build script for ETS RISC-V project

# Set project name and directory
set project_name "ets_riscv"
set project_dir "vivado_project"

# Create project
create_project $project_name $project_dir -part xc7z010clg400-1 -force

# Add RTL sources
add_files -norecurse {
    rtl/ets_module/cycle_counter.v
    rtl/ets_module/signature_db.v
    rtl/ets_module/comparator.v
    rtl/ets_module/alert_controller.v
    rtl/ets_module/ets_monitor.v
    rtl/top/ets_riscv_top.v
    rtl/top/zybo_z7_top.v
}

# Add constraints
add_files -fileset constrs_1 -norecurse constraints/zybo_z7.xdc

# Set top module
set_property top zybo_z7_top [current_fileset]

# Run synthesis
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Run implementation
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Reports
open_run impl_1
report_utilization -file vivado_project/utilization.rpt
report_timing_summary -file vivado_project/timing.rpt

puts "Build complete!"
puts "Bitstream: $project_dir/ets_riscv.runs/impl_1/zybo_z7_top.bit"
```

Run with:
```bash
vivado -mode batch -source build.tcl
```

---

## Pin Mapping

### Clock & Reset
| Signal | Pin | Bank | Notes |
|--------|-----|------|-------|
| `clk` | K17 | 35 | 125 MHz oscillator |
| `rst_n` | K18 | 35 | BTN0 (active low) |

### LEDs (Status)
| Signal | Pin | Bank | Function |
|--------|-----|------|----------|
| `ets_alert_flag` | M14 | 34 | LED0: ETS alert active |
| `dbg_anomaly` | M15 | 34 | LED1: Anomaly detected |
| `led_active` | G14 | 35 | LED2: CPU active |
| `led_heartbeat` | D18 | 35 | LED3: Heartbeat (1 Hz) |

### Switches
| Signal | Pin | Bank | Function |
|--------|-----|------|----------|
| `sw_ets_enable` | G15 | 35 | SW0: Enable ETS |
| `sw_learning_mode` | P15 | 34 | SW1: Learning mode |

### Pmod JE (Debug)
| Signal | Pin | Bank | Function |
|--------|-----|------|----------|
| `pmod_ets_irq` | V12 | 34 | ETS interrupt |
| `pmod_instr_valid` | W16 | 13 | Instruction valid |
| `pmod_instr_done` | J15 | 13 | Instruction done |
| `pmod_anomaly` | H15 | 13 | Anomaly flag |

**Use Pmod signals with logic analyzer for debugging!**

---

## Programming the FPGA

### Via Vivado Hardware Manager (GUI)

1. Open Vivado → **Open Hardware Manager**
2. Click **Open target** → **Auto Connect**
3. **Program device** → Select bitstream file
4. Click **Program**

### Via Command Line (TCL)

```tcl
open_hw_manager
connect_hw_server
open_hw_target
set_property PROGRAM.FILE {path/to/zybo_z7_top.bit} [get_hw_devices xc7z010_1]
program_hw_devices [get_hw_devices xc7z010_1]
close_hw_manager
```

### Via xsdb (Xilinx Software Command-Line Tool)

```bash
xsdb
connect
targets
fpga path/to/zybo_z7_top.bit
exit
```

---

## Debugging

### Integrated Logic Analyzer (ILA)

Add ILA core to probe internal signals:

```tcl
# In Vivado, add ILA IP
create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_0

# Configure probes
set_property -dict [list \
  CONFIG.C_NUM_OF_PROBES {8} \
  CONFIG.C_PROBE0_WIDTH {32} \
  CONFIG.C_PROBE1_WIDTH {1} \
] [get_ips ila_0]
```

Probe these signals:
- `instr_pc[31:0]` - Program counter
- `instr_valid` - Instruction executing
- `dbg_cycle_count[31:0]` - Current cycle count
- `dbg_anomaly_detected` - Anomaly flag

### UART Console (Future)

Connect USB cable to Zybo, use serial terminal (115200 baud):
```bash
# Linux
screen /dev/ttyUSB1 115200

# Windows
putty COM3 -serial -sercfg 115200,8,n,1,N
```

---

## Performance Tuning

### Clock Frequency Optimization

Default: 125 MHz (8 ns period)

To reduce frequency for easier timing closure:
```verilog
// Add clock divider in zybo_z7_top.v
reg [1:0] clk_div;
always @(posedge clk) clk_div <= clk_div + 1;
wire sys_clk = clk_div[1];  // 31.25 MHz
```

### Pipeline ETS Monitoring

If ETS adds critical path delay, pipeline the comparator:
```verilog
// In comparator.v, add extra register stage
always @(posedge clk) begin
    anomaly_detected_reg <= (actual > upper) || (actual < lower);
end
assign anomaly_detected = anomaly_detected_reg;
```

---

## Troubleshooting

### Issue: Synthesis Errors

**Problem**: Undefined signals in PicoRV32 integration

**Solution**: Make sure PicoRV32 is cloned and added to project:
```bash
cd rtl/riscv_core
git clone https://github.com/YosysHQ/picorv32.git
```

Add `picorv32.v` to Vivado project sources.

---

### Issue: Timing Violations

**Problem**: Setup/hold violations reported

**Solutions**:
1. Reduce clock frequency (add divider)
2. Pipeline ETS comparator (add register stage)
3. Adjust timing constraints in XDC file:
   ```tcl
   create_clock -period 10.000 [get_ports clk]  # 100 MHz instead of 125
   ```

---

### Issue: LEDs Not Blinking

**Problem**: Bitstream loaded but no activity

**Checklist**:
1. ✓ Reset button (BTN0) pressed?
2. ✓ Clock constraint in XDC correct?
3. ✓ Memory initialized with valid program?
4. ✓ Check ILA traces for activity

---

## Next Steps

1. **Integrate PicoRV32**: See `docs/risc_v_selection.md`
2. **Compile firmware**: See `software/firmware/tests/Makefile`
3. **Run simulation**: See `sim/tb_ets_monitor.v`
4. **Build bitstream**: Use `build.tcl` script
5. **Program FPGA**: Load bitstream via Hardware Manager
6. **Test ETS**: Observe LEDs, Pmod debug outputs

---

## Resources

- **Zybo Z7 Reference Manual**: https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual
- **Zybo Z7 Schematic**: https://digilent.com/reference/_media/reference/programmable-logic/zybo-z7/zybo-z7-sch.pdf
- **Vivado User Guide**: UG893 (Vivado Design Suite User Guide)
- **PicoRV32 Documentation**: https://github.com/YosysHQ/picorv32

---

**Happy Hacking!** 🚀

