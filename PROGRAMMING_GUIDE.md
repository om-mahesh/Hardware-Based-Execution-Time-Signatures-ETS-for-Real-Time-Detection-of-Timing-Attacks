# 🎯 ZYBO Z7-10 PROGRAMMING GUIDE

## Quick Reference for After Build Completes

---

## ✅ Pre-Programming Checklist

Before programming your board, verify:

- [ ] **Bitstream exists**: `zybo_z7_top.bit` file created
- [ ] **Board powered ON**: Power switch in ON position
- [ ] **USB connected**: Micro-USB cable to PROG/UART port
- [ ] **Jumper JP5**: Set to "JTAG" mode (factory default)
- [ ] **Power LED**: Green LED near power jack is lit

---

## 🔌 Board Connections

### Physical Setup
```
[PC USB] ──┬──> [Zybo PROG/UART] (Programming)
           └──> [Optional: UART Console]

[Power Adapter] ──> [Zybo Power Jack] (12V, 3A recommended)
```

### LED Positions (After Programming)
```
┌─────────────────────┐
│  LD3  LD2  LD1  LD0 │  ← User LEDs
│   🟢   🟠   🔴   🟡  │
└─────────────────────┘

LD3 (Green):  Heartbeat (blinks 1 Hz)
LD2 (Orange): CPU Active (flickers)
LD1 (Red):    Anomaly Detected (off)
LD0 (Yellow): ETS Alert (off)
```

---

## 🚀 Programming Methods

### Method 1: Automated Script (RECOMMENDED)
```powershell
cd C:\Users\omdag\OneDrive\Desktop\time_bound_processor
vivado -mode batch -source program.tcl
```

**Expected output**:
```
Connecting to hardware server...
Opening hardware target...
Programming device...
========================================
Programming Complete!
========================================
```

**Time**: ~1-2 minutes

---

### Method 2: Vivado Hardware Manager (GUI)

1. **Open Vivado**:
   ```powershell
   vivado
   ```

2. **Open Hardware Manager**:
   - Click: `Flow Navigator` → `Program and Debug` → `Open Hardware Manager`
   - Or: Menu `Flow` → `Open Hardware Manager`

3. **Connect to Board**:
   - Click: `Open target` → `Auto Connect`
   - Should see: `localhost:3121/xilinx_tcf/Digilent/210...`

4. **Program Device**:
   - Right-click on device: `xc7z010_1`
   - Select: `Program Device...`
   - Bitstream file: Browse to `zybo_z7_top.bit`
   - Click: `Program`

5. **Wait for Programming**:
   - Progress bar will show upload status
   - Takes ~30-60 seconds

6. **Verify**:
   - "Programming successful" message
   - LEDs on board should light up!

---

### Method 3: Xilinx hw_server (Advanced)

```tcl
# Start hardware server
hw_server

# In another terminal
vivado -mode tcl
connect_hw_server -url localhost:3121
open_hw_target
set_property PROGRAM.FILE {zybo_z7_top.bit} [get_hw_devices xc7z010_1]
program_hw_devices [get_hw_devices xc7z010_1]
refresh_hw_device [get_hw_devices xc7z010_1]
```

---

## 🎉 Success Indicators

### Immediate (within 1 second)
- ✅ **DONE LED**: Lights up on FPGA
- ✅ **LD3**: Starts blinking at 1 Hz (heartbeat)

### After 2-3 seconds
- ✅ **LD2**: Flickering (CPU executing instructions)
- ✅ **No errors** in Vivado console

### Test Buttons
- Press **BTN2** (test anomaly): LD1 should light up
- Press **BTN0** (reset): System restarts, LD3 keeps blinking

---

## 🔧 Troubleshooting

### Problem: "No hardware targets found"

**Cause**: Board not detected

**Solutions**:
1. Check USB cable connection
2. Install Digilent drivers:
   ```
   C:\Xilinx\Vivado\2024.1\data\xicom\cable_drivers\nt64\
   → Run install_drivers.exe
   ```
3. Check Device Manager: Should see "Digilent USB Device"
4. Try different USB port
5. Restart board (power cycle)

---

### Problem: "Device programming failed"

**Cause**: JTAG communication error

**Solutions**:
1. Verify JP5 jumper set to JTAG
2. Check USB cable (try different cable)
3. Power cycle the board
4. Restart Vivado Hardware Manager
5. Try: `Close Hardware Manager` → Reopen → Reconnect

---

### Problem: "LEDs don't blink after programming"

**Cause**: Design not running or clock issue

**Solutions**:
1. Press **BTN0** (reset button)
2. Check if DONE LED is lit (programming succeeded)
3. Verify bitstream file is correct
4. Re-program the board
5. Check build log for timing violations

---

### Problem: "DONE LED lit but no LED activity"

**Cause**: Clock not running or design in reset

**Check**:
1. XDC constraints loaded? (should be in bitstream)
2. Clock pin K17 correct? (125 MHz oscillator)
3. Reset button (BTN0) not stuck?

**Debug**:
- Check synthesis report for clock constraints
- Verify XDC file was included in build
- Try programming with ILA (Integrated Logic Analyzer) for debug

---

## 🧪 Verification Tests

### Test 1: Heartbeat LED (LD3)
**Expected**: Blinks ON/OFF at 1 Hz (0.5 sec on, 0.5 sec off)

**If not blinking**:
- Clock may not be running
- Design may be in permanent reset
- Check synthesis timing report

---

### Test 2: CPU Activity (LD2)
**Expected**: Irregular flickering (CPU executing instructions)

**If solid ON or OFF**:
- CPU may be stalled
- Memory initialization issue
- Check memory module in design

---

### Test 3: Anomaly Detection
**Action**: Press **BTN2** (test anomaly button)  
**Expected**: LD1 lights up briefly

**If no response**:
- Button input may not be working
- ETS module may need configuration
- Check constraints for button pin

---

### Test 4: Reset Function
**Action**: Press **BTN0** (reset button)  
**Expected**: All LEDs blink/reset, then resume normal operation

---

## 📊 Debug with Pmod Headers

If you have a logic analyzer, connect to **Pmod JE**:

| Pin | Signal | Purpose |
|-----|--------|---------|
| JE1 | ETS Interrupt | Pulses when anomaly detected |
| JE2 | Instruction Valid | High when instruction executing |
| JE3 | Instruction Done | Pulses when instruction completes |
| JE4 | Anomaly Flag | High when timing violation |

**Logic Analyzer Settings**:
- Clock: 125 MHz (or lower if clock divider used)
- Trigger: Rising edge on JE1 (ETS interrupt)
- Capture: 1000 samples

---

## 🎓 What Each LED Means

### LD3 (Green) - Heartbeat
- **Source**: `zybo_z7_top.v` - heartbeat counter
- **Purpose**: Proves FPGA is configured and clock running
- **Frequency**: 1 Hz (toggle every 62.5M cycles @ 125MHz)

### LD2 (Orange) - CPU Active
- **Source**: PC change detector
- **Purpose**: Shows CPU executing code (PC incrementing)
- **Pattern**: Irregular flicker (code-dependent)

### LD1 (Red) - Anomaly Detected
- **Source**: `ets_monitor.v` - comparator output
- **Purpose**: Timing violation detected
- **Normal**: OFF (no anomalies)

### LD0 (Yellow) - ETS Alert
- **Source**: `alert_controller.v` - alert flag
- **Purpose**: ETS alert active (sticky flag)
- **Normal**: OFF initially

---

## 🔄 Reprogramming

The FPGA configuration is **volatile** (lost on power-off).

**To reprogram**:
1. Don't need to power-cycle
2. Just run `program.tcl` again
3. New bitstream overwrites previous

**To make persistent**:
- Program flash memory (requires different flow)
- See Xilinx UG908 for QSPI programming

---

## ✅ Success Checklist

After programming, you should see:

- [x] DONE LED is lit (green)
- [x] LD3 blinking at 1 Hz
- [x] LD2 flickering (CPU active)
- [x] LD1 off (no anomalies)
- [x] LD0 off (no alerts)
- [x] No errors in Vivado console

**If all checked**: 🎉 **YOUR ETS RISC-V PROCESSOR IS RUNNING!**

---

## 📝 Next Steps After Success

1. **Test ETS functionality**:
   - Monitor LEDs during operation
   - Press BTN2 to inject test anomaly

2. **Load custom firmware**:
   - Compile new program
   - Re-synthesize with updated memory
   - Reprogram board

3. **Add UART console** (future):
   - Connect to COM port
   - 115200 baud, 8N1
   - See debug messages

4. **Measure timing** with logic analyzer:
   - Capture ETS signals on Pmod
   - Verify timing signatures

---

## 🚀 You're Ready to Program!

Once the build completes (check `build_log.txt`), run:

```powershell
vivado -mode batch -source program.tcl
```

**Then watch your LEDs light up!** ✨

---

*Good luck! Your processor is about to come to life!* 🎉

