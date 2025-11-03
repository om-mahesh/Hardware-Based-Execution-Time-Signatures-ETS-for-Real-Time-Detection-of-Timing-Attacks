# RISC-V Core Selection Guide

## Overview

This document compares RISC-V implementations suitable for ETS integration on the Zybo Z7-10 FPGA.

## Comparison Matrix

| Core | Size (LUTs) | Performance | Timing Predictability | ETS Integration Difficulty | License | Recommendation |
|------|-------------|-------------|----------------------|---------------------------|---------|----------------|
| **PicoRV32** | 1000-2000 | ~0.5 DMIPS/MHz | ⭐⭐⭐⭐⭐ Excellent | ⭐⭐⭐⭐⭐ Easy | ISC | **BEST** |
| **VexRiscv** | 1500-3000 | ~0.8 DMIPS/MHz | ⭐⭐⭐⭐ Good | ⭐⭐⭐ Medium | MIT | Alternative |
| **SERV** | 200-300 | ~0.1 DMIPS/MHz | ⭐⭐⭐⭐⭐ Excellent | ⭐⭐⭐⭐ Easy | ISC | Learning |
| **Rocket Chip** | 10K-20K | ~1.5 DMIPS/MHz | ⭐⭐⭐ Fair | ⭐ Hard | BSD | Too complex |
| **BOOM** | 20K-50K | ~2.5 DMIPS/MHz | ⭐⭐ Poor | ⭐ Very Hard | BSD | Too complex |
| **CVA6 (Ariane)** | 15K-30K | ~1.7 DMIPS/MHz | ⭐⭐⭐ Fair | ⭐ Hard | SolderPad | Too complex |

## Detailed Analysis

### 1. PicoRV32 ⭐ RECOMMENDED

**Repository**: https://github.com/YosysHQ/picorv32

#### Pros
- ✅ **Simple microarchitecture**: Single-stage or 2-stage pipeline
- ✅ **Highly predictable timing**: No caches, no branch prediction
- ✅ **Small footprint**: Fits easily in Zybo Z7-10
- ✅ **Well-documented**: Clean, readable Verilog
- ✅ **Easy signal extraction**: All pipeline signals easily accessible
- ✅ **Active development**: Maintained by YosysHQ
- ✅ **Proven design**: Used in many production ASICs

#### Cons
- ❌ Lower performance than pipelined cores
- ❌ No MMU/privilege modes (less relevant for IoT)

#### ETS Integration Strategy
```verilog
// PicoRV32 exports these signals naturally:
wire        instr_valid = picorv32_core.mem_valid;
wire        instr_done  = picorv32_core.mem_ready;
wire [31:0] instr_pc    = picorv32_core.reg_pc;
wire [31:0] instr_data  = picorv32_core.mem_rdata_latched;

// Minimal modification needed - just export internal regs to ports
```

#### Configuration for ETS
```verilog
picorv32 #(
    .ENABLE_COUNTERS(1),     // Enable cycle counters (useful for ETS)
    .ENABLE_REGS_16_31(1),   // Full register file
    .ENABLE_IRQ(1),          // Enable interrupts (for ETS alerts)
    .LATCHED_MEM_RDATA(1),   // Stable memory read data
    .TWO_STAGE_SHIFT(1),     // Predictable shift timing
    .CATCH_ILLINSN(1)        // Catch illegal instructions
) riscv_core (
    // ports...
);
```

#### Resource Usage on Zybo Z7-10
- **LUTs**: ~2000 (11% of 17,600)
- **FFs**: ~1500 (4% of 35,200)
- **BRAMs**: 2-4 (for instruction/data memory)
- **Frequency**: 50-100 MHz achievable

---

### 2. VexRiscv (Alternative)

**Repository**: https://github.com/SpinalHDL/VexRiscv

#### Pros
- ✅ **Highly configurable**: Generate exactly what you need
- ✅ **Better performance**: 5-stage pipeline, branch prediction
- ✅ **Modern design**: Written in SpinalHDL (generates Verilog)
- ✅ **Debug support**: JTAG debugging built-in
- ✅ **Privilege modes**: M/S/U modes for secure systems

#### Cons
- ❌ More complex pipeline → less predictable timing
- ❌ Requires Scala/SpinalHDL to customize (learning curve)
- ❌ Generated Verilog harder to read/modify
- ❌ Branch predictor adds timing variability

#### ETS Integration Strategy
VexRiscv's plugin architecture makes integration cleaner:
```scala
// Add ETS monitoring plugin (in Scala)
class EtsMonitorPlugin extends Plugin[VexRiscv] {
  override def build(pipeline: VexRiscv): Unit = {
    import pipeline._
    import pipeline.config._
    
    // Connect to execute stage
    val execute = pipeline.execute
    val etsMonitor = EtsMonitor()
    etsMonitor.io.instrValid := execute.arbitration.isValid
    etsMonitor.io.instrDone := execute.arbitration.isDone
    etsMonitor.io.pc := execute.input(PC)
  }
}
```

#### Configuration for ETS
Use the "minimal" configuration for predictability:
```
VexRiscvGen --csrPluginConfig=all
           --without-branch-prediction
           --without-mul
           --without-div
           --single-cycle-shift
```

#### When to Choose VexRiscv
- Need better performance (2-3× PicoRV32)
- Want privilege modes (M/U separation)
- Comfortable with SpinalHDL
- Can tolerate slightly less predictable timing

---

### 3. SERV (Educational)

**Repository**: https://github.com/olofk/serv

#### Pros
- ✅ **World's smallest RISC-V**: Only ~200 LUTs
- ✅ **Bit-serial execution**: Extremely predictable timing
- ✅ **Every instruction takes 32+ cycles**: Perfect for ETS learning
- ✅ **Simple design**: Great for understanding RISC-V

#### Cons
- ❌ Very slow (32× slower than PicoRV32)
- ❌ Not practical for real applications
- ❌ Limited peripheral support

#### Use Case
**Recommended for**: Learning ETS concepts, prototyping timing algorithms

#### Integration
```verilog
// SERV executes bit-serially, so timing is ultra-predictable:
// ADD: always 33 cycles
// LOAD: always 33 + memory_latency cycles
// Easy to build comprehensive timing database
```

---

### 4. Rocket Chip (Not Recommended)

**Repository**: https://github.com/chipsalliance/rocket-chip

#### Why Not Suitable
- ❌ Requires Chisel3/Scala toolchain
- ❌ 10K-20K LUTs (too large for Zybo Z7-10 with ETS)
- ❌ Complex 5-stage pipeline with caches
- ❌ Caches make timing highly variable
- ❌ Overkill for IoT use cases

---

### 5. BOOM (Not Recommended)

**Repository**: https://github.com/riscv-boom/riscv-boom

#### Why Not Suitable
- ❌ Out-of-order execution → timing chaos
- ❌ 20K-50K LUTs (won't fit)
- ❌ Designed for high performance, not predictability
- ❌ Completely unsuitable for ETS concept

---

## Decision Matrix for Your Project

| Requirement | PicoRV32 | VexRiscv | SERV |
|-------------|----------|----------|------|
| Fits in Zybo Z7-10 | ✅ Yes | ✅ Yes | ✅ Yes |
| Timing Predictability | ✅✅✅ Excellent | ✅✅ Good | ✅✅✅ Perfect |
| IoT Performance | ✅✅ Adequate | ✅✅✅ Good | ❌ Too slow |
| Easy Modification | ✅✅✅ Very Easy | ✅ Medium | ✅✅ Easy |
| Production Ready | ✅✅✅ Yes | ✅✅✅ Yes | ❌ Educational |
| **Overall for ETS** | **9/10** | **7/10** | **5/10** |

---

## Final Recommendation

### For Your ETS Implementation: **PicoRV32**

**Rationale**:
1. **Perfect timing predictability**: No caches, no branch prediction, no out-of-order execution
2. **Ease of integration**: Verilog code is readable and modifiable
3. **Proven for embedded**: Used in real silicon (e.g., Lattice iCE40 projects)
4. **Size**: Leaves room for ETS module and peripherals
5. **Frequency**: 50-100 MHz is perfect for IoT workloads
6. **Learning curve**: Minimal - just read the Verilog

### Alternative Path: **VexRiscv**

Choose VexRiscv if:
- You need 2-3× better performance
- You're willing to learn SpinalHDL
- Your IoT tasks are computationally intensive
- You want privilege separation (M/U modes)

**Note**: VexRiscv's pipeline adds timing variability, so ETS thresholds must be more permissive.

---

## Getting Started with PicoRV32

### Clone the Repository
```bash
cd rtl/riscv_core
git clone https://github.com/YosysHQ/picorv32.git
```

### Key Files
- `picorv32.v` - Main CPU core (read this first!)
- `testbench.v` - Example testbench
- `firmware/` - Example C programs
- `dhrystone/` - Performance benchmark

### Required Modifications for ETS
1. **Export internal signals**:
   ```verilog
   // Add to picorv32 module ports:
   output reg [31:0] dbg_pc,
   output reg        dbg_instr_valid,
   output reg        dbg_instr_done
   ```

2. **Connect to internal state**:
   ```verilog
   // Inside picorv32 module:
   assign dbg_pc = reg_pc;
   assign dbg_instr_valid = decoder_trigger;
   assign dbg_instr_done = !mem_do_rinst && !mem_do_prefetch;
   ```

That's it! Minimal changes needed.

---

## Software Toolchain

All cores use the same **RISC-V GCC toolchain**:

### Download Prebuilt Toolchain
- **Windows**: https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/
- **Linux**: `apt install gcc-riscv64-unknown-elf`
- **macOS**: `brew install riscv-tools`

### Compile for RV32I (PicoRV32)
```bash
riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 \
    -nostdlib -o firmware.elf firmware.c

riscv32-unknown-elf-objcopy -O binary firmware.elf firmware.bin
```

### Convert to Verilog Memory Initialization
```bash
python3 makehex.py firmware.bin > firmware.hex
```

---

## Conclusion

**PicoRV32** is the ideal choice for your ETS implementation:
- Simple, predictable, proven
- Easy to integrate with minimal modifications
- Leaves ample FPGA resources for ETS module
- Perfect for IoT security applications

Start with PicoRV32, get ETS working, then optionally upgrade to VexRiscv if you need more performance.

---

**Next Steps**: See `docs/zybo_z7_guide.md` for FPGA implementation details.

