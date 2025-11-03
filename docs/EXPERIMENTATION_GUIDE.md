# 🧪 ETS RISC-V Experimentation Guide

## **Complete Guide for Research-Level Testing**

This guide provides step-by-step instructions for conducting experiments with the ETS RISC-V system.

---

## **📋 Quick Start**

### **Option 1: Automated Testing (Recommended)**

```powershell
cd C:\Users\omdag\OneDrive\Desktop\time_bound_processor

# Run research test suite
.\tools\run_research_test.ps1 -TestType research

# Or run interactive interface
.\tools\run_research_test.ps1 -TestType interactive
```

### **Option 2: Manual Testing**

```powershell
# 1. Compile firmware
cd software/firmware/tests
.\build.ps1 research

# 2. Generate firmware init
cd ../../../
.\generate_firmware_init.ps1 -hexFile "software/firmware/tests/test_research.hex"

# 3. Build & program
vivado -mode batch -source build.tcl
vivado -mode batch -source program.tcl
```

---

## **🔬 Experiment Types**

### **1. Automated Research Test Suite**

**Purpose**: Comprehensive validation of all ETS features

**Command**:
```powershell
.\tools\run_research_test.ps1 -TestType research
```

**What it does**:
- Runs 7 different tests automatically
- Measures timing accuracy, detection rates, performance
- Tests crypto validation, learning mode, stress testing

**Observation**:
- **LEDs show test progress** (LED pattern = test number)
  - LED: 0x1 = Test 1 (Timing Accuracy)
  - LED: 0x2 = Test 2 (False Positives)
  - LED: 0x4 = Test 3 (Attack Detection)
  - LED: 0x5 = Test 4 (Performance)
  - LED: 0x6 = Test 5 (Crypto)
  - LED: 0x7 = Test 6 (Learning)
  - LED: 0x8 = Test 7 (Stress)

- **Final result** (after all tests):
  - Blinks N times = N tests passed
  - Final pattern:
    - 0x1 = Excellent (>90% pass)
    - 0x3 = Good (>70% pass)
    - 0x7 = Fair (>50% pass)
    - 0xF = Poor (<50% pass)

**Duration**: ~30-60 seconds

---

### **2. Interactive Interface**

**Purpose**: Manual control and experimentation

**Command**:
```powershell
.\tools\run_research_test.ps1 -TestType interactive
```

**What it does**:
- Provides state machine for user interaction
- Cycles through different ETS configurations
- Runs tests on demand
- Shows real-time monitoring

**Interaction** (simulated button presses in current version):
- System cycles through states automatically
- Watch LED patterns for current state
- Future: Use board switches/buttons for control

**States**:
1. **INIT** → Powers up, initializes
2. **IDLE** → Ready (LED: 0x1)
3. **CONFIG_PERMISSIVE** → Sets permissive mode
4. **RUN_TESTS** → Executes test suite
5. **DISPLAY_RESULTS** → Shows results
6. **CONFIG_STRICT** → Sets strict mode
7. Loop continues...

**Duration**: Continuous (runs indefinitely)

---

### **3. Basic Functionality Test**

**Purpose**: Verify basic ETS operation

**Command**:
```powershell
.\tools\run_research_test.ps1 -TestType basic
```

**What it does**:
- Simple loop with ETS monitoring
- Generates predictable timing patterns
- Should produce minimal anomalies

**Expected behavior**:
- LEDs show heartbeat pattern
- Should see consistent timing
- Anomaly count stays low

---

### **4. Anomaly Detection Test**

**Purpose**: Test attack detection capabilities

**Command**:
```powershell
.\tools\run_research_test.ps1 -TestType anomaly
```

**What it does**:
- Injects timing anomalies
- Tests ETS alert system
- Validates detection accuracy

**Expected behavior**:
- LEDs will flash when anomalies detected
- Alert count should increase
- System should catch injected delays

---

### **5. Learning Mode Test**

**Purpose**: Validate automatic signature learning

**Command**:
```powershell
.\tools\run_research_test.ps1 -TestType learning
```

**What it does**:
- Learns instruction timing automatically
- Builds signature database
- Validates learned signatures

**Expected behavior**:
- Initial phase: Learning (many anomalies)
- Later phase: Stable (few anomalies)
- Demonstrates adaptive behavior

---

## **🎛️ ETS Configuration Modes**

### **Permissive Mode**

```c
ets_set_signature(0x13, 10, 10);  // ADDI: 10 cycles ±10
ets_set_signature(0x33, 15, 10);  // ADD:  15 cycles ±10
ets_set_signature(0x03, 20, 15);  // LOAD: 20 cycles ±15
```

**Characteristics**:
- Large tolerances
- Low false positive rate (<1%)
- May miss subtle attacks
- Good for normal operation

**Use when**: You want minimal false alarms

---

### **Strict Mode**

```c
ets_set_signature(0x13, 5, 1);    // ADDI: 5 cycles ±1
ets_set_signature(0x33, 6, 1);    // ADD:  6 cycles ±1
ets_set_signature(0x03, 10, 2);   // LOAD: 10 cycles ±2
```

**Characteristics**:
- Tight tolerances
- Higher detection rate (70-90%)
- More false positives (5-10%)
- Catches most timing variations

**Use when**: You need strong security

---

### **Research Mode**

```c
ets_set_signature(0x13, 5, 0);    // ADDI: 5 cycles (EXACT)
ets_set_signature(0x33, 6, 0);    // ADD:  6 cycles (EXACT)
ets_set_signature(0x03, 10, 1);   // LOAD: 10 cycles ±1
```

**Characteristics**:
- Zero tolerance on critical instructions
- Very high detection rate (>90%)
- High false positive rate (10-20%)
- For research/analysis only

**Use when**: You want maximum sensitivity

---

## **📊 Data Collection**

### **Method 1: LED Observation (Current)**

**Record manually**:

| Test | LED Pattern | Interpretation | Notes |
|------|-------------|----------------|-------|
| 1 | 0x1 | Pass | Timing accurate |
| 2 | 0x3 | Partial | Some false positives |
| 3 | 0x1 | Pass | Attack detected |
| ... | ... | ... | ... |

**Final Blinks**: Count and record

**Final Pattern**: Note the pattern

---

### **Method 2: Memory Dump (Advanced)**

**Future enhancement**: Read results from memory

```c
// In firmware, store results at known address
#define RESULTS_ADDR 0x00000F00
volatile test_result_t* results = (test_result_t*)RESULTS_ADDR;

// After programming, use Vivado to read memory
```

---

### **Method 3: UART Output (Future)**

**When UART is added**:

```c
uart_printf("Test %d: %s\n", id, passed ? "PASS" : "FAIL");
uart_printf("Anomalies: %d\n", anomaly_count);
uart_printf("Cycles: %d\n", cycles);
```

**Connect serial terminal**, log output to CSV

---

## **🧮 Analysis**

### **After Data Collection**

1. **Create CSV file**:

```csv
test_id,expected_anomalies,detected_anomalies,execution_time,passed
1,0,0,250,true
1,0,1,248,true
2,0,15,5000,true
3,10,8,3000,true
...
```

2. **Run analysis**:

```bash
python tools/analyze_results.py data.csv
```

3. **Review reports**:
- `analysis_report.txt` - Full text report
- `analysis_summary.csv` - Summary metrics

---

## **📈 Interpreting Results**

### **Detection Metrics**

**True Positive Rate**:
```
TPR = (Detected Attacks / Total Attacks) × 100%

Excellent: >90%
Good:      70-90%
Fair:      50-70%
Poor:      <50%
```

**False Positive Rate**:
```
FPR = (False Alarms / Normal Executions) × 100%

Excellent: <1%
Good:      1-5%
Fair:      5-10%
Poor:      >10%
```

### **Timing Metrics**

**Precision**:
```
Precision = (Std Dev / Mean) × 100%

Excellent: <5%
Good:      5-10%
Fair:      10-20%
Poor:      >20%
```

### **Performance Metrics**

**Overhead**:
```
Overhead = ((Time_with_ETS - Time_without_ETS) / Time_without_ETS) × 100%

Excellent: <2%
Good:      2-5%
Fair:      5-10%
Poor:      >10%
```

---

## **🎯 Experiment Ideas**

### **Experiment 1: Configuration Tuning**

**Goal**: Find optimal tolerance settings

**Method**:
1. Run tests with permissive mode
2. Record false positive rate
3. Run tests with strict mode
4. Record detection rate
5. Try intermediate values
6. Plot ROC curve

**Analysis**: Find best trade-off between TPR and FPR

---

### **Experiment 2: Attack Simulation**

**Goal**: Test against various attack types

**Method**:
1. Implement different timing delays
2. Test with cache miss simulation
3. Test with branch misprediction
4. Test with data-dependent timing
5. Measure detection for each

**Analysis**: Which attacks are easiest/hardest to detect?

---

### **Experiment 3: Crypto Validation**

**Goal**: Validate constant-time implementations

**Method**:
1. Implement various crypto operations
2. Measure timing variance
3. Compare constant-time vs. variable-time
4. Use ETS to validate

**Analysis**: Does ETS effectively distinguish constant-time code?

---

### **Experiment 4: Learning Efficiency**

**Goal**: Optimize learning algorithm

**Method**:
1. Vary number of learning iterations
2. Test convergence speed
3. Measure accuracy vs. manual config
4. Test on different code patterns

**Analysis**: How many iterations needed? When to stop learning?

---

### **Experiment 5: Scalability**

**Goal**: Test with large programs

**Method**:
1. Start with small programs (100 instructions)
2. Gradually increase size
3. Measure performance impact
4. Check detection accuracy

**Analysis**: Does ETS scale to real applications?

---

## **🔧 Troubleshooting Experiments**

### **Problem: All tests fail**

**Possible causes**:
- ETS not initialized properly
- Signatures not configured
- Clock issues

**Solution**:
- Check initialization sequence
- Verify signature values
- Test with permissive mode first

---

### **Problem: High false positive rate**

**Possible causes**:
- Tolerances too tight
- Natural timing variation
- Cache/memory effects

**Solution**:
- Increase tolerances
- Use permissive mode
- Average over more samples

---

### **Problem: Low detection rate**

**Possible causes**:
- Tolerances too loose
- Attacks too subtle
- Sampling issues

**Solution**:
- Use strict/research mode
- Inject stronger anomalies
- Increase monitoring frequency

---

### **Problem: Inconsistent results**

**Possible causes**:
- Environmental factors
- Board interference
- Power supply issues

**Solution**:
- Run multiple trials
- Use controlled environment
- Check power supply quality

---

## **📝 Experiment Template**

Use this template for each experiment:

```markdown
# Experiment: [Name]

## Objective
[What are you trying to learn?]

## Hypothesis
[What do you expect to happen?]

## Method
1. [Step 1]
2. [Step 2]
3. ...

## Configuration
- ETS Mode: [Permissive/Strict/Research]
- Firmware: [which test]
- Parameters: [any special settings]

## Data Collection
[How will you record results?]

## Results
[Record your observations]

| Trial | Metric 1 | Metric 2 | Notes |
|-------|----------|----------|-------|
| 1     |          |          |       |
| 2     |          |          |       |

## Analysis
[What do the results mean?]

## Conclusions
[What did you learn?]

## Future Work
[What should be tested next?]
```

---

## **🚀 Advanced Experiments**

### **Power Analysis**

**Goal**: Measure power consumption with/without ETS

**Equipment needed**:
- Power analyzer
- Current probe

**Method**:
1. Measure baseline power
2. Enable ETS, measure again
3. Calculate power overhead

---

### **Formal Verification**

**Goal**: Mathematically prove ETS properties

**Tools needed**:
- Model checker
- Formal specification

**Method**:
1. Create formal model
2. Specify properties
3. Verify with tool

---

### **Machine Learning Integration**

**Goal**: Use ML for signature learning

**Method**:
1. Collect training data
2. Train ML model
3. Deploy to FPGA
4. Compare to rule-based approach

---

## **📚 Publishing Results**

### **For Academic Papers**

**Sections to include**:
1. Introduction & motivation
2. ETS design & implementation
3. Experimental methodology
4. Results & analysis
5. Discussion
6. Related work
7. Conclusions

### **Key Metrics to Report**

- Detection rate (TPR)
- False alarm rate (FPR)
- Performance overhead (%)
- Timing precision (%)
- Scalability results
- Power consumption (if measured)

### **Graphs & Figures**

- ROC curve (TPR vs FPR)
- Timing distribution histograms
- Performance comparison bar charts
- Scalability plots
- Example attack detection

---

## **✅ Experiment Checklist**

Before starting:
- [ ] Board connected and powered
- [ ] Firmware compiled successfully
- [ ] Bitstream built and programmed
- [ ] Documentation reviewed
- [ ] Data recording method ready

During experiment:
- [ ] Record all LED patterns
- [ ] Note any anomalies
- [ ] Take multiple readings
- [ ] Document configuration

After experiment:
- [ ] Organize data into CSV
- [ ] Run analysis tools
- [ ] Document findings
- [ ] Plan next experiment

---

## **🆘 Need Help?**

**Documentation**:
- `docs/RESEARCH_TESTING_GUIDE.md` - Testing methodology
- `docs/ets_specification.md` - ETS design details
- `software/firmware/common/ets_lib.h` - API reference

**Common Questions**:
- "How do I interpret LED patterns?" → See RESEARCH_TESTING_GUIDE.md
- "What configuration should I use?" → Start with permissive, then strict
- "How long should experiments run?" → At least 100 samples
- "Can I modify the tests?" → Yes! Edit C files in software/firmware/tests/

---

**Good luck with your experiments! 🚀**

