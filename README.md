# Hardware-Based Execution Time Signatures (ETS) for Real-Time Detection of Timing Attacks

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![RISC-V](https://img.shields.io/badge/RISC--V-Open-green.svg)](https://riscv.org/)
[![FPGA](https://img.shields.io/badge/FPGA-Xilinx%20Zynq-blue.svg)](https://www.xilinx.com/)

> A novel hardware-based security mechanism that monitors instruction-level execution timing in RISC-V processors to detect timing side-channel attacks with negligible overhead (<2%).

## 📋 Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Hardware Implementation](#hardware-implementation)
- [Software Toolchain](#software-toolchain)
- [Experimental Results](#experimental-results)
- [Publications](#publications)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

**Execution Time Signatures (ETS)** is a hardware security module that monitors instruction-level execution timing in real-time to detect timing-dependent code paths indicative of security vulnerabilities. This implementation integrates ETS with a RISC-V processor core (PicoRV32) on a Xilinx Zynq-7000 FPGA platform.

### Problem Addressed

Timing attacks exploit execution time variations to extract secrets from cryptographic implementations. Existing software-based defenses:
- Rely on developer discipline and are error-prone
- Introduce significant performance overhead (20-300%)
- Can be undermined by compiler optimizations and microarchitectural features
- Are difficult to verify for constant-time properties

### Our Solution

ETS provides:
- ✅ **Hardware-enforced** timing monitoring that cannot be bypassed
- ✅ **Low overhead**: <2% performance, <1% power, <2% FPGA area
- ✅ **Real-time detection** of timing anomalies during execution
- ✅ **100% classification accuracy** distinguishing constant-time vs. variable-time implementations
- ✅ **9.15× discrimination ratio** between secure and vulnerable code

## ✨ Key Features

- **Instruction-Level Monitoring**: Tracks execution timing for each instruction via cycle counter
- **Signature Database**: Stores expected timing signatures indexed by Program Counter (PC)
- **Real-Time Detection**: Compares actual vs. expected timing with configurable tolerance
- **Non-Intrusive**: Operates transparently without modifying processor ISA
- **Memory-Mapped Interface**: Software-configurable via memory-mapped registers
- **UART Telemetry**: Built-in serial communication for data collection
- **Learning Mode**: Populates signature database during benign execution
- **Monitoring Mode**: Detects anomalies in production code

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    RISC-V Processor Core                     │
│                  (PicoRV32 - RV32I ISA)                      │
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                │
│  │  Fetch Unit  │────────►│ Decode Unit  │                │
│  └──────────────┘         └──────┬───────┘                │
│                                   │                         │
│  ┌──────────────┐         ┌──────▼───────┐                │
│  │Memory Access │◄────────│ Execute Unit │                │
│  └──────────────┘         └───────────────┘                │
└─────────────────────────────────┬───────────────────────────┘
                                  │
                      ┌───────────▼───────────────┐
                      │   ETS Monitor Module     │
                      │  ┌────────────────────┐  │
                      │  │ Cycle Counter      │  │
                      │  │ (measures instr)   │  │
                      │  └─────────┬──────────┘  │
                      │  ┌─────────▼──────────┐  │
                      │  │ Signature DB      │  │
                      │  │ (expected timings)│  │
                      │  └─────────┬──────────┘  │
                      │  ┌─────────▼──────────┐  │
                      │  │ Comparator        │  │
                      │  │ (threshold check) │  │
                      │  └─────────┬──────────┘  │
                      │  ┌─────────▼──────────┐  │
                      │  │ Alert Controller  │  │
                      │  │ (anomaly counter) │  │
                      │  └──────────────────┘  │
                      └────────────────────────┘
                                  │
                      ┌───────────▼───────────────┐
                      │  Memory-Mapped Registers  │
                      │  0x60000000: Control      │
                      │  0x60000004: Anomaly Count│
                      │  0x60000008: Last PC      │
                      └───────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Vivado** 2020.1 or later (for FPGA synthesis)
- **RISC-V GNU Toolchain** (for software compilation)
- **Zybo Z7-10** FPGA board (or compatible Xilinx Zynq-7000)
- **Python 3.8+** (for build scripts)

### Hardware Setup

1. **Clone the repository**:
```bash
git clone https://github.com/om-mahesh/Hardware-Based-Execution-Time-Signatures-ETS-for-Real-Time-Detection-of-Timing-Attacks.git
cd Hardware-Based-Execution-Time-Signatures-ETS-for-Real-Time-Detection-of-Timing-Attacks
```

2. **Build FPGA bitstream**:
```bash
vivado -mode batch -source build.tcl
```

3. **Program FPGA**:
```bash
vivado -mode batch -source program.tcl
```

### Software Compilation

1. **Setup RISC-V toolchain** (Windows PowerShell):
```powershell
cd software/toolchain
.\setup_env.ps1
```

2. **Compile test programs**:
```powershell
cd software/firmware/tests
.\build.ps1 test_basic
```

3. **Generate firmware initialization**:
```powershell
cd ../..
.\generate_firmware_init.ps1 software/firmware/tests/test_basic.hex
```

4. **Rebuild FPGA with firmware**:
```bash
vivado -mode batch -source build.tcl
```

## 💻 Hardware Implementation

### FPGA Platform
- **Board**: Digilent Zybo Z7-10
- **FPGA**: Xilinx XC7Z010-1CLG400C (Zynq-7000)
- **Clock**: 125 MHz system clock
- **Memory**: 16 KB Block RAM

### Resource Utilization

| Resource | Used | Overhead |
|----------|------|----------|
| LUTs     | 1,247 | 1.8% |
| FFs      | 983  | 1.2% |
| BRAM     | 2 blocks | 0.5% |
| Power    | 8 mW | 0.9% |

### ETS Module Components

- **`cycle_counter.v`**: Instruction-level cycle counting
- **`signature_db.v`**: PC-indexed signature database
- **`comparator.v`**: Timing deviation detection
- **`alert_controller.v`**: Anomaly reporting and counting
- **`ets_monitor.v`**: Top-level ETS module

## 📊 Experimental Results

### Detection Accuracy

| Implementation | Type | Anomalies/100 ops | Status |
|----------------|------|-------------------|--------|
| XOR Cipher | Constant | 2.1 ± 0.8 | ✅ Pass |
| Rotate Cipher | Constant | 1.3 ± 0.6 | ✅ Pass |
| Addition Cipher | Constant | 2.8 ± 1.1 | ✅ Pass |
| Conditional Cipher | Variable | 18.4 ± 2.3 | ⚠️ Detected |
| Substitution Cipher | Variable | 24.7 ± 3.1 | ⚠️ Detected |
| Early-Exit Compare | Variable | 11.8 ± 1.9 | ⚠️ Detected |

**Key Metrics:**
- **False Positive Rate**: 2.0 anomalies/100 ops (constant-time)
- **True Positive Rate**: 18.3 anomalies/100 ops (variable-time)
- **Discrimination Ratio**: 9.15×
- **Classification Accuracy**: 100%

### Performance Overhead

| Benchmark | Baseline | With ETS | Overhead |
|-----------|----------|----------|----------|
| XOR Cipher | 12.4 ms | 12.6 ms | 1.6% |
| AES SubBytes | 48.2 ms | 49.1 ms | 1.9% |
| SHA-256 Round | 31.7 ms | 32.1 ms | 1.3% |

**Average Overhead**: 1.6%

## 📄 Publications

- **IEEE Conference Paper**: [paper/ets_ieee_paper.pdf](paper/ets_ieee_paper.pdf)
  - Title: "ETS: Hardware-Based Execution Time Signatures for Real-Time Detection of Timing Attacks in IoT Devices"
  - Status: Draft (Ready for submission)

## 📁 Project Structure

```
.
├── README.md                      # This file
├── docs/                          # Documentation
│   ├── ets_specification.md      # Detailed ETS specification
│   ├── RESEARCH_TESTING_GUIDE.md  # Research experiment guide
│   ├── EXPERIMENTATION_GUIDE.md   # Configuration experiments
│   └── UART_GUIDE.md              # UART interface documentation
├── rtl/                           # Hardware source (Verilog)
│   ├── ets_module/                # ETS core modules
│   │   ├── cycle_counter.v
│   │   ├── signature_db.v
│   │   ├── comparator.v
│   │   ├── alert_controller.v
│   │   └── ets_monitor.v
│   ├── riscv_core/picorv32/       # PicoRV32 RISC-V core
│   ├── uart/                      # UART interface
│   └── top/                       # Top-level integration
│       ├── ets_riscv_top.v
│       └── zybo_z7_top.v
├── constraints/                   # FPGA constraints
│   └── zybo_z7.xdc
├── software/                      # Software toolchain & firmware
│   ├── toolchain/                 # RISC-V GCC setup
│   └── firmware/                  # Test programs & libraries
│       ├── common/                # ETS library, UART, startup
│       ├── tests/                 # Basic test programs
│       └── experiments/          # Research experiments
│           ├── config_optimization.c
│           └── crypto_validation.c
├── paper/                         # IEEE paper LaTeX source
│   ├── ets_ieee_paper.tex
│   ├── ets_ieee_paper.pdf
│   └── README.md
├── sim/                           # Simulation testbenches
│   └── tb_ets_monitor.v
├── tools/                         # Analysis scripts
│   ├── analyze_results.py
│   └── run_research_test.ps1
├── build.tcl                      # Vivado build script
└── program.tcl                   # FPGA programming script
```

## 🔬 Research Experiments

The repository includes comprehensive research experiments:

1. **Configuration Optimization**: Tests different ETS tolerance settings to find optimal security/performance trade-offs
2. **Crypto Validation**: Detects timing leaks in cryptographic implementations (constant-time vs. variable-time)

See [docs/RESEARCH_TESTING_GUIDE.md](docs/RESEARCH_TESTING_GUIDE.md) for details.

## 🤝 Contributing

Contributions are welcome! Areas of interest:
- Support for additional RISC-V cores
- Extended experiments and benchmarks
- Integration with other security mechanisms
- Documentation improvements

Please follow standard Git workflow:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Note**: The PicoRV32 RISC-V core maintains its original license (see `rtl/riscv_core/picorv32/COPYING`).

## 🙏 Acknowledgments

- **PicoRV32** developers for the open-source RISC-V core
- **RISC-V community** for the open architecture enabling this research
- **Xilinx** for FPGA tools and Zynq platform

## 📧 Contact

For questions about this research:
- **Repository Issues**: Use GitHub Issues
- **Academic Inquiries**: [Your email/institution]

---

**⭐ If you find this project useful, please consider giving it a star!**
#   H a r d w a r e - B a s e d - E x e c u t i o n - T i m e - S i g n a t u r e s - E T S - f o r - R e a l - T i m e - D e t e c t i o n - o f - T i m i n g - A t t a c k s  
 