# 📡 UART Data Logging Guide

## **Complete Guide to Using UART with Your ETS RISC-V System**

---

## **🎯 What is UART?**

**UART (Universal Asynchronous Receiver-Transmitter)** is a serial communication protocol that lets your FPGA send text data to your PC.

**Benefits**:
- ✅ **Real data** instead of LED observation
- ✅ **Quantitative results** for research
- ✅ **CSV export** for Python analysis
- ✅ **Publication-quality** data collection

---

## **🔌 Hardware Setup**

### **What You Need**:
1. **Zybo Z7-10 board** (you have this!)
2. **USB-UART adapter** (e.g., FTDI FT232, CP2102)
   - **Cost**: $5-10 on Amazon/eBay
   - **Alternative**: Use logic analyzer or oscilloscope
3. **3 jumper wires** (female-to-female)

### **Connections**:

```
USB-UART Adapter          Zybo Z7-10 Board
─────────────────         ────────────────────
GND        ────────────→  GND (any ground pin)
RX (input) ────────────→  Pmod JA Pin 1 (UART TX)
```

**Important**: 
- Connect adapter **RX** to board **TX** (cross connection)
- We're only doing transmit (one-way), so adapter TX is not connected
- Make sure voltage levels match (3.3V)

### **Pin Locations on Zybo Z7-10**:

```
Pmod JA Header (Top Row):
┌───┬───┬───┬───┐
│ 1 │ 2 │ 3 │ 4 │  Pin 1 = UART TX (Y18)
└───┴───┴───┴───┘
  ↑
  TX
```

---

## **💻 Software Setup**

### **Step 1: Install Serial Terminal**

**Option A: PuTTY (Windows - Recommended)**
1. Download from: https://www.putty.org/
2. Install
3. Done!

**Option B: RealTerm (Windows - Advanced)**
1. Download from: https://realterm.sourceforge.io/
2. Better for logging to files

**Option C: screen (Linux/Mac)**
```bash
screen /dev/ttyUSB0 115200
```

### **Step 2: Find COM Port**

**Windows**:
1. Plug in USB-UART adapter
2. Open **Device Manager**
3. Expand **Ports (COM & LPT)**
4. Look for "USB Serial Port (COM X)" - note the number

**Linux/Mac**:
```bash
ls /dev/tty*
# Look for /dev/ttyUSB0 or /dev/ttyACM0
```

### **Step 3: Configure Terminal**

**PuTTY Settings**:
1. Connection type: **Serial**
2. Serial line: **COM3** (or your COM port)
3. Speed: **115200**
4. Click **Open**

**Settings Detail**:
- Baud rate: 115200
- Data bits: 8
- Stop bits: 1
- Parity: None
- Flow control: None

---

## **🚀 Running UART Tests**

### **The FPGA bitstream is building right now!**

When build completes (~5-10 minutes), it will include:
- UART hardware module
- Memory-mapped UART interface
- Test program with `uart_printf()`

### **After Build Completes**:

1. **Program Board**:
```powershell
cd C:\Users\omdag\OneDrive\Desktop\time_bound_processor
vivado -mode batch -source program.tcl
```

2. **Connect UART Adapter** (if not already connected)

3. **Open Serial Terminal** (PuTTY at 115200 baud)

4. **Press Reset Button** on board (or re-program)

5. **Watch Data Stream In!** 🎉

---

## **📊 Expected Output**

You should see something like this:

```
========================================
ETS RISC-V RESEARCH TEST SUITE
========================================
System: PicoRV32 + ETS Monitor
Platform: Zybo Z7-10 FPGA
Clock: 125 MHz
========================================

Starting tests...

--- Test 1: Timing Accuracy ---
Anomalies: 3
Status: PASS

--- Test 2: False Positive Rate ---
Anomalies: 8 / 100 iterations
FP Rate: 8%
Status: PASS

--- Test 3: Attack Detection ---
Baseline: 0, Detected: 7
Detection Rate: 70%
Status: PASS

--- Test 4: Performance ---
Status: PASS

--- Test 5: Crypto Validation ---
Constant-time: 2, Variable-time: 14
Status: PASS

--- Test 6: Learning Mode ---
Anomalies after learning: 4
Status: PASS

--- Test 7: Stress Test ---
Matrix sum: 2025
Status: PASS

========================================
RESEARCH TEST SUMMARY
========================================
Test 1: PASS - Anomalies: 3
Test 2: PASS - Anomalies: 8
Test 3: PASS - Anomalies: 7
Test 4: PASS - Anomalies: 0
Test 5: PASS - Anomalies: 14
Test 6: PASS - Anomalies: 4
Test 7: PASS - Anomalies: 0

Total: 7/7 tests passed
Success Rate: 100%
Grade: EXCELLENT
========================================

--- CSV DATA (for analysis) ---
test_id,expected_anomalies,detected_anomalies,execution_time,passed
1,0,3,0,1
2,0,8,0,1
3,0,7,0,1
4,0,0,0,1
5,0,14,0,1
6,0,4,0,1
7,0,0,0,1

Tests complete. System entering heartbeat mode.
```

---

## **💾 Saving Data**

### **PuTTY Method**:

1. Before connecting, go to:
   - **Session** → **Logging**
   - Select "All session output"
   - Choose file location
   - Click **Open**

2. Everything will be saved to file

### **RealTerm Method**:

1. **Capture** tab
2. Enter filename
3. Click **Start**

### **Manual Copy**:

1. Select text in terminal
2. Right-click to copy
3. Paste into text file

---

## **📈 Data Analysis**

### **Extract CSV Data**:

From the output, copy the CSV section:

```csv
test_id,expected_anomalies,detected_anomalies,execution_time,passed
1,0,3,0,1
2,0,8,0,1
3,0,7,0,1
...
```

Save as `test_results.csv`

### **Analyze with Python**:

```bash
cd C:\Users\omdag\OneDrive\Desktop\time_bound_processor
python tools/analyze_results.py test_results.csv
```

**Output**:
- Detailed report: `analysis_report.txt`
- Summary: `analysis_summary.csv`
- Graphs (if matplotlib installed)

---

## **🔧 Troubleshooting**

### **Problem: No output in terminal**

**Solutions**:
1. Check COM port number
2. Verify 115200 baud rate
3. Check wire connections:
   - GND to GND
   - Board TX to Adapter RX
4. Try resetting board
5. Re-program board

### **Problem: Garbled text**

**Solutions**:
1. Wrong baud rate - must be 115200
2. Check data bits = 8, stop bits = 1
3. Flow control = None

### **Problem: Output stops mid-stream**

**Solutions**:
1. Board may have crashed - check LEDs
2. Power issue - use external power supply
3. Reset and try again

### **Problem: Can't find COM port**

**Solutions**:
1. Install FTDI/CH340 drivers
2. Try different USB port
3. Check Device Manager for errors

---

## **🎯 What to Do With Data**

### **Immediate**:
1. ✅ Verify all tests pass
2. ✅ Record anomaly counts
3. ✅ Note success rate

### **Short-term**:
1. Run tests multiple times
2. Calculate average anomalies
3. Measure consistency
4. Compare different ETS configurations

### **Long-term**:
1. Create graphs (TPR vs FPR, overhead, etc.)
2. Write paper with quantitative results
3. Publish findings!

---

## **📊 Research Value**

With UART data logging, you can now:

✅ **Quantify Detection Rates**
- True Positive Rate: Detected / Expected
- False Positive Rate: False Alarms / Normal Runs
- ROC curves for different configurations

✅ **Measure Performance**
- Exact cycle counts
- Overhead calculations  
- Timing precision statistics

✅ **Validate Hypotheses**
- Test configuration changes
- Compare algorithms
- Statistical significance

✅ **Publication Quality**
- Real experimental data
- Reproducible results
- Professional graphs

---

## **🔬 Next Experiments**

Now that you have data logging:

1. **Configuration Optimization**
   - Test permissive, strict, research modes
   - Find optimal thresholds
   - Plot ROC curve

2. **Attack Simulation**
   - Vary timing injection amounts
   - Measure detection vs. FP rate
   - Test different attack patterns

3. **Scalability Testing**
   - Increase program size
   - Measure overhead scaling
   - Test with real applications

---

## **💡 Tips**

### **For Best Results**:
- Run each test 10+ times for statistics
- Record all parameters (config, thresholds, etc.)
- Keep detailed lab notebook
- Save all raw data

### **For Debugging**:
- Add more `uart_printf()` statements
- Print intermediate values
- Use UART as printf() replacement
- Very helpful for development!

---

## **📚 API Reference**

### **Basic Functions**:

```c
#include "../common/uart.h"

uart_init();                    // Initialize (optional)
uart_putc('A');                 // Send character
uart_puts("Hello");             // Send string
uart_putln("Line");             // String + newline
uart_puthex(0x1234);           // Print hex
uart_putuint(42);              // Print unsigned
uart_putdec(-10);              // Print signed
uart_printf("Val: %d\n", x);   // Printf-style
```

### **Printf Format Specifiers**:

- `%d` - Signed decimal
- `%u` - Unsigned decimal
- `%x` - Hexadecimal (with 0x prefix)
- `%s` - String
- `%c` - Character
- `%%` - Literal %

---

## **✅ Checklist**

Before running UART tests:

- [ ] FPGA bitstream built with UART support
- [ ] Board programmed with UART firmware
- [ ] USB-UART adapter connected correctly
- [ ] COM port identified
- [ ] Serial terminal configured (115200 baud)
- [ ] Terminal open and waiting
- [ ] Board powered on

---

## **🎉 You're Ready!**

Once the FPGA build completes and you program the board, you'll have **real-time data logging** from your hardware!

**This transforms your system from hobby project to research platform!** 🚀📊

---

*Build Status: Check `build_uart_log.txt` for progress*

