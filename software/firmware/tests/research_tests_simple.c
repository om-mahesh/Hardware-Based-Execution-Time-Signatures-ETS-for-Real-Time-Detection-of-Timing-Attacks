/**
 * research_tests_simple.c
 * 
 * Simplified research tests that work on bare-metal RISC-V without floats.
 * Uses only integer arithmetic and basic operations.
 */

#include "../common/ets_lib.h"

#define LED_REG (*(volatile uint32_t*)0x90000000)

// Test result storage (simpler version)
typedef struct {
    uint32_t test_id;
    uint32_t anomalies_detected;
    uint32_t execution_time;
    uint32_t passed;  // 1 = pass, 0 = fail
} test_result_t;

test_result_t test_results[7];
int test_count = 0;

// Simple delay
void delay_cycles(uint32_t cycles) {
    for (volatile uint32_t i = 0; i < cycles; i++) {
        asm volatile ("nop");
    }
}

// ========== Configuration Functions ==========

void ets_config_permissive() {
    ets_set_signature(0x13, 10, 10);  // ADDI
    ets_set_signature(0x33, 15, 10);  // ADD
    ets_set_signature(0x03, 20, 15);  // LOAD
    ets_set_signature(0x23, 20, 15);  // STORE
    ets_set_signature(0x63, 15, 10);  // BRANCH
}

void ets_config_strict() {
    ets_set_signature(0x13, 5, 1);    // ADDI
    ets_set_signature(0x33, 6, 1);    // ADD
    ets_set_signature(0x03, 10, 2);   // LOAD
    ets_set_signature(0x23, 10, 2);   // STORE
    ets_set_signature(0x63, 8, 2);    // BRANCH
}

void ets_config_research() {
    ets_set_signature(0x13, 5, 0);    // ADDI - NO tolerance
    ets_set_signature(0x33, 6, 0);    // ADD - NO tolerance
    ets_set_signature(0x03, 10, 1);   // LOAD
    ets_set_signature(0x23, 10, 1);   // STORE
    ets_set_signature(0x63, 8, 1);    // BRANCH
}

// ========== Test 1: Timing Accuracy ==========

void test1_timing_accuracy() {
    LED_REG = 0x1;
    
    ets_clear_anomaly_count();
    ets_config_permissive();
    ets_enable(true);
    
    // Execute known sequence
    volatile uint32_t a = 0;
    for (int i = 0; i < 100; i++) {
        a = a + 1;
    }
    
    uint32_t anomalies = ets_get_anomaly_count();
    
    test_results[test_count].test_id = 1;
    test_results[test_count].anomalies_detected = anomalies;
    test_results[test_count].passed = (anomalies < 10);  // < 10% false positives
    test_count++;
    
    delay_cycles(10000);
}

// ========== Test 2: False Positive Rate ==========

void test2_false_positives() {
    LED_REG = 0x2;
    
    ets_clear_anomaly_count();
    ets_config_strict();
    ets_enable(true);
    
    // Run predictable code many times
    for (int iteration = 0; iteration < 100; iteration++) {
        volatile uint32_t sum = 0;
        for (int i = 0; i < 10; i++) {
            sum += i;
        }
    }
    
    uint32_t anomalies = ets_get_anomaly_count();
    
    test_results[test_count].test_id = 2;
    test_results[test_count].anomalies_detected = anomalies;
    test_results[test_count].passed = (anomalies < 50);  // < 50% FP rate acceptable
    test_count++;
    
    delay_cycles(10000);
}

// ========== Test 3: Attack Detection ==========

void test3_attack_detection() {
    LED_REG = 0x4;
    
    ets_clear_anomaly_count();
    ets_config_strict();
    ets_enable(true);
    
    // Normal execution
    for (int i = 0; i < 10; i++) {
        volatile uint32_t x = i;
    }
    
    uint32_t baseline = ets_get_anomaly_count();
    
    // Inject timing anomalies (simulated attack)
    for (int i = 0; i < 10; i++) {
        volatile uint32_t x = i;
        // Variable delay
        for (volatile int j = 0; j < (i * 10); j++) {
            asm volatile ("nop");
        }
    }
    
    uint32_t total = ets_get_anomaly_count();
    uint32_t detected = total - baseline;
    
    test_results[test_count].test_id = 3;
    test_results[test_count].anomalies_detected = detected;
    test_results[test_count].passed = (detected > 3);  // Detected > 30%
    test_count++;
    
    delay_cycles(10000);
}

// ========== Test 4: Performance Overhead ==========

void test4_performance() {
    LED_REG = 0x5;
    
    // Simple test - just ensure ETS doesn't crash
    ets_enable(false);
    delay_cycles(1000);
    
    ets_enable(true);
    delay_cycles(1000);
    
    test_results[test_count].test_id = 4;
    test_results[test_count].anomalies_detected = 0;
    test_results[test_count].passed = 1;  // Pass if we get here
    test_count++;
    
    delay_cycles(10000);
}

// ========== Test 5: Crypto Validation ==========

void test5_crypto() {
    LED_REG = 0x6;
    
    ets_clear_anomaly_count();
    ets_config_research();
    ets_enable(true);
    
    volatile uint32_t key = 0x12345678;
    volatile uint32_t data[16];
    
    // Constant-time XOR
    for (int i = 0; i < 16; i++) {
        data[i] = i ^ key;
    }
    
    uint32_t const_time_anomalies = ets_get_anomaly_count();
    ets_clear_anomaly_count();
    
    // Variable-time (data-dependent)
    for (int i = 0; i < 16; i++) {
        if (data[i] & 0x1) {
            data[i] = data[i] * 2;
        } else {
            data[i] = data[i] + 1;
        }
    }
    
    uint32_t var_time_anomalies = ets_get_anomaly_count();
    
    test_results[test_count].test_id = 5;
    test_results[test_count].anomalies_detected = var_time_anomalies;
    test_results[test_count].passed = (var_time_anomalies > const_time_anomalies);
    test_count++;
    
    delay_cycles(10000);
}

// ========== Test 6: Learning Mode ==========

void test6_learning() {
    LED_REG = 0x7;
    
    // Simple learning test - just run same code multiple times
    ets_config_permissive();
    ets_enable(true);
    
    // "Learn" by running code
    for (int learn_iter = 0; learn_iter < 20; learn_iter++) {
        volatile uint32_t sum = 0;
        for (int i = 0; i < 10; i++) {
            sum += i;
        }
    }
    
    // Now test - should have stable timing
    ets_clear_anomaly_count();
    for (int test_iter = 0; test_iter < 20; test_iter++) {
        volatile uint32_t sum = 0;
        for (int i = 0; i < 10; i++) {
            sum += i;
        }
    }
    
    uint32_t anomalies = ets_get_anomaly_count();
    
    test_results[test_count].test_id = 6;
    test_results[test_count].anomalies_detected = anomalies;
    test_results[test_count].passed = (anomalies < 10);
    test_count++;
    
    delay_cycles(10000);
}

// ========== Test 7: Stress Test ==========

void test7_stress() {
    LED_REG = 0x8;
    
    ets_config_permissive();
    ets_enable(true);
    
    // Large computation
    volatile uint32_t matrix[10][10];
    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
            matrix[i][j] = i * j;
        }
    }
    
    volatile uint32_t sum = 0;
    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
            sum += matrix[i][j];
        }
    }
    
    test_results[test_count].test_id = 7;
    test_results[test_count].anomalies_detected = ets_get_anomaly_count();
    test_results[test_count].passed = 1;  // Pass if completes
    test_count++;
    
    delay_cycles(10000);
}

// ========== Display Results ==========

void display_results() {
    // Count passed tests
    int passed = 0;
    for (int i = 0; i < test_count; i++) {
        if (test_results[i].passed) {
            passed++;
        }
    }
    
    // Blink N times for N passed tests
    for (int i = 0; i < passed; i++) {
        LED_REG = 0xF;
        delay_cycles(10000);
        LED_REG = 0x0;
        delay_cycles(10000);
    }
    
    delay_cycles(50000);
    
    // Final pattern based on success
    if (passed >= 6) {
        LED_REG = 0x1;  // Excellent
    } else if (passed >= 5) {
        LED_REG = 0x3;  // Good
    } else if (passed >= 3) {
        LED_REG = 0x7;  // Fair
    } else {
        LED_REG = 0xF;  // Poor
    }
}

// ========== Main ==========

int main(void) {
    // Startup
    LED_REG = 0x0;
    delay_cycles(50000);
    
    // Initialize ETS
    ets_init(ETS_MODE_FINE_GRAINED);
    ets_configure_alerts(true, true);
    
    // Startup blinks
    for (int i = 0; i < 3; i++) {
        LED_REG = 0xF;
        delay_cycles(20000);
        LED_REG = 0x0;
        delay_cycles(20000);
    }
    
    // Run all tests
    test1_timing_accuracy();
    test2_false_positives();
    test3_attack_detection();
    test4_performance();
    test5_crypto();
    test6_learning();
    test7_stress();
    
    // Display results
    display_results();
    
    // Loop with heartbeat
    while (1) {
        delay_cycles(500000);
        LED_REG ^= 0x1;  // Toggle LED0
    }
    
    return 0;
}

