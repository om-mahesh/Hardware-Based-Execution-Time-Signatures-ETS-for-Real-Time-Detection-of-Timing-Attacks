#!/usr/bin/env python3
"""
analyze_results.py

Data analysis tool for ETS research results.
Processes test data, generates statistics, and creates visualizations.

Usage:
    python analyze_results.py [data_file.csv]
"""

import sys
import csv
from typing import List, Dict, Tuple
import statistics

# ========== Data Structures ==========

class TestResult:
    def __init__(self, test_id, expected, detected, exec_time, passed):
        self.test_id = int(test_id)
        self.expected_anomalies = int(expected)
        self.detected_anomalies = int(detected)
        self.execution_time = int(exec_time)
        self.passed = (passed.lower() == 'true')
    
    def __repr__(self):
        return f"Test{self.test_id}(detected={self.detected_anomalies}, time={self.execution_time}, pass={self.passed})"

# ========== Analysis Functions ==========

def calculate_detection_rates(results: List[TestResult]) -> Dict:
    """Calculate true positive, false positive rates"""
    
    # Filter attack detection tests (test_id == 3)
    attack_tests = [r for r in results if r.test_id == 3]
    
    if not attack_tests:
        return {"error": "No attack detection tests found"}
    
    total_expected = sum(r.expected_anomalies for r in attack_tests)
    total_detected = sum(r.detected_anomalies for r in attack_tests)
    
    tp_rate = (total_detected / total_expected * 100) if total_expected > 0 else 0
    
    # False positive tests (test_id == 2)
    fp_tests = [r for r in results if r.test_id == 2]
    total_fp = sum(r.detected_anomalies for r in fp_tests)
    fp_rate = (total_fp / len(fp_tests)) if fp_tests else 0
    
    return {
        "true_positive_rate": tp_rate,
        "false_positive_rate": fp_rate,
        "total_attacks_expected": total_expected,
        "total_attacks_detected": total_detected,
        "total_false_positives": total_fp
    }

def calculate_performance_metrics(results: List[TestResult]) -> Dict:
    """Calculate performance statistics"""
    
    # Performance test (test_id == 4)
    perf_tests = [r for r in results if r.test_id == 4]
    
    if not perf_tests:
        return {"error": "No performance tests found"}
    
    overhead_cycles = [r.execution_time for r in perf_tests]
    
    return {
        "avg_overhead_cycles": statistics.mean(overhead_cycles),
        "median_overhead": statistics.median(overhead_cycles),
        "std_dev": statistics.stdev(overhead_cycles) if len(overhead_cycles) > 1 else 0,
        "min_overhead": min(overhead_cycles),
        "max_overhead": max(overhead_cycles)
    }

def calculate_timing_accuracy(results: List[TestResult]) -> Dict:
    """Calculate timing measurement accuracy"""
    
    # Timing accuracy test (test_id == 1)
    timing_tests = [r for r in results if r.test_id == 1]
    
    if not timing_tests:
        return {"error": "No timing accuracy tests found"}
    
    exec_times = [r.execution_time for r in timing_tests]
    
    avg_time = statistics.mean(exec_times)
    std_dev = statistics.stdev(exec_times) if len(exec_times) > 1 else 0
    precision = (std_dev / avg_time * 100) if avg_time > 0 else 0
    
    return {
        "avg_execution_time": avg_time,
        "std_dev": std_dev,
        "precision_percent": precision,
        "min_time": min(exec_times),
        "max_time": max(exec_times)
    }

def calculate_overall_success(results: List[TestResult]) -> Dict:
    """Calculate overall test success rate"""
    
    total_tests = len(results)
    passed_tests = sum(1 for r in results if r.passed)
    
    success_rate = (passed_tests / total_tests * 100) if total_tests > 0 else 0
    
    # Grade based on success rate
    if success_rate >= 90:
        grade = 'A (Excellent)'
    elif success_rate >= 70:
        grade = 'B (Good)'
    elif success_rate >= 50:
        grade = 'C (Fair)'
    else:
        grade = 'F (Fail)'
    
    return {
        "total_tests": total_tests,
        "passed_tests": passed_tests,
        "failed_tests": total_tests - passed_tests,
        "success_rate": success_rate,
        "grade": grade
    }

# ========== Report Generation ==========

def generate_text_report(results: List[TestResult]) -> str:
    """Generate comprehensive text report"""
    
    report = []
    report.append("=" * 70)
    report.append("ETS RESEARCH TEST RESULTS - ANALYSIS REPORT")
    report.append("=" * 70)
    report.append("")
    
    # Overall Success
    overall = calculate_overall_success(results)
    report.append("📊 OVERALL RESULTS")
    report.append("-" * 70)
    report.append(f"Total Tests:     {overall['total_tests']}")
    report.append(f"Tests Passed:    {overall['passed_tests']}")
    report.append(f"Tests Failed:    {overall['failed_tests']}")
    report.append(f"Success Rate:    {overall['success_rate']:.1f}%")
    report.append(f"Grade:           {overall['grade']}")
    report.append("")
    
    # Detection Rates
    detection = calculate_detection_rates(results)
    if "error" not in detection:
        report.append("🎯 DETECTION ANALYSIS")
        report.append("-" * 70)
        report.append(f"True Positive Rate:     {detection['true_positive_rate']:.1f}%")
        report.append(f"False Positive Rate:    {detection['false_positive_rate']:.2f}%")
        report.append(f"Attacks Expected:       {detection['total_attacks_expected']}")
        report.append(f"Attacks Detected:       {detection['total_attacks_detected']}")
        report.append(f"False Positives:        {detection['total_false_positives']}")
        report.append("")
    
    # Timing Accuracy
    timing = calculate_timing_accuracy(results)
    if "error" not in timing:
        report.append("⏱️  TIMING ACCURACY")
        report.append("-" * 70)
        report.append(f"Avg Execution Time:     {timing['avg_execution_time']:.0f} cycles")
        report.append(f"Standard Deviation:     {timing['std_dev']:.2f} cycles")
        report.append(f"Precision:              {timing['precision_percent']:.2f}%")
        report.append(f"Min Time:               {timing['min_time']} cycles")
        report.append(f"Max Time:               {timing['max_time']} cycles")
        report.append("")
    
    # Performance Impact
    performance = calculate_performance_metrics(results)
    if "error" not in performance:
        report.append("⚡ PERFORMANCE IMPACT")
        report.append("-" * 70)
        report.append(f"Avg Overhead:           {performance['avg_overhead_cycles']:.0f} cycles")
        report.append(f"Median Overhead:        {performance['median_overhead']:.0f} cycles")
        report.append(f"Std Deviation:          {performance['std_dev']:.2f} cycles")
        report.append(f"Min Overhead:           {performance['min_overhead']} cycles")
        report.append(f"Max Overhead:           {performance['max_overhead']} cycles")
        report.append("")
    
    # Individual Test Results
    report.append("📋 INDIVIDUAL TEST RESULTS")
    report.append("-" * 70)
    
    test_names = {
        1: "Timing Accuracy",
        2: "False Positive Rate",
        3: "Attack Detection",
        4: "Performance Overhead",
        5: "Constant-Time Crypto",
        6: "Learning Mode",
        7: "Stress Test"
    }
    
    for test_id in sorted(set(r.test_id for r in results)):
        test_results = [r for r in results if r.test_id == test_id]
        passed = sum(1 for r in test_results if r.passed)
        total = len(test_results)
        
        status = "✅ PASS" if passed == total else f"⚠️  PARTIAL ({passed}/{total})"
        test_name = test_names.get(test_id, f"Test {test_id}")
        
        report.append(f"Test {test_id} - {test_name}: {status}")
    
    report.append("")
    report.append("=" * 70)
    
    return "\n".join(report)

def generate_csv_summary(results: List[TestResult], output_file: str):
    """Generate CSV summary"""
    
    with open(output_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["Metric", "Value"])
        
        # Overall
        overall = calculate_overall_success(results)
        writer.writerow(["Total Tests", overall['total_tests']])
        writer.writerow(["Passed Tests", overall['passed_tests']])
        writer.writerow(["Success Rate (%)", f"{overall['success_rate']:.1f}"])
        writer.writerow(["Grade", overall['grade']])
        writer.writerow([])
        
        # Detection
        detection = calculate_detection_rates(results)
        if "error" not in detection:
            writer.writerow(["True Positive Rate (%)", f"{detection['true_positive_rate']:.1f}"])
            writer.writerow(["False Positive Rate (%)", f"{detection['false_positive_rate']:.2f}"])
            writer.writerow([])
        
        # Timing
        timing = calculate_timing_accuracy(results)
        if "error" not in timing:
            writer.writerow(["Avg Execution Time (cycles)", f"{timing['avg_execution_time']:.0f}"])
            writer.writerow(["Timing Precision (%)", f"{timing['precision_percent']:.2f}"])
            writer.writerow([])
        
        # Performance
        performance = calculate_performance_metrics(results)
        if "error" not in performance:
            writer.writerow(["Avg Overhead (cycles)", f"{performance['avg_overhead_cycles']:.0f}"])
    
    print(f"✅ Summary saved to {output_file}")

# ========== Data Loading ==========

def load_results_from_csv(filename: str) -> List[TestResult]:
    """Load test results from CSV file"""
    
    results = []
    
    try:
        with open(filename, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                result = TestResult(
                    test_id=row['test_id'],
                    expected=row['expected_anomalies'],
                    detected=row['detected_anomalies'],
                    exec_time=row['execution_time'],
                    passed=row['passed']
                )
                results.append(result)
        
        print(f"✅ Loaded {len(results)} test results from {filename}")
    except FileNotFoundError:
        print(f"❌ Error: File '{filename}' not found")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error loading file: {e}")
        sys.exit(1)
    
    return results

def create_sample_data() -> List[TestResult]:
    """Create sample data for demonstration"""
    
    print("ℹ️  No input file provided. Using sample data.")
    
    return [
        # Timing accuracy tests
        TestResult(1, 0, 0, 250, True),
        TestResult(1, 0, 1, 248, True),
        TestResult(1, 0, 0, 252, True),
        
        # False positive tests
        TestResult(2, 0, 15, 5000, True),
        TestResult(2, 0, 12, 5020, True),
        
        # Attack detection tests
        TestResult(3, 10, 8, 3000, True),
        TestResult(3, 10, 9, 3100, True),
        
        # Performance tests
        TestResult(4, 0, 0, 120, True),
        TestResult(4, 0, 0, 118, True),
        
        # Crypto tests
        TestResult(5, 0, 25, 4000, True),
        
        # Learning tests
        TestResult(6, 0, 3, 8000, True),
        
        # Stress tests
        TestResult(7, 0, 45, 50000, True),
    ]

# ========== Main ==========

def main():
    print("\n" + "=" * 70)
    print("ETS Research Results Analyzer")
    print("=" * 70 + "\n")
    
    # Load data
    if len(sys.argv) > 1:
        results = load_results_from_csv(sys.argv[1])
    else:
        results = create_sample_data()
    
    # Generate report
    report = generate_text_report(results)
    print(report)
    
    # Save to file
    with open("analysis_report.txt", "w") as f:
        f.write(report)
    print("📄 Full report saved to: analysis_report.txt")
    
    # Generate CSV summary
    generate_csv_summary(results, "analysis_summary.csv")
    
    print("\n✅ Analysis complete!\n")

if __name__ == "__main__":
    main()

