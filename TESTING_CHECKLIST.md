# 🧪 ZYBO Z7-10 TESTING CHECKLIST

## Current Status
- ✅ Bitstream programmed successfully
- ✅ Board powered and connected
- 🧪 Testing what's functional

---

## TEST 1: LED HEARTBEAT (LD3) 💚

### What to Check
**LED3 (Green)** - Should blink ON/OFF at 1 Hz

### Procedure
1. Look at LED3 (leftmost LED on board)
2. Count the blinks for 10 seconds
3. Expected: ~10 blinks (1 per second)

### Result
- [ ] ✅ **PASS** - LED blinks steadily at 1 Hz
- [ ] ⚠️ **PARTIAL** - LED blinks but faster/slower
- [ ] ❌ **FAIL** - LED doesn't blink

### What This Tests
- ✅ FPGA configuration successful
- ✅ 125 MHz clock working
- ✅ Counter logic functional
- ✅ GPIO output working

---

## TEST 2: CPU ACTIVITY LED (LD2) 🟠

### What to Check
**LED2 (Orange)** - CPU activity indicator

### Procedure
1. Look at LED2 (second LED from left)
2. Observe its state

### Expected Behavior
Since full processor isn't integrated yet:
- May be ON, OFF, or dim
- Not expected to flicker (no actual CPU yet)

### Result
- [ ] ON (solid)
- [ ] OFF
- [ ] Flickering
- [ ] Dim

### What This Tests
- ✅ LED output working
- ⚠️ PC change detection (needs full processor)

---

## TEST 3: ETS STATUS LEDS (LD1, LD0) 🔴🟡

### What to Check
**LED1 (Red)** - Anomaly detected  
**LED0 (Yellow)** - ETS alert

### Procedure
1. Look at LED1 and LED0
2. Both should be OFF initially

### Result
- [ ] LD1: OFF ✅
- [ ] LD0: OFF ✅
- [ ] LD1: ON (unexpected)
- [ ] LD0: ON (unexpected)

### What This Tests
- ✅ LED outputs configured
- ⚠️ ETS detection (needs full integration)

---

## TEST 4: RESET BUTTON (BTN0) 🔄

### What to Check
**BTN0** - Reset button (active low)

### Procedure
1. Watch LED3 blinking
2. Press and hold BTN0
3. Release BTN0
4. LED3 should continue blinking

### Result
- [ ] ✅ **PASS** - LEDs reset properly
- [ ] ⚠️ **PARTIAL** - Some effect visible
- [ ] ❌ **FAIL** - No effect

### What This Tests
- ✅ Reset signal connectivity
- ✅ Reset button working
- ✅ System can recover from reset

---

## TEST 5: CONTROL BUTTONS (BTN1, BTN2) 🔘

### What to Check
**BTN1** - Clear ETS counters  
**BTN2** - Test anomaly trigger

### Procedure
1. Press BTN1 (may have no visible effect yet)
2. Press BTN2 (may have no visible effect yet)
3. Observe LEDs

### Result
- [ ] No visible effect (expected without full processor)
- [ ] LD1 lights up
- [ ] Other LED changes

### What This Tests
- ⚠️ Button inputs (functionality needs processor)

---

## TEST 6: SWITCHES (SW0, SW1) 🎚️

### What to Check
**SW0** - ETS enable  
**SW1** - Learning mode

### Procedure
1. Toggle SW0 up and down
2. Toggle SW1 up and down
3. Observe any LED changes

### Result
- [ ] No visible effect (expected - not connected to LEDs)
- [ ] LEDs change

### What This Tests
- ⚠️ Switch inputs (needs full processor integration)

---

## TEST 7: POWER LED 🟢

### What to Check
**Power LED** - Green LED near power jack

### Procedure
1. Look at power LED (separate from user LEDs)
2. Should be solid green

### Result
- [ ] ✅ ON (solid green)
- [ ] ❌ OFF

### What This Tests
- ✅ Board power supply working

---

## TEST 8: DONE LED (FPGA Configuration) 🔵

### What to Check
**DONE LED** - Blue LED on FPGA

### Procedure
1. Look for small blue LED on FPGA chip
2. Should be lit after programming

### Result
- [ ] ✅ ON (FPGA configured)
- [ ] ❌ OFF (configuration failed)

### What This Tests
- ✅ FPGA successfully configured with bitstream

---

## 🔬 ADVANCED TESTS (If you have equipment)

### TEST 9: Clock Signal (Oscilloscope/Logic Analyzer)

**Equipment Needed**: Oscilloscope or logic analyzer

**Probe Points**:
- Pin K17 (CLK input): Should see 125 MHz
- Pmod JE pins: Various debug signals

**Procedure**:
1. Connect probe to CLK pin (K17)
2. Should see 125 MHz square wave
3. Measure frequency

**Result**:
- [ ] ✅ 125 MHz ±5%
- [ ] ⚠️ Different frequency
- [ ] ❌ No signal

---

### TEST 10: Pmod Debug Outputs (Logic Analyzer)

**Equipment Needed**: Logic analyzer

**Pmod JE Pin Mapping**:
| Pin | Signal | Expected |
|-----|--------|----------|
| JE1 | ETS Interrupt | LOW (no interrupts yet) |
| JE2 | Instruction Valid | LOW (no processor) |
| JE3 | Instruction Done | LOW (no processor) |
| JE4 | Anomaly Detected | LOW (no anomalies) |

**Procedure**:
1. Connect logic analyzer to Pmod JE
2. Capture signals
3. Verify all LOW

**Result**:
- [ ] All signals LOW (expected)
- [ ] Some activity (unexpected)

---

## 📊 TEST RESULTS SUMMARY

### ✅ PASSING (Should Work)
- [ ] LED3 heartbeat blinking
- [ ] Power LED on
- [ ] DONE LED on
- [ ] Reset button functional
- [ ] Clock running at 125 MHz

### ⚠️ PARTIAL (Limited Without Full Processor)
- [ ] LED2 CPU activity
- [ ] Button controls (BTN1, BTN2)
- [ ] Switch inputs (SW0, SW1)
- [ ] ETS LEDs (LD1, LD0)

### ❌ NOT WORKING (Expected - Needs Integration)
- [ ] Actual RISC-V code execution
- [ ] ETS anomaly detection
- [ ] Memory access patterns
- [ ] Pmod signal activity

---

## 🎯 WHAT'S ACTUALLY RUNNING?

### Current Design Components

```
┌─────────────────────────────────┐
│     Zybo Z7-10 Top Module      │
│                                 │
│  ┌──────────────────────────┐  │
│  │  125 MHz Clock           │  │
│  │  ├─> Heartbeat Counter   │──┼─> LED3 (Blinking!)
│  │  └─> LED Control Logic   │  │
│  └──────────────────────────┘  │
│                                 │
│  ┌──────────────────────────┐  │
│  │  Simple Memory Module    │  │
│  │  (16 KB BRAM)           │  │
│  └──────────────────────────┘  │
│                                 │
│  ┌──────────────────────────┐  │
│  │  GPIO Connections        │  │
│  │  (Switches, Buttons)     │  │
│  └──────────────────────────┘  │
│                                 │
│  ⚠️ ETS + Processor           │
│     (Placeholder - Not Active) │
└─────────────────────────────────┘
```

### Why Low Resource Usage?

**Current**: 84 LUTs, 30 FFs  
**With Full Processor**: Would be ~2700 LUTs, ~1900 FFs

The PicoRV32 core is commented out in the current design, so you're only seeing the basic support logic.

---

## 🔍 DETAILED VERIFICATION

### Check Utilization Report

```powershell
cd C:\Users\omdag\OneDrive\Desktop\time_bound_processor
Get-Content vivado_project\utilization_impl.rpt | Select-String -Pattern "Slice LUTs|Slice Registers|Block RAM" -Context 2
```

### Check Timing Report

```powershell
Get-Content vivado_project\timing.rpt | Select-String -Pattern "slack|WNS|TNS" -Context 2
```

---

## 📝 RECORD YOUR RESULTS

Fill this out after testing:

**Date/Time**: _______________

**Tests Passed**: _____ / 10

**LED3 Blink Rate**: _____ blinks in 10 seconds

**Observations**:
```
[Write your observations here]
```

**Issues Found**:
```
[Any problems or unexpected behavior]
```

**Ready for Full Integration?**: YES / NO

---

## 🚀 NEXT STEPS

Based on your test results:

### If Everything Working (LED3 Blinking)
✅ **Board is healthy!**  
→ Ready for full processor integration

### If LED3 Not Blinking
❌ **Troubleshooting needed**  
→ Check power, reset, reprogram

### If Partial Results
⚠️ **Some issues**  
→ Debug specific components

---

**Complete this checklist, then tell me your results!** 📋

