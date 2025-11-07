# Hardware‑Based Execution Time Signatures (ETS) for Real‑Time Detection of Timing Attacks

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Language: Verilog / SystemVerilog / C / Python](https://img.shields.io/badge/Languages-Mixed-blue.svg)](./)
[![Platform: FPGA / Embedded](https://img.shields.io/badge/Platform-FPGA%2FEmbedded-green.svg)]()

---

## 📘 Table of Contents
1. [Introduction](#introduction)
2. [Motivation](#motivation)
3. [Key Features](#key-features)
4. [Architecture Overview](#architecture-overview)
5. [Repository Structure](#repository-structure)
6. [Quick Start](#quick-start)
7. [Detailed Usage](#detailed-usage)
   - [Hardware Implementation](#hardware-implementation)
   - [Simulation & Verification](#simulation--verification)
   - [Software Integration](#software-integration)
8. [Experiments & Results](#experiments--results)
9. [Contributing](#contributing)
10. [License](#license)
11. [Acknowledgements](#acknowledgements)
12. [Contact](#contact)

---

## 🧩 Introduction
This repository presents a **hardware-based framework** for detecting timing side-channel attacks using **Execution Time Signatures (ETS)**. ETS tracks execution-time variations at the instruction or block level and detects anomalies in real-time through a lightweight FPGA/SoC implementation.

---

## 💡 Motivation
Timing side-channel attacks exploit variations in execution latency to leak secret information (like cryptographic keys). Existing software-based protections incur high overhead or fail to offer runtime guarantees.

**ETS** introduces a hardware-assisted solution — measuring instruction execution time at the hardware level, profiling baseline patterns, and continuously comparing them to detect malicious anomalies in real-time.

---

## 🚀 Key Features
- ⚙️ Real-time monitoring of execution time per instruction.
- 🔐 Hardware-embedded anomaly detection engine.
- 💾 Low-latency data logging with configurable window sizes.
- 🔍 Supports FPGA & Embedded System deployment.
- 📊 Includes simulation testbenches and performance metrics.
- 🔔 On-anomaly alerts with interrupt or logging interface.

---

## 🏗️ Architecture Overview
The ETS architecture consists of four primary modules:

1. **Signature Logger** – Captures timing data for each critical operation.
2. **Baseline Profiler** – Builds a timing profile during safe learning runs.
3. **Anomaly Detector** – Compares current signatures with the baseline using configurable thresholds.
4. **Alert Handler** – Triggers alarms or system interrupts upon detection.

```
┌──────────────────────────┐
│ Target Operation         │
└──────────────┬───────────┘
               │
     ┌─────────▼──────────┐
     │ Signature Logger   │
     └─────────┬──────────┘
               │
     ┌─────────▼──────────┐
     │ Baseline Profiler  │
     └─────────┬──────────┘
               │
     ┌─────────▼──────────┐
     │ Anomaly Detector   │
     └─────────┬──────────┘
               │
     ┌─────────▼──────────┐
     │ Alert / Interrupt  │
     └────────────────────┘
```

---

## 📂 Repository Structure
```
/
├── docs/            → Documentation, design flow, and block diagrams
├── paper/           → Research paper and references
├── rtl/             → Verilog/SystemVerilog source files
├── sim/             → Simulation testbenches and waveform scripts
├── software/        → C/Python firmware for integration
├── tools/           → Utility scripts and data processing
├── constraints/     → Timing and synthesis constraints for FPGA
├── LICENSE          → MIT License
└── README.md        → This file
```

---

## ⚡ Quick Start

### 1️⃣ Clone Repository
```bash
git clone https://github.com/om-mahesh/Hardware-Based-Execution-Time-Signatures-ETS-for-Real-Time-Detection-of-Timing-Attacks.git
cd Hardware-Based-Execution-Time-Signatures-ETS-for-Real-Time-Detection-of-Timing-Attacks
```

### 2️⃣ Build Hardware
Use your preferred FPGA tool (Vivado, Quartus, or Yosys) to synthesize RTL from `rtl/`.

### 3️⃣ Run Simulation
```bash
cd sim/
make run
```
View the results in the generated waveform files.

### 4️⃣ Deploy & Test
Upload the bitstream to your FPGA board and run firmware from `/software/` to interact with the ETS hardware.

---

## 🔬 Detailed Usage

### ⚙️ Hardware Implementation
- Synthesize RTL using FPGA vendor tools.
- Modify timing thresholds or window size in `rtl/config.v`.
- Integrate ETS logger around crypto cores or sensitive IP blocks.

### 🧠 Simulation & Verification
- Run testbenches in `/sim` for both baseline and attack scenarios.
- Analyze the waveform to visualize timing deviation patterns.
- Compare with baseline stored in `/tools/profiles/`.

### 💻 Software Integration
- `/software/firmware` includes C drivers for reading ETS registers.
- `/software/python` offers live monitoring and anomaly plotting utilities.

---

## 📈 Experiments & Results
- **Baseline Runs:** Stable execution time distribution under normal load.
- **Attack Runs:** Clear deviations detected by ETS anomaly thresholds.
- **FPGA Resource Usage:** ~3% LUT, ~2% FF, negligible BRAM utilization.
- **Latency Overhead:** < 2% compared to unmonitored baseline.

Refer to `/paper/results.pdf` for detailed tables and graphs.

---

## 🤝 Contributing
Contributions are welcome!  
If you'd like to improve the design or extend functionality, please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit and push changes
4. Submit a Pull Request

Ensure proper documentation for any new module.

---

## 📜 License
This project is licensed under the [MIT License](./LICENSE).  
You’re free to use, modify, and distribute this work with attribution.

---

## 🙏 Acknowledgements
Developed at **Indian Institute of Technology Mandi (IIT Mandi)**.  
Special thanks to **Dr. Bikram Paul** and the **Embedded Systems & VLSI Research Group** for their invaluable guidance and insights.

---

## 📬 Contact
**Author:** Om Maheshwari  
**Institute:** School of Computing and Electrical Engineering, IIT Mandi  
**Email:** b23089@students.iitmandi.ac.in  
**GitHub:** [om-mahesh](https://github.com/om-mahesh)  

> “Timing attacks are whispers — ETS teaches hardware to listen.”

---


