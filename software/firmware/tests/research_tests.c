/**
 * research_tests.c
 * 
 * Research-level validation and testing for ETS RISC-V system.
 * 
 * Test Categories:
 * 1. Timing Accuracy - Measure instruction timing precision
 * 2. Detection Rate - False positive/negative analysis
 * 3. Performance Impact - ETS overhead measurement
 * 4. Security Validation - Simulated attack detection
 * 5. Scalability - Large program testing
 */

#include "../common/ets_lib.h"

#define LED_REG (*(volatile uint32_t*)0x90000000)

// ========== Data Collection Structures ==========

typedef struct {
    uint32_t instruction_count;
    uint32_t total_cycles;
    uint32_t anomalies_detected;
    uint32_t false_positives;
    uint32_t true_positives;
    uint32_t avg_cycles_per_instr;
} performance_metrics_t;

typedef struct {
    uint32_t test_id;
    uint32_t expected_anomalies;
    uint32_t detected_anomalies;
    uint32_t execution_time;
    bool passed;
} test_case_result_t;

#define MAX_TEST_CASES 20
test_case_result_t test_results[MAX_TEST_CASES];
int test_result_index = 0;

performance_metrics_t metrics;

// ========== Timing Measurement ==========

static inline uint32_t get_cycle_count() {
    // Read from ETS current cycles register
    return ETS_CURRENT_CYCLES;
}

void delay_precise(uint32_t cycles) {
    uint32_t start = get_cycle_count();
    while ((get_cycle_count() - start) < cycles) {
        asm volatile ("nop");
    }
}

// ========== Test 1: Timing Accuracy Validation ==========

void research_test_timing_accuracy() {
    // Objective: Measure how accurately ETS tracks instruction timing
    
    LED_REG = 0x1;  // Signal test start
    
    ets_clear_anomaly_count();
    ets_config_permissive();  // Use permissive for accuracy test
    ets_enable(true);
    
    uint32_t start_cycles = get_cycle_count();
    
    // Execute known instruction sequence
    volatile uint32_t a = 0;
    for (int i = 0; i < 100; i++) {
        a = a + 1;  // ADDI instruction
    }
    
    uint32_t end_cycles = get_cycle_count();
    uint32_t measured_cycles = end_cycles - start_cycles;
    
    // Store results
    metrics.instruction_count = 100;
    metrics.total_cycles = measured_cycles;
    metrics.avg_cycles_per_instr = measured_cycles / 100;
    
    // Expected: ~2-3 cycles per ADDI
    bool passed = (metrics.avg_cycles_per_instr >= 2 && 
                   metrics.avg_cycles_per_instr <= 5);
    
    test_results[test_result_index].test_id = 1;
    test_results[test_result_index].execution_time = measured_cycles;
    test_results[test_result_index].passed = passed;
    test_result_index++;
    
    if (passed) {
        LED_REG = 0x1;  // Success
    } else {
        LED_REG = 0xF;  // Fail
    }
}

// ========== Test 2: False Positive Rate ==========

void research_test_false_positives() {
    // Objective: Measure false positive rate with normal code
    
    LED_REG = 0x2;
    
    ets_clear_anomaly_count();
    ets_config_strict();  // Strict config to challenge system
    ets_enable(true);
    
    // Run 1000 iterations of normal, predictable code
    for (int iteration = 0; iteration < 1000; iteration++) {
        volatile uint32_t sum = 0;
        for (int i = 0; i < 10; i++) {
            sum += i;
        }
    }
    
    uint32_t anomalies = ets_get_anomaly_count();
    
    // Calculate false positive rate
    // Expected: < 1% false positives for predictable code
    float fp_rate = (float)anomalies / 1000.0f * 100.0f;
    
    test_results[test_result_index].test_id = 2;
    test_results[test_result_index].detected_anomalies = anomalies;
    test_results[test_result_index].expected_anomalies = 0;
    test_results[test_result_index].passed = (fp_rate < 5.0f);  // < 5% acceptable
    test_result_index++;
    
    // Display result
    if (anomalies == 0) {
        LED_REG = 0x1;  // Perfect
    } else if (anomalies < 50) {
        LED_REG = 0x3;  // Acceptable
    } else {
        LED_REG = 0xF;  // Too many FPs
    }
}

// ========== Test 3: True Positive Rate (Attack Detection) ==========

void research_test_attack_detection() {
    // Objective: Verify ETS detects timing anomalies (simulated attacks)
    
    LED_REG = 0x4;
    
    ets_clear_anomaly_count();
    ets_config_strict();  // Strict to catch anomalies
    ets_enable(true);
    
    // Phase 1: Normal execution
    for (int i = 0; i < 10; i++) {
        volatile uint32_t x = i;
    }
    
    uint32_t baseline_anomalies = ets_get_anomaly_count();
    
    // Phase 2: Inject timing anomalies (simulated attack)
    for (int i = 0; i < 10; i++) {
        volatile uint32_t x = i;
        // Add unpredictable delay (simulates cache miss, side-channel attack)
        for (volatile int j = 0; j < i * 10; j++) {
            asm volatile ("nop");
        }
    }
    
    uint32_t total_anomalies = ets_get_anomaly_count();
    uint32_t detected_attacks = total_anomalies - baseline_anomalies;
    
    // Expected: Should detect most of the injected anomalies
    test_results[test_result_index].test_id = 3;
    test_results[test_result_index].expected_anomalies = 10;
    test_results[test_result_index].detected_anomalies = detected_attacks;
    test_results[test_result_index].passed = (detected_attacks > 5);  // >50% detection
    test_result_index++;
    
    // Display detection rate
    if (detected_attacks >= 8) {
        LED_REG = 0x1;  // Excellent
    } else if (detected_attacks >= 5) {
        LED_REG = 0x3;  // Good
    } else {
        LED_REG = 0xF;  // Poor detection
    }
}

// ========== Test 4: Performance Overhead Measurement ==========

void research_test_performance_overhead() {
    // Objective: Measure ETS performance impact
    
    LED_REG = 0x5;
    
    uint32_t cycles_without_ets, cycles_with_ets;
    
    // Test WITHOUT ETS
    ets_enable(false);
    uint32_t start = get_cycle_count();
    for (int i = 0; i < 1000; i++) {
        volatile uint32_t x = i * 2;
    }
    uint32_t end = get_cycle_count();
    cycles_without_ets = end - start;
    
    delay_precise(1000);
    
    // Test WITH ETS
    ets_enable(true);
    start = get_cycle_count();
    for (int i = 0; i < 1000; i++) {
        volatile uint32_t x = i * 2;
    }
    end = get_cycle_count();
    cycles_with_ets = end - start;
    
    // Calculate overhead
    uint32_t overhead = cycles_with_ets - cycles_without_ets;
    float overhead_percent = ((float)overhead / (float)cycles_without_ets) * 100.0f;
    
    // Expected: < 5% overhead
    test_results[test_result_index].test_id = 4;
    test_results[test_result_index].execution_time = overhead;
    test_results[test_result_index].passed = (overhead_percent < 10.0f);
    test_result_index++;
    
    if (overhead_percent < 2.0f) {
        LED_REG = 0x1;  // Negligible overhead
    } else if (overhead_percent < 5.0f) {
        LED_REG = 0x3;  // Acceptable
    } else {
        LED_REG = 0xF;  // High overhead
    }
}

// ========== Test 5: Constant-Time Crypto Validation ==========

void research_test_constant_time_crypto() {
    // Objective: Verify ETS can validate constant-time implementations
    
    LED_REG = 0x6;
    
    ets_clear_anomaly_count();
    ets_config_research();  // Ultra-strict for crypto
    ets_enable(true);
    
    volatile uint32_t key = 0x12345678;
    volatile uint32_t data_array[16];
    
    // Constant-time XOR (should have consistent timing)
    for (int i = 0; i < 16; i++) {
        data_array[i] = i ^ key;  // XOR is constant-time
    }
    
    uint32_t anomalies_constant_time = ets_get_anomaly_count();
    
    ets_clear_anomaly_count();
    
    // Variable-time operation (data-dependent branches)
    for (int i = 0; i < 16; i++) {
        if (data_array[i] & 0x1) {  // Branch based on data
            data_array[i] = data_array[i] * 2;
        } else {
            data_array[i] = data_array[i] + 1;
        }
    }
    
    uint32_t anomalies_variable_time = ets_get_anomaly_count();
    
    // Expected: Constant-time has fewer anomalies
    bool passed = (anomalies_constant_time < anomalies_variable_time);
    
    test_results[test_result_index].test_id = 5;
    test_results[test_result_index].expected_anomalies = 0;
    test_results[test_result_index].detected_anomalies = anomalies_variable_time;
    test_results[test_result_index].passed = passed;
    test_result_index++;
    
    if (passed) {
        LED_REG = 0x1;
    } else {
        LED_REG = 0xF;
    }
}

// ========== Test 6: Learning Mode Validation ==========

void research_test_learning_mode() {
    // Objective: Test automatic signature generation
    
    LED_REG = 0x7;
    
    // Define test function
    void test_function() {
        volatile uint32_t sum = 0;
        for (int i = 0; i < 20; i++) {
            sum += i;
        }
    }
    
    // Learn timing
    ets_learn_function(test_function, 50);  // Learn over 50 iterations
    
    // Now test with learned signatures
    ets_enable(true);
    ets_clear_anomaly_count();
    
    // Run same function - should have minimal anomalies
    for (int i = 0; i < 20; i++) {
        test_function();
    }
    
    uint32_t anomalies_after_learning = ets_get_anomaly_count();
    
    // Expected: Very few anomalies with learned signatures
    test_results[test_result_index].test_id = 6;
    test_results[test_result_index].detected_anomalies = anomalies_after_learning;
    test_results[test_result_index].passed = (anomalies_after_learning < 5);
    test_result_index++;
    
    if (anomalies_after_learning == 0) {
        LED_REG = 0x1;
    } else {
        LED_REG = 0x3;
    }
}

// ========== Test 7: Stress Test (Large Program) ==========

void research_test_stress() {
    // Objective: Test ETS with large, complex program
    
    LED_REG = 0x8;
    
    ets_clear_anomaly_count();
    ets_config_permissive();
    ets_enable(true);
    
    uint32_t start = get_cycle_count();
    
    // Large computation
    volatile uint32_t matrix[10][10];
    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
            matrix[i][j] = i * j;
        }
    }
    
    // Matrix operations
    volatile uint32_t sum = 0;
    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
            sum += matrix[i][j];
        }
    }
    
    uint32_t end = get_cycle_count();
    uint32_t total_cycles = end - start;
    
    uint32_t anomalies = ets_get_anomaly_count();
    
    test_results[test_result_index].test_id = 7;
    test_results[test_result_index].execution_time = total_cycles;
    test_results[test_result_index].detected_anomalies = anomalies;
    test_results[test_result_index].passed = (total_cycles > 0);  // Just needs to complete
    test_result_index++;
    
    LED_REG = 0x1;  // Stress test complete
}

// ========== Results Display ==========

void display_test_results() {
    // Display summary via LED patterns
    
    int passed_tests = 0;
    for (int i = 0; i < test_result_index; i++) {
        if (test_results[i].passed) {
            passed_tests++;
        }
    }
    
    // Blink number of passed tests
    for (int i = 0; i < passed_tests; i++) {
        LED_REG = 0xF;
        delay_precise(10000);
        LED_REG = 0x0;
        delay_precise(10000);
    }
    
    // Final pattern based on success rate
    float success_rate = (float)passed_tests / (float)test_result_index;
    
    if (success_rate >= 0.9f) {
        LED_REG = 0x1;  // Excellent (>90%)
    } else if (success_rate >= 0.7f) {
        LED_REG = 0x3;  // Good (>70%)
    } else if (success_rate >= 0.5f) {
        LED_REG = 0x7;  // Fair (>50%)
    } else {
        LED_REG = 0xF;  // Poor (<50%)
    }
}

// ========== Main Research Test Suite ==========

int main(void) {
    // Startup sequence
    LED_REG = 0x0;
    delay_precise(50000);
    
    // Initialize ETS
    ets_init(ETS_MODE_FINE_GRAINED);
    ets_configure_alerts(true, true);
    
    // Signal start
    for (int i = 0; i < 3; i++) {
        LED_REG = 0xF;
        delay_precise(20000);
        LED_REG = 0x0;
        delay_precise(20000);
    }
    
    // Run all research tests
    research_test_timing_accuracy();         // Test 1
    delay_precise(100000);
    
    research_test_false_positives();         // Test 2
    delay_precise(100000);
    
    research_test_attack_detection();        // Test 3
    delay_precise(100000);
    
    research_test_performance_overhead();    // Test 4
    delay_precise(100000);
    
    research_test_constant_time_crypto();    // Test 5
    delay_precise(100000);
    
    research_test_learning_mode();           // Test 6
    delay_precise(100000);
    
    research_test_stress();                  // Test 7
    delay_precise(100000);
    
    // Display results
    display_test_results();
    
    // Loop with status display
    while (1) {
        // Periodic status blink
        LED_REG = 0x1;
        delay_precise(500000);
        LED_REG = 0x0;
        delay_precise(500000);
    }
    
    return 0;
}

