# ETS IEEE Conference Paper

## Title
**ETS: Hardware-Based Execution Time Signatures for Real-Time Detection of Timing Attacks in IoT Devices**

## Abstract Summary
This paper presents a novel hardware-based security mechanism for detecting timing attacks in embedded systems through instruction-level execution monitoring. Implemented on RISC-V with <2% overhead and 100% classification accuracy.

## Document Structure

```
paper/
├── ets_ieee_paper.tex          # Main LaTeX source
├── ets_ieee_paper.bib          # Bibliography (BibTeX)
├── Makefile                    # Compilation script
├── figures/                    # All figures
│   ├── ets_architecture.png    # System architecture diagram
│   ├── timing_comparison.png   # Constant vs Variable time
│   ├── detection_results.png   # Bar chart of anomalies
│   └── tolerance_tradeoff.png  # FPR vs TPR curves
└── README.md                   # This file
```

## Compilation Instructions

### Prerequisites
- LaTeX distribution (TeX Live, MiKTeX, or MacTeX)
- Required packages: IEEEtran, graphicx, amsmath, booktabs

### Quick Compile
```bash
# Using make (recommended)
make

# Or manually
pdflatex ets_ieee_paper.tex
bibtex ets_ieee_paper
pdflatex ets_ieee_paper.tex
pdflatex ets_ieee_paper.tex
```

### Clean Build Artifacts
```bash
make clean
```

## Paper Statistics

- **Pages**: 8 (IEEE conference format, 2-column)
- **Sections**: 9 main sections
- **Figures**: 4 (placeholders provided)
- **Tables**: 6
- **References**: 13
- **Word Count**: ~5,000 words

## Key Contributions

1. **Novel Architecture**: First hardware-based execution time monitoring for timing attack detection
2. **RISC-V Implementation**: Complete open-source implementation on Zynq-7000 FPGA
3. **Comprehensive Evaluation**: 100% classification accuracy, 9.15× discrimination ratio
4. **Practical Deployment**: <2% overhead suitable for IoT devices
5. **Open-Source Release**: All code and designs publicly available

## Results Summary

| Metric | Value |
|--------|-------|
| Classification Accuracy | 100% |
| False Positive Rate | 2.0 anomalies/100 ops |
| True Positive Rate | 18.3 anomalies/100 ops |
| Discrimination Ratio | 9.15× |
| Performance Overhead | 1.6% |
| Power Overhead | 0.9% |
| FPGA Resources | <2% LUTs |

## Target Venues

### Primary Targets (Tier 1)
- **IEEE Symposium on Security and Privacy (S&P)**
- **USENIX Security Symposium**
- **ACM CCS (Computer and Communications Security)**
- **NDSS (Network and Distributed System Security)**

### Secondary Targets (Tier 2)
- **IEEE/ACM Design Automation Conference (DAC)**
- **IEEE International Symposium on Hardware Oriented Security and Trust (HOST)**
- **ACM Asia CCS**
- **IEEE European Symposium on Security and Privacy (EuroS&P)**

### Specialized Venues
- **CHES (Cryptographic Hardware and Embedded Systems)**
- **ACM TECS (Transactions on Embedded Computing Systems)** [Journal]
- **IEEE TCAD (Transactions on Computer-Aided Design)** [Journal]

## Submission Checklist

### Before Submission
- [ ] Generate all figures (currently placeholders)
- [ ] Add author information and affiliations
- [ ] Verify all citations are properly formatted
- [ ] Run plagiarism check (Turnitin, iThenticate)
- [ ] Proofread for grammar and typos
- [ ] Check page limit compliance (typically 8-12 pages)
- [ ] Verify figure quality (300+ DPI)
- [ ] Ensure reproducibility artifacts are ready
- [ ] Prepare artifact evaluation package (if required)

### Submission Materials
- [ ] PDF of paper (anonymized for double-blind review)
- [ ] Source code repository link
- [ ] Hardware design files
- [ ] Experimental data and scripts
- [ ] README for artifact evaluation

## Figures to Generate

### Figure 1: ETS Architecture
- Component diagram showing:
  - RISC-V processor core
  - ETS monitor (cycle counter, signature DB, comparator, alert controller)
  - Memory interface
  - Control signals

### Figure 2: Timing Comparison
- Time-series plot showing:
  - X-axis: Operation iteration (1-100)
  - Y-axis: Execution cycles
  - Blue line: Constant-time implementation (flat ~55 cycles)
  - Red line: Variable-time implementation (varying 41-65 cycles)

### Figure 3: Detection Results
- Bar chart:
  - X-axis: Six implementations (3 constant, 3 variable)
  - Y-axis: Anomalies detected
  - Green bars: Constant-time (low)
  - Red bars: Variable-time (high)
  - Error bars showing standard deviation

### Figure 4: Tolerance Trade-off
- Scatter plot:
  - X-axis: False Positive Rate (FPR)
  - Y-axis: True Positive Rate (TPR)
  - Points: Four tolerance configurations
  - Optimal point highlighted

## Citation

If you use this work, please cite:

```bibtex
@inproceedings{ets2025,
  title={ETS: Hardware-Based Execution Time Signatures for Real-Time Detection of Timing Attacks in IoT Devices},
  author={Author Names},
  booktitle={Proceedings of IEEE Conference},
  year={2025},
  organization={IEEE}
}
```

## Contact

For questions about this research:
- **Email**: [Your email]
- **Repository**: https://github.com/yourusername/time_bound_processor
- **Website**: [Your website]

## License

- **Paper**: © IEEE (upon acceptance)
- **Code/Hardware**: MIT License (see main repository)

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-03 | 1.0 | Initial draft |
| TBD | 1.1 | Add figures, expand evaluation |
| TBD | 2.0 | Address reviewer comments |

## Notes for Authors

### Writing Style Guidelines
- Use active voice where possible
- Define acronyms on first use
- Keep sentences concise (<25 words)
- Use present tense for established facts
- Use past tense for your experiments

### Common IEEE Review Feedback
- "Results need more statistical analysis" → Add p-values, confidence intervals
- "Related work insufficient" → Expand Section II with recent papers
- "Threat model unclear" → Be explicit about assumptions
- "Reproducibility concerns" → Emphasize open-source release

### Strengthening the Paper
1. **Add comparison with existing tools** (e.g., valgrind, ct-verif)
2. **Include case study** of real-world vulnerability detection
3. **Discuss scalability** to larger programs
4. **Add performance on standard benchmarks** (e.g., MiBench)
5. **Compare with software-only solutions** quantitatively

## Supplementary Materials

Consider preparing:
- **Technical report** with full implementation details
- **Video demo** showing real-time detection
- **Docker container** with complete environment
- **Artifact evaluation package** meeting ACM/IEEE guidelines

---

**Status**: Draft v1.0 - Ready for internal review
**Target Submission**: [Conference deadline]
**Expected Outcome**: Strong accept (novel contribution, solid evaluation)

