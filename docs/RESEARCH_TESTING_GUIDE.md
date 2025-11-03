# 🔬 Research-Level Testing Guide

## **ETS RISC-V System - Comprehensive Validation**

This document outlines the research methodology for validating the Execution Time Signatures (ETS) system.

---

## **📋 Table of Contents**

1. [Research Objectives](#research-objectives)
2. [Test Methodology](#test-methodology)
3. [Test Suite Overview](#test-suite-overview)
4. [Measurement Techniques](#measurement-techniques)
5. [Data Collection](#data-collection)
6. [Analysis Framework](#analysis-framework)
7. [Expected Results](#expected-results)
8. [How to Run Tests](#how-to-run-tests)

---

## **🎯 Research Objectives**

### **Primary Goals:**
1. **Validate ETS Accuracy** - Measure timing detection precision
2. **Quantify Detection Rates** - False positives/negatives analysis
3. **Assess Performance Impact** - Overhead measurement
4. **Verify Security Properties** - Attack detection validation
5. **Evaluate Scalability** - Large program testing

### **Research Questions:**
- **Q1**: How accurately does ETS track instruction execution times?
- **Q2**: What is the false positive rate for normal code?
- **Q3**: Can ETS detect simulated timing attacks?
- **Q4**: What is the performance overhead of ETS monitoring?
- **Q5**: Does ETS effectively validate constant-time crypto implementations?
- **Q6**: How well does automatic learning mode work?
- **Q7**: Can ETS scale to large, complex programs?

---

## **🔬 Test Methodology**

### **1. Controlled Environment**
- **Platform**: Zybo Z7-10 FPGA @ 100MHz
- **Processor**: PicoRV32 with ETS integration
- **Memory**: 4KB Block RAM
- **Isolation**: No OS, bare-metal execution

### **2. Measurement Approach**
```
┌─────────────────────────────────────────┐
│  Test Execution Flow                    │
├─────────────────────────────────────────┤
│  1. Initialize ETS with config          │
│  2. Clear counters & state              │
│  3. Start cycle counter                 │
│  4. Execute test code                   │
│  5. Stop cycle counter                  │
│  6. Read ETS registers                  │
│  7. Log results                         │
│  8. Analyze data                        │
└─────────────────────────────────────────┘
```

### **3. Statistical Analysis**
- **Minimum Samples**: 100 iterations per test
- **Confidence Level**: 95%
- **Outlier Detection**: ±2 standard deviations
- **Reproducibility**: 3 complete test runs

---

## **📊 Test Suite Overview**

### **Test 1: Timing Accuracy Validation**

**Objective**: Measure how precisely ETS tracks instruction execution times.

**Method**:
```c
// Execute known instruction sequence
for (int i = 0; i < 100; i++) {
    a = a + 1;  // ADDI instruction (predictable)
}
// Measure: Total cycles / 100 = avg cycles per instruction
```

**Metrics**:
- Average cycles per instruction
- Standard deviation
- Min/max cycle counts

**Expected Results**:
- ADDI: 2-3 cycles (PicoRV32 baseline)
- Standard deviation: < 5%
- No anomalies with permissive config

**Success Criteria**: ✅ Measured timing within ±10% of expected

---

### **Test 2: False Positive Rate**

**Objective**: Measure false alarm rate with normal, predictable code.

**Method**:
```c
// Run 1000 iterations of identical code
for (int iteration = 0; iteration < 1000; iteration++) {
    // Simple, predictable loop
    sum = 0;
    for (int i = 0; i < 10; i++) {
        sum += i;
    }
}
// Count anomalies detected
```

**Metrics**:
- Total anomalies / 1000 iterations
- False positive rate (%)

**Expected Results**:
- Permissive config: < 1% FP rate
- Strict config: < 10% FP rate
- Research config: < 20% FP rate

**Success Criteria**: ✅ FP rate within acceptable bounds for each configuration

---

### **Test 3: Attack Detection (True Positive Rate)**

**Objective**: Verify ETS detects timing anomalies (simulated attacks).

**Method**:
```c
// Phase 1: Normal execution (baseline)
for (int i = 0; i < 10; i++) {
    x = i;
}

// Phase 2: Inject timing anomalies
for (int i = 0; i < 10; i++) {
    x = i;
    // Variable delay (simulates cache miss, side-channel)
    for (int j = 0; j < i * 10; j++) {
        nop;
    }
}
```

**Metrics**:
- True positive rate: (detected / injected) × 100%
- Detection latency: Cycles until alert

**Expected Results**:
- Permissive: 30-50% detection
- Strict: 70-90% detection
- Research: >90% detection

**Success Criteria**: ✅ Strict config detects >70% of attacks

---

### **Test 4: Performance Overhead**

**Objective**: Quantify performance impact of ETS monitoring.

**Method**:
```c
// Measure WITHOUT ETS
ets_enable(false);
start = get_cycles();
[test code]
end = get_cycles();
baseline_time = end - start;

// Measure WITH ETS
ets_enable(true);
start = get_cycles();
[same test code]
end = get_cycles();
ets_time = end - start;

overhead = ((ets_time - baseline_time) / baseline_time) × 100%
```

**Metrics**:
- Absolute overhead (cycles)
- Relative overhead (%)
- Per-instruction overhead

**Expected Results**:
- Coarse-grained: < 2% overhead
- Fine-grained: < 5% overhead
- Instruction-level: < 10% overhead

**Success Criteria**: ✅ Overhead < 5% for fine-grained mode

---

### **Test 5: Constant-Time Crypto Validation**

**Objective**: Verify ETS validates constant-time implementations.

**Method**:
```c
// Test 1: Constant-time XOR (no branches)
for (int i = 0; i < 16; i++) {
    data[i] = data[i] ^ key;
}
anomalies_constant = get_anomaly_count();

// Test 2: Data-dependent branches
for (int i = 0; i < 16; i++) {
    if (data[i] & 0x1) {  // Branch on data
        data[i] = data[i] * 2;
    } else {
        data[i] = data[i] + 1;
    }
}
anomalies_variable = get_anomaly_count();
```

**Metrics**:
- Anomalies in constant-time code
- Anomalies in variable-time code
- Ratio: variable / constant

**Expected Results**:
- Constant-time: 0-5 anomalies
- Variable-time: 10+ anomalies
- Ratio: > 2.0

**Success Criteria**: ✅ ETS distinguishes constant vs. variable time

---

### **Test 6: Learning Mode**

**Objective**: Test automatic signature generation.

**Method**:
```c
// Define test function
void test_func() { [...] }

// Learn timing over 50 iterations
ets_learn_function(test_func, 50);

// Validate learned signatures
ets_enable(true);
for (int i = 0; i < 20; i++) {
    test_func();  // Should match learned timing
}
```

**Metrics**:
- Anomalies after learning
- Convergence speed (iterations)
- Accuracy vs. manual configuration

**Expected Results**:
- < 5% anomalies after learning
- Convergence in 30-50 iterations

**Success Criteria**: ✅ Learned signatures reduce anomalies by >80%

---

### **Test 7: Stress Test**

**Objective**: Validate ETS with large, complex programs.

**Method**:
- Matrix operations (100+ instructions)
- Multiple function calls
- Mixed instruction types
- Extended execution time

**Metrics**:
- Total execution time
- Memory usage
- System stability
- Final anomaly count

**Success Criteria**: ✅ System remains stable, completes successfully

---

## **📈 Data Collection**

### **Hardware Monitoring**

**LED Indicators** (Real-time feedback):
```
LED[0] = 0x1: Test running / OK
LED[1] = 0x2: Processing
LED[2] = 0x4: Warning
LED[3] = 0x8: Error

Patterns:
- 0x1: Success
- 0x3: Partial success
- 0x7: Warnings
- 0xF: Errors/failures
- Blinking: Progress indicator
```

**LED Blink Codes**:
```
1 blink  = Permissive mode
3 blinks = Strict mode
5 blinks = Research mode

After test completion:
N blinks = N tests passed
```

### **Software Logging**

**Result Structure**:
```c
typedef struct {
    uint32_t test_id;
    uint32_t expected_anomalies;
    uint32_t detected_anomalies;
    uint32_t execution_time;
    bool passed;
} test_result_t;
```

**Metrics Collected**:
- Instruction count
- Total cycles
- Anomalies detected
- False positive/negative counts
- Average cycles per instruction
- Performance overhead

---

## **🔍 Analysis Framework**

### **1. Timing Precision Analysis**

Calculate standard deviation:
```
σ = sqrt(Σ(xi - μ)² / N)
Precision = (σ / μ) × 100%
```

**Interpretation**:
- < 5%: Excellent precision
- 5-10%: Good precision
- > 10%: Poor precision (investigate)

### **2. Detection Rate Analysis**

```
True Positive Rate (TPR) = TP / (TP + FN)
False Positive Rate (FPR) = FP / (FP + TN)
Accuracy = (TP + TN) / (TP + TN + FP + FN)
```

**ROC Curve**: Plot TPR vs. FPR for different thresholds

### **3. Performance Impact**

```
Overhead% = ((T_ets - T_baseline) / T_baseline) × 100%
```

**Acceptable Ranges**:
- IoT devices: < 10%
- Real-time systems: < 5%
- High-performance: < 2%

---

## **📊 Expected Results**

### **Summary Table**

| Test | Metric | Expected | Acceptable Range |
|------|--------|----------|------------------|
| 1. Timing Accuracy | Avg cycles/instr | 2-3 | 2-5 |
| 2. False Positives | FP rate | < 5% | < 10% |
| 3. Attack Detection | TP rate | > 70% | > 60% |
| 4. Performance | Overhead | < 5% | < 10% |
| 5. Crypto Validation | Ratio (var/const) | > 2.0 | > 1.5 |
| 6. Learning Mode | Anomaly reduction | > 80% | > 70% |
| 7. Stress Test | Completion | Yes | - |

### **Pass/Fail Criteria**

**Overall System Grade**:
- **A (Excellent)**: All tests pass expected values
- **B (Good)**: All tests within acceptable range
- **C (Fair)**: 5+ tests within acceptable range
- **F (Fail)**: < 5 tests pass

---

## **🚀 How to Run Tests**

### **Option 1: Interactive Interface**

```bash
cd software/firmware/tests
./build.ps1 interactive_interface
cd ../../../
./generate_firmware_init.ps1 -hexFile "software/firmware/tests/test_basic.hex"
vivado -mode batch -source build.tcl
vivado -mode batch -source program.tcl
```

**Interaction**:
- Use switches/buttons on Zybo board
- Watch LED patterns for feedback
- Cycle through modes and tests

### **Option 2: Automated Research Tests**

```bash
cd software/firmware/tests
./build.ps1 research_tests
cd ../../../
./generate_firmware_init.ps1 -hexFile "software/firmware/tests/research_tests.hex"
vivado -mode batch -source build.tcl
vivado -mode batch -source program.tcl
```

**Observation**:
- LEDs show test progress (1-7)
- Final LED pattern indicates overall result
- Count blinks for passed tests

### **Option 3: Individual Test**

Modify `research_tests.c` to run specific test:
```c
int main(void) {
    ets_init(ETS_MODE_FINE_GRAINED);
    
    // Run single test
    research_test_timing_accuracy();
    
    while(1) { /* hold */ }
}
```

---

## **📝 Data Logging & Analysis**

### **Manual Data Recording**

Create observation log:
```
Test Run: [Date/Time]
Configuration: [Permissive/Strict/Research]
Board: Zybo Z7-10

Test 1 - Timing Accuracy:
  - LED Pattern: 0x1 (pass)
  - Observed: [notes]

Test 2 - False Positives:
  - LED Pattern: 0x3 (partial)
  - Observed: [notes]

...
```

### **Future: UART Logging**

**Planned enhancement**:
```c
void uart_log_result(test_result_t* result) {
    uart_printf("Test %d: %s\n", 
                result->test_id, 
                result->passed ? "PASS" : "FAIL");
    uart_printf("  Anomalies: %d\n", result->detected_anomalies);
    uart_printf("  Time: %d cycles\n", result->execution_time);
}
```

---

## **🎓 Research Applications**

### **1. Academic Papers**

**Potential Contributions**:
- Hardware-based timing attack mitigation
- IoT security enhancement
- Side-channel attack detection
- Constant-time validation

### **2. Industrial Applications**

**Use Cases**:
- Secure IoT devices
- Cryptographic accelerators
- Safety-critical systems
- Anomaly detection

### **3. Further Research**

**Extensions**:
- Machine learning for signature generation
- Multi-core ETS monitoring
- Power consumption analysis
- Formal verification

---

## **📚 References**

1. **Timing Attacks**: Kocher, P. (1996). "Timing Attacks on Implementations of Diffie-Hellman, RSA, DSS, and Other Systems"

2. **Side-Channel Analysis**: Mangard, S., et al. (2007). "Power Analysis Attacks: Revealing the Secrets of Smart Cards"

3. **Constant-Time Programming**: Almeida, J.B., et al. (2016). "Verifying Constant-Time Implementations"

4. **RISC-V Security**: Ferraiuolo, A., et al. (2018). "Secure Speculation for Weakly Speculative Processors"

---

## **✅ Validation Checklist**

- [ ] All 7 tests implemented
- [ ] LED feedback working
- [ ] Data structures logging results
- [ ] Multiple configurations tested (permissive/strict/research)
- [ ] Reproducibility verified (3+ runs)
- [ ] Results documented
- [ ] Analysis completed
- [ ] Pass/fail criteria met

---

## **🆘 Troubleshooting**

### **Issue**: No LED activity
**Solution**: Check board power, programming, clock

### **Issue**: All tests fail
**Solution**: Verify ETS initialization, check signatures

### **Issue**: Inconsistent results
**Solution**: Increase sample size, check for interference

### **Issue**: High false positive rate
**Solution**: Adjust tolerance in signature configuration

---

## **📧 Contact & Support**

For questions about the research methodology or results interpretation:
- Review `docs/ets_specification.md`
- Check `STATUS.md` for known issues
- Examine `software/firmware/common/ets_lib.h` for API details

**Good luck with your research! 🚀**

