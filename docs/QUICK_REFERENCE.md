# ⚡ ETS RISC-V Quick Reference

## **1-Minute Setup**

```powershell
cd C:\Users\omdag\OneDrive\Desktop\time_bound_processor
.\tools\run_research_test.ps1 -TestType research
```

**Wait 5-10 minutes** → Watch LEDs for results

---

## **🎯 Test Types**

| Command | Purpose | Duration |
|---------|---------|----------|
| `-TestType research` | Full test suite (7 tests) | 30-60s |
| `-TestType interactive` | Manual control | Continuous |
| `-TestType basic` | Basic functionality | Continuous |
| `-TestType anomaly` | Attack detection | Continuous |
| `-TestType learning` | Auto-learning | Continuous |

---

## **💡 LED Meanings**

### **During Research Tests**
- **0x1** = Test 1 (Timing)
- **0x2** = Test 2 (False Positives)
- **0x4** = Test 3 (Attacks)
- **0x5** = Test 4 (Performance)
- **0x6** = Test 5 (Crypto)
- **0x7** = Test 6 (Learning)
- **0x8** = Test 7 (Stress)

### **Final Results**
- **N blinks** = N tests passed
- **0x1** = Excellent (>90%)
- **0x3** = Good (70-90%)
- **0x7** = Fair (50-70%)
- **0xF** = Poor (<50%)

---

## **⚙️ ETS Configurations**

### **Permissive** (Low false alarms)
```c
ets_set_signature(0x13, 10, 10);  // ±10 cycles
```
- FP Rate: <1%
- Detection: 30-50%

### **Strict** (Balanced)
```c
ets_set_signature(0x13, 5, 1);    // ±1 cycle
```
- FP Rate: 5-10%
- Detection: 70-90%

### **Research** (Maximum sensitivity)
```c
ets_set_signature(0x13, 5, 0);    // Exact
```
- FP Rate: 10-20%
- Detection: >90%

---

## **📊 Key Metrics**

| Metric | Formula | Good Value |
|--------|---------|------------|
| True Positive Rate | Detected / Total Attacks | >70% |
| False Positive Rate | False Alarms / Normal Runs | <5% |
| Timing Precision | (StdDev / Mean) × 100% | <10% |
| Overhead | (ETS_Time - Base_Time) / Base_Time | <5% |

---

## **🔧 Common Commands**

### **Full Build & Test**
```powershell
.\tools\run_research_test.ps1 -TestType research
```

### **Quick Test (Skip FPGA Build)**
```powershell
.\tools\run_research_test.ps1 -TestType basic -SkipBuild
```

### **Clean Build**
```powershell
.\tools\run_research_test.ps1 -TestType research -CleanBuild
```

### **Analyze Results**
```bash
python tools/analyze_results.py data.csv
```

---

## **🚨 Troubleshooting**

| Problem | Solution |
|---------|----------|
| Board not detected | Check power, USB, drivers |
| All LEDs off | Check programming, reset board |
| All tests fail | Try permissive mode, check init |
| High false positives | Increase tolerances |
| Low detection | Use strict mode |

---

## **📁 File Locations**

```
rtl/                   → Hardware (Verilog)
software/firmware/     → C programs
tools/                 → Scripts & analysis
docs/                  → Full documentation
constraints/           → FPGA pin assignments
```

---

## **🔬 Experiment Workflow**

```
1. Modify test code (optional)
   └─ software/firmware/tests/[test].c

2. Run test
   └─ .\tools\run_research_test.ps1 -TestType [type]

3. Observe LEDs
   └─ Record patterns & blinks

4. Analyze (optional)
   └─ python tools/analyze_results.py

5. Document findings
   └─ Use experiment template
```

---

## **📚 Documentation**

- **Full Research Guide**: `docs/RESEARCH_TESTING_GUIDE.md`
- **Experimentation**: `docs/EXPERIMENTATION_GUIDE.md`
- **ETS Specification**: `docs/ets_specification.md`
- **Hardware Details**: `docs/zybo_z7_guide.md`

---

## **🎓 Research Topics**

1. **Configuration Tuning** → Optimize tolerances
2. **Attack Simulation** → Test detection
3. **Crypto Validation** → Constant-time verification
4. **Learning Efficiency** → Auto-signature generation
5. **Scalability** → Large program testing

---

## **✅ Quick Checks**

**Is it working?**
- [ ] LEDs change during tests
- [ ] Patterns match expected values
- [ ] Final result shows pass/fail

**Ready for research?**
- [ ] Multiple test runs consistent
- [ ] Can modify and rebuild firmware
- [ ] Understand LED interpretation
- [ ] Have data collection method

---

## **🚀 Next Steps**

**Beginner**:
1. Run `research` test
2. Count passed tests (blinks)
3. Try different test types
4. Read full research guide

**Advanced**:
1. Modify test code
2. Create custom experiments
3. Analyze with Python tools
4. Publish findings

---

**For detailed info, see: `docs/EXPERIMENTATION_GUIDE.md`**

