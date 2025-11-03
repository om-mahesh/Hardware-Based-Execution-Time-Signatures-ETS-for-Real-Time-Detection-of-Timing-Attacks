# ETS RISC-V Quick Start Guide

Get your ETS-enhanced RISC-V processor running on Zybo Z7-10 in 30 minutes!

## Prerequisites

- **Zybo Z7-10** FPGA board
- **Vivado** 2020.1 or later (with cable drivers)
- **Git** for cloning repositories
- **Python 3.8+** for build scripts
- **RISC-V GCC Toolchain** (we'll install this)

---

## Step 1: Clone PicoRV32 Core (5 minutes)

```bash
cd rtl
mkdir -p riscv_core
cd riscv_core
git clone https://github.com/YosysHQ/picorv32.git
cd ../..
```

**Verify**: You should now have `rtl/riscv_core/picorv32/picorv32.v`

---

## Step 2: Install RISC-V Toolchain (10 minutes)

### Option A: Automated Script

```bash
cd software/toolchain
chmod +x setup_toolchain.sh
./setup_toolchain.sh
source env.sh
```

### Option B: Manual Download

Download from: https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/

Extract to `software/toolchain/riscv-toolchain/`

**Verify**:
```bash
riscv-none-elf-gcc --version
```

---

## Step 3: Build Test Firmware (5 minutes)

```bash
cd software/firmware/tests
make
```

This creates:
- `test_basic.hex` - Basic ETS test
- `test_anomaly.hex` - Anomaly detection test
- `test_learning.hex` - Learning mode test

**Verify**: You should see `.hex` files in the tests directory.

---

## Step 4: Simulate (Optional, 5 minutes)

```bash
cd sim

# Using Icarus Verilog (free)
iverilog -o tb_ets tb_ets_monitor.v ../rtl/ets_module/*.v
vvp tb_ets
gtkwave tb_ets_monitor.vcd

# OR using Vivado simulator
vivado -mode batch -source run_sim.tcl
```

---

## Step 5: Build FPGA Bitstream (15 minutes)

### Option A: TCL Script (Recommended)

```bash
vivado -mode batch -source build.tcl
```

Output: `zybo_z7_top.bit`

### Option B: Vivado GUI

1. Open Vivado
2. **File → Project → New**
3. Follow wizard:
   - Part: `xc7z010clg400-1`
   - Add sources: `rtl/**/*.v`
   - Add constraints: `constraints/zybo_z7.xdc`
4. **Run Synthesis** → **Run Implementation** → **Generate Bitstream**

**Expected Results**:
- Utilization: ~15% LUTs, ~5% FFs, ~13% BRAM
- Timing: Should meet 125 MHz constraint (or reduce clock if needed)

---

## Step 6: Program FPGA (5 minutes)

### Connect Hardware

1. Connect Zybo Z7-10 to PC via USB (PROG/UART port)
2. Power on board (flip power switch)
3. Set jumper JP5 to "JTAG" mode

### Program Bitstream

**Via Vivado**:
1. Open Vivado
2. **Flow → Open Hardware Manager**
3. **Open target → Auto Connect**
4. **Program device** → Select `zybo_z7_top.bit`

**Via Command Line**:
```bash
vivado -mode batch -source program.tcl
```

---

## Step 7: Test & Verify

### Visual Indicators

After programming, you should see:

- **LED3 (Green)**: Blinking at ~1 Hz (heartbeat) ✓
- **LED2 (Orange)**: Flickering (CPU active) ✓
- **LED1 (Red)**: Off (no anomalies detected yet) ✓
- **LED0 (Yellow)**: Off (no ETS alerts) ✓

### Test Anomaly Detection

1. Press **BTN2** to inject test anomaly
2. **LED1** should turn on (anomaly detected)
3. **LED0** should turn on (alert active)

**Success!** Your ETS system is working!

---

## Step 8: Advanced Testing (Optional)

### Monitor with Logic Analyzer

Connect logic analyzer to **Pmod JE** header:
- JE1: ETS interrupt
- JE2: Instruction valid
- JE3: Instruction done
- JE4: Anomaly detected

### UART Console (Future)

```bash
# Linux
screen /dev/ttyUSB1 115200

# Windows
putty COM3 -serial -sercfg 115200,8,n,1,N
```

### Modify Firmware

1. Edit `software/firmware/tests/test_basic.c`
2. Rebuild: `make`
3. Update memory initialization in Vivado
4. Reprogram FPGA

---

## Troubleshooting

### Issue: "PicoRV32 not found"

**Solution**: Run step 1 to clone PicoRV32

### Issue: "Synthesis failed"

**Solutions**:
- Check Vivado version (2020.1+)
- Verify all files added to project
- Check console for specific errors

### Issue: "Timing violations"

**Solutions**:
1. Reduce clock frequency in XDC:
   ```tcl
   create_clock -period 10.000 [get_ports clk]  # 100 MHz
   ```
2. Add timing constraints for ETS paths

### Issue: "LEDs not blinking"

**Checklist**:
- Power switch ON?
- Bitstream programmed successfully?
- Press BTN0 (reset) and try again
- Check ILA traces in Vivado

---

## What's Next?

### Customize ETS Parameters

Edit `rtl/ets_module/ets_monitor.v` to adjust:
- Signature database size (default: 64 entries)
- Tolerance thresholds
- Alert behavior

### Add More Test Programs

Create new tests in `software/firmware/tests/`:
```c
#include "../common/ets_lib.h"

void my_secure_function(void) {
    ets_enable(true);
    // Your crypto/security code here
    if (ets_get_anomaly_count() > 0) {
        // Attack detected!
    }
}
```

### Integrate with IoT Application

Use ETS to protect:
- AES encryption
- RSA signature verification
- Password checking
- Secure boot

### Performance Tuning

- Profile instruction timings
- Build comprehensive signature database
- Optimize tolerance thresholds
- Reduce false positive rate

---

## Resources

- **Project Documentation**: See `docs/` folder
- **PicoRV32 Docs**: https://github.com/YosysHQ/picorv32
- **Zybo Z7 Manual**: https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual
- **RISC-V Spec**: https://riscv.org/technical/specifications/

---

## Support

If you encounter issues:

1. Check `docs/zybo_z7_guide.md` for detailed troubleshooting
2. Review Vivado synthesis/implementation reports
3. Simulate with testbench (`sim/tb_ets_monitor.v`)
4. Check pin assignments in `constraints/zybo_z7.xdc`

---

**Congratulations!** You now have a working ETS-enhanced RISC-V processor! 🎉

Explore the codebase, modify the ETS parameters, and protect your IoT applications from timing attacks!

