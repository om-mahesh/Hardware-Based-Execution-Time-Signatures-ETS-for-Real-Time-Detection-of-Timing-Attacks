# Execution Time Signatures (ETS) - Detailed Specification

## 1. Introduction

**Execution Time Signatures (ETS)** is a hardware security mechanism that monitors instruction execution time to detect anomalies, prevent timing side-channel attacks, and identify malicious hardware modifications.

## 2. Threat Model

### 2.1 Attacks Mitigated

1. **Timing Side-Channel Attacks**
   - Cache-timing attacks (e.g., Spectre, Meltdown variants)
   - RSA/AES key extraction via timing analysis
   - Branch prediction timing leaks

2. **Fault Injection Attacks**
   - Clock glitching causing instruction timing variations
   - Voltage glitching affecting execution speed
   - Electromagnetic interference

3. **Hardware Trojans**
   - Malicious logic causing selective delays
   - Backdoors triggered by specific instruction sequences
   - Performance degradation attacks

### 2.2 Assumptions

- IoT devices perform repetitive, predictable tasks
- Normal execution timing is stable and characterizable
- Attacker cannot perfectly mimic timing signatures
- False positives are acceptable (better safe than sorry)

## 3. ETS Architecture

### 3.1 Monitoring Granularity

We implement **instruction-level monitoring** with three modes:

| Mode | Granularity | Use Case |
|------|-------------|----------|
| **Fine** | Per instruction | Crypto operations, critical code |
| **Coarse** | Per basic block (5-10 instr) | General IoT tasks |
| **Task** | Per complete task | High-level anomaly detection |

### 3.2 Hardware Components

#### 3.2.1 Cycle Counter
```
Input:  
  - clk: System clock
  - rst_n: Active-low reset
  - instr_valid: Instruction executing
  - instr_done: Instruction complete
  
Output:
  - cycle_count[31:0]: Elapsed cycles
  
Behavior:
  - Resets on instruction start (instr_valid && !instr_done)
  - Increments every cycle while executing
  - Latches value when instruction completes
```

#### 3.2.2 Signature Database
```
Type: Block RAM or Register File
Size: 32 entries × 32 bits (expandable)

Entry Format (32 bits):
  [31:24] - Opcode/Instruction ID
  [23:16] - Expected cycles (mean)
  [15:8]  - Tolerance (+/- cycles)
  [7:0]   - Flags (enable, interrupt, etc.)

Access:
  - Write: Memory-mapped configuration interface
  - Read: Indexed by current instruction opcode
```

#### 3.2.3 Comparator
```
Input:
  - actual_cycles[31:0]: From cycle counter
  - expected_cycles[7:0]: From signature DB
  - tolerance[7:0]: From signature DB
  
Output:
  - anomaly_detected: 1-bit flag
  - timing_delta[31:0]: Signed difference
  
Logic:
  if (actual_cycles > expected_cycles + tolerance ||
      actual_cycles < expected_cycles - tolerance) {
    anomaly_detected = 1;
  }
```

#### 3.2.4 Alert Controller
```
Input:
  - anomaly_detected: From comparator
  - alert_config[7:0]: Configuration register
    [0] - Enable alerts
    [1] - Generate interrupt
    [2] - Halt processor
    [3] - Log to buffer
    [7:4] - Reserved
    
Output:
  - alert_flag: GPIO/LED output
  - alert_interrupt: To processor interrupt line
  - halt_request: To processor control
  
Behavior:
  - Maintains circular log buffer (32 entries)
  - Each entry: {PC, opcode, actual_cycles, timestamp}
  - Interrupt priority configurable
```

### 3.3 Memory Map

```
Base Address: 0x80000000 (example)

Offset | Register Name          | Description
-------|------------------------|----------------------------------
0x000  | ETS_CTRL               | Control register (enable, mode)
0x004  | ETS_STATUS             | Status register (alert count)
0x008  | ETS_INTR_EN            | Interrupt enable mask
0x00C  | ETS_ALERT_CONFIG       | Alert behavior configuration
0x010  | ETS_CURRENT_CYCLES     | Current instruction cycle count
0x014  | ETS_LAST_ANOMALY_PC    | PC of last anomaly
0x018  | ETS_LAST_ANOMALY_DELTA | Timing delta of last anomaly
0x01C  | ETS_ANOMALY_COUNT      | Total anomalies detected
0x100-0x1FF | ETS_SIGNATURE_DB  | Timing signature entries (64 × 4B)
0x200-0x3FF | ETS_LOG_BUFFER    | Anomaly log buffer (128 entries)
```

### 3.4 Register Specifications

#### ETS_CTRL (0x000)
```
[31:8]  - Reserved
[7:4]   - Monitoring mode
          0000 = Disabled
          0001 = Fine-grained (per instruction)
          0010 = Coarse-grained (per block)
          0011 = Task-level
[3]     - Learning mode (auto-build signatures)
[2]     - Clear log buffer
[1]     - Clear anomaly count
[0]     - Enable ETS
```

#### ETS_STATUS (0x004)
```
[31:16] - Total anomalies detected (saturating counter)
[15:8]  - Reserved
[7:0]   - Status flags
          [0] - Alert active
          [1] - Interrupt pending
          [2] - Log buffer full
          [3] - Learning in progress
          [7:4] - Reserved
```

## 4. Operating Modes

### 4.1 Learning Mode

**Purpose**: Automatically build timing signature database during normal operation.

**Procedure**:
1. Enable learning mode (ETS_CTRL[3] = 1)
2. Run typical IoT workload repeatedly (10-100 iterations)
3. ETS module captures timing statistics:
   - Mean cycles per instruction
   - Standard deviation
   - Min/max cycles
4. Calculate tolerance: `tolerance = mean + 3*stddev`
5. Store in signature database
6. Disable learning mode

**Example Code**:
```c
// Enable ETS learning mode
ETS_CTRL = (1 << 3) | (1 << 0);

// Run workload
for (int i = 0; i < 100; i++) {
    perform_iot_task();
}

// Finalize signatures
ETS_CTRL = (1 << 0); // Normal monitoring mode
```

### 4.2 Enforcement Mode

**Purpose**: Actively monitor and alert on timing violations.

**Behavior**:
- Compare every instruction against signature database
- Raise alerts on violations
- Optionally halt processor or trigger interrupt

**Detection Latency**: 1-3 cycles after instruction completion

### 4.3 Logging Mode

**Purpose**: Collect timing data for offline analysis.

**Log Entry Format** (8 bytes):
```
[63:48] - Timestamp (16-bit cycle counter)
[47:32] - Program Counter (PC)
[31:24] - Opcode
[23:8]  - Actual cycles
[7:0]   - Expected cycles
```

**Buffer**: Circular, 128 entries (1KB RAM)

## 5. Integration with RISC-V Core

### 5.1 Signal Connections

#### From RISC-V Core to ETS:
```verilog
// Execution signals
wire        instr_valid;    // Instruction is executing
wire        instr_done;     // Instruction completed
wire [31:0] instr_pc;       // Program counter
wire [31:0] instr_opcode;   // Current instruction
wire [6:0]  instr_type;     // Decoded instruction type

// Memory interface (for config access)
wire        mem_wr_en;
wire [31:0] mem_addr;
wire [31:0] mem_wdata;
wire [31:0] mem_rdata;
```

#### From ETS to RISC-V Core:
```verilog
wire alert_interrupt;       // Timing anomaly interrupt
wire halt_request;          // Request processor halt (optional)
```

### 5.2 PicoRV32 Integration Points

**Instruction Valid**: `picorv32.v` - `instr_valid` signal (already exists)
**Instruction Done**: `picorv32.v` - `instr_done` signal (already exists)
**PC**: `picorv32.v` - `reg_pc` (may need to export)

**Modification Required**: Export internal signals to top-level ports.

### 5.3 VexRiscv Integration Points

VexRiscv has explicit pipeline stages - easier integration:
- `execute.arbitration.isValid` → instr_valid
- `execute.arbitration.isStuck` → stall indicator
- `execute.PC` → current PC

## 6. Performance Analysis

### 6.1 Area Overhead

| Component | Estimated Area |
|-----------|----------------|
| Cycle Counter | 32 FFs + comparator = 50 LUTs |
| Signature DB (64 entries) | 1 BRAM (18Kb) |
| Comparator Logic | 100 LUTs |
| Alert Controller | 50 LUTs |
| Log Buffer | 1 BRAM (18Kb) |
| **Total** | **~200 LUTs + 2 BRAMs** |

**Percentage on Zybo Z7-10**: ~1.1% LUTs, ~4% BRAM

### 6.2 Timing Overhead

- **Critical Path Addition**: ~1-2 ns (comparator logic)
- **Frequency Impact**: Minimal if ETS is pipelined
- **Detection Latency**: 1-3 clock cycles

### 6.3 Power Overhead

- **Dynamic Power**: ~2-5% (counters switching every cycle)
- **Static Power**: Negligible

## 7. Software API

### 7.1 C Library (`ets_lib.h`)

```c
// Initialize ETS module
void ets_init(ets_mode_t mode);

// Configure timing signature for instruction type
void ets_set_signature(uint8_t instr_id, uint8_t cycles, uint8_t tolerance);

// Enable/disable monitoring
void ets_enable(bool enable);

// Read anomaly count
uint32_t ets_get_anomaly_count(void);

// Read last anomaly details
void ets_get_last_anomaly(uint32_t *pc, int32_t *delta);

// Clear log buffer
void ets_clear_log(void);

// Run learning mode on function
void ets_learn_function(void (*func)(void), int iterations);
```

### 7.2 Example Usage

```c
#include "ets_lib.h"

void secure_crypto_operation(uint8_t *key, uint8_t *data) {
    // Enable fine-grained monitoring for this critical function
    ets_enable(true);
    
    // Perform crypto
    aes_encrypt(key, data);
    
    // Check for timing anomalies
    if (ets_get_anomaly_count() > 0) {
        // Timing attack detected!
        trigger_security_alert();
        wipe_sensitive_data();
    }
}
```

## 8. Test Cases

### 8.1 Functional Tests

1. **Normal Operation**: Verify no false positives on regular code
2. **Anomaly Detection**: Inject delays, verify detection
3. **Learning Mode**: Build signatures, verify accuracy
4. **Interrupt Generation**: Verify interrupt triggered on anomaly
5. **Log Buffer**: Fill buffer, verify circular behavior

### 8.2 Security Tests

1. **Cache Timing Attack Simulation**: Vary memory access patterns
2. **Clock Glitch Injection**: Slow down specific instructions
3. **Statistical Analysis**: Measure false positive/negative rates

## 9. Future Enhancements

1. **Machine Learning**: Neural network for anomaly detection
2. **Multi-Core Support**: Synchronize ETS across cores
3. **Compressed Signatures**: Reduce memory footprint
4. **Runtime Adaptation**: Adjust thresholds based on temperature, voltage
5. **Integration with TEE**: Secure monitoring in trusted execution environments

## 10. References

- [Timing Attack Research](https://cr.yp.to/antiforgery.html)
- [RISC-V Security Extensions](https://github.com/riscv/riscv-security-model)
- [Hardware Security Monitoring](https://cseweb.ucsd.edu/~mihir/papers/timing.html)

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-02

