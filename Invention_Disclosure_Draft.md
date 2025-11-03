# Invention Disclosure Draft (For Patent Filing)

- Title of Invention: Hardware-Based Execution Time Signatures (ETS) for Real-Time Detection of Timing Attacks in Embedded RISC-V Systems
- Inventor(s): [Your full name], [Co-inventor names]
- Affiliation(s): [Dept], [Institution/Company], [City, Country]
- Contact Email(s): [email@domain]
- Date of First Conception: [YYYY-MM-DD]
- Date of First Reduction to Practice (Prototype Working): [YYYY-MM-DD]
- Funding/Grant Info: [If any; else “None”]
- Third-Party IP/Obligations: [If any; else “None”]

## 1. Field of the Invention

This invention relates to hardware security for embedded and IoT systems, specifically to hardware mechanisms that monitor instruction-level execution timing to detect timing side-channel vulnerabilities and anomalous execution, with application to RISC-V and similar processor architectures.

## 2. Background (Problem Addressed)

Timing attacks exploit variations in execution time to infer secrets in cryptographic and other sensitive computations. Software-based mitigations (e.g., constant-time programming, random delays, blinding) are error-prone, impose high performance costs, and can be undermined by compiler optimizations or microarchitectural effects. There is a need for a low-overhead, hardware-enforced mechanism that validates and enforces timing behavior of code on resource-constrained devices.

## 3. Summary of the Invention (What is new and useful)

The invention introduces Execution Time Signatures (ETS), a hardware module integrated with a processor that:
- Measures instruction execution time at runtime using a cycle counter tightly coupled to instruction lifecycle signals.
- Maintains a signature database indexed by program counter (PC) and instruction class, storing expected cycle counts and tolerances learned during a controlled “learning mode.”
- Compares actual timing against the signature in real time; deviations beyond tolerance raise alerts and increment an anomaly counter.
- Exposes memory-mapped control/status registers to firmware for configuration (tolerance, learning/monitoring mode, clearing counters) and telemetry (anomaly count, last anomaly PC).
- Operates non-intrusively with negligible performance/area/power overhead, suitable for IoT-class devices.

Key novelty lies in the concrete hardware architecture for instruction-level timing signature learning and enforcement, its comparator logic and alert semantics, and its specific integration to a RISC-V memory interface (e.g., PicoRV32 `mem_valid`, `mem_ready`, `mem_instr`) to infer instruction boundaries without modifying the ISA.

## 4. Detailed Description of the Invention

### 4.1 System Architecture
- Processor core: RISC-V (PicoRV32) integrated on FPGA (Zynq-7000, Zybo Z7-10 board).
- ETS module sub-blocks:
  1) Cycle Counter: Synchronous counter reset on instruction start; accumulates during `instr_active`; latches on `instr_done`.
  2) Signature Database: Small CAM/RAM indexed by PC/instruction type storing (expected_cycles, tolerance, valid). Learning mode populates entries; monitoring mode performs lookups.
  3) Comparator: Computes |actual_cycles − expected_cycles| > tolerance; on true, asserts anomaly signal.
  4) Alert Controller: Increments anomaly counter; latches last anomaly PC; exposes alert/clear bits.
- Bus/CSR Interface: Memory-mapped registers at 0x6000_0000 region, including Control, Anomaly Count, Last PC, Tolerance, Learning Mode.
- UART Telemetry (optional embodiment): Memory-mapped UART at 0x8000_0000 for live reporting.

### 4.2 Instruction Lifecycle Signals (One Embodiment with PicoRV32)
- `mem_valid && mem_instr` denotes instruction fetch phase; `mem_valid && mem_ready && mem_instr` denotes instruction acceptance/completion.
- `instr_start = mem_valid && mem_instr && mem_ready`, `instr_active = mem_valid && !mem_ready` used to define counter gating.

### 4.3 Modes of Operation
- Learning Mode: System observes benign executions to populate the signature DB per PC/instruction class.
- Monitoring Mode: Real-time comparison and anomaly detection; firmware adjustable tolerance.

### 4.4 Example Memory Map
- 0x6000_0000: Control (enable/clear)
- 0x6000_0004: Anomaly Count (RO)
- 0x6000_0008: Last Anomaly PC (RO)
- 0x6000_000C: Tolerance (RW)
- 0x6000_0010: Learning Mode (RW)

### 4.5 Implementation Footprint (One FPGA Embodiment)
- Overheads: ~1.6% performance, ~0.9% power, <2% LUTs, 2 BRAMs (measured on Zybo Z7-10).

## 5. Advantages Over Prior Art
- Hardware-based, non-bypassable detection of timing variations at instruction granularity.
- Transparent to software and ISA; no compiler or source code changes required.
- Low overhead, suitable for IoT devices; enables in-field validation and runtime protection.
- Provides quantitative validation for constant-time claims and detects regressions.

## 6. Example Use Cases
- Validating constant-time cryptographic routines (AES/SHA/RSA) on embedded processors.
- Detecting data-dependent branches or table lookups that leak secrets via timing.
- Runtime anomaly detection for safety/security-critical loops in IoT/industrial devices.

## 7. Experimental Evidence (Prototype Data)
- Platform: PicoRV32 @125 MHz on Zybo Z7-10; ETS integrated.
- Constant-time tests: XOR/Rotate/Add show ~2.0 anomalies per 100 ops.
- Variable-time tests: Conditional/Substitution/Early-exit show ~18.3 anomalies per 100 ops.
- Discrimination ratio: ~9.15×; classification accuracy 100% across tested kernels.

## 8. Alternatives and Variations
- Different cores/ISAs: ETS integrates to other RISC-V cores or ARM/MIPS via analogous pipeline/memory signals.
- Alternative signature keys: broader context (basic block hash, instruction window) instead of PC-only.
- Mitigation: optional auto-response (insert fixed padding, throttle, or halt on repeated anomalies).
- Storage: signatures in on-chip RAM or NVM; size scalable with application.

## 9. Prior Art and How This Differs
- Software constant-time verification tools (ct-verif, etc.) do not enforce at runtime on-device.
- Noise injection/random delays impose high overhead and are statistically removable.
- Control-flow monitors do not measure execution-time deviation per instruction.
- Claimed novelty: specific hardware pipeline-level signature learning and thresholding for instruction-time enforcement with PC-indexed signatures and tolerance configuration, integrated non-intrusively via existing memory interface signaling.

## 10. Disclosure/Publication Timeline
- Internal prototype working: [date]
- Repository visibility: [Private/Public; if public, date of first public access]
- Paper draft prepared (not publicly posted): 2025-11-03 (no public enabling disclosure yet)
- Conference submission target: [venue & date]

## 11. Commercial Potential
- Licensing to embedded IP vendors and MCU/SoC makers.
- Add-on IP block for RISC-V cores targeting secure IoT.
- Certification and compliance (Common Criteria) support tool.

## 12. Known Risks/Limitations
- Requires learning phase; signature DB capacity vs. code size trade-off.
- Tolerance tuning to balance FPR/TPR.
- Microarchitectural variability if ported to OoO/speculative cores (mitigations possible).

## 13. Materials Provided
- RTL (Verilog): `rtl/ets_module/*.v`, integration in `rtl/top/*`.
- Firmware and experiments: `software/firmware/*`.
- Bitstream and build scripts; UART telemetry for logs.

## 14. Inventor Declarations
- Each inventor contributed to at least one of: ETS architecture, signature DB design, comparator/alert design, RISC-V integration, experiments.
- No prior assignment beyond standard institutional IP policy. [Adjust if sponsored/consulting applies.]

---

### Action Items to Complete Before Filing
- Confirm inventors and contribution dates.
- Ensure repo remains private until provisional is filed.
- File provisional patent (US/in-country) immediately; consider PCT within 12 months.
- Coordinate with TTO/Patent counsel; attach this draft to `InventionDisclosureFormIITMandi.docx`.
