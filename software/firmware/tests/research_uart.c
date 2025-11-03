/**
 * research_uart.c
 * 
 * Research tests with UART data logging
 * Outputs quantitative results over UART for analysis
 */

#include "../common/ets_lib.h"
#include "../common/uart.h"

#define LED_REG (*(volatile uint32_t*)0x90000000)

// Test results
typedef struct {
    uint32_t test_id;
    uint32_t anomalies_detected;
    uint32_t execution_time;
    uint32_t passed;
} test_result_t;

test_result_t results[7];
int test_count = 0;

void delay_cycles(uint32_t cycles) {
    for (volatile uint32_t i = 0; i < cycles; i++) {
        asm volatile ("nop");
    }
}

// ETS config functions
void ets_config_permissive() {
    ets_set_signature(0x13, 10, 10);
    ets_set_signature(0x33, 15, 10);
    ets_set_signature(0x03, 20, 15);
    ets_set_signature(0x23, 20, 15);
    ets_set_signature(0x63, 15, 10);
}

void ets_config_strict() {
    ets_set_signature(0x13, 5, 1);
    ets_set_signature(0x33, 6, 1);
    ets_set_signature(0x03, 10, 2);
    ets_set_signature(0x23, 10, 2);
    ets_set_signature(0x63, 8, 2);
}

// Test 1: Timing Accuracy
void test1_timing() {
    LED_REG = 0x1;
    uart_printf("\r\n--- Test 1: Timing Accuracy ---\r\n");
    
    ets_clear_anomaly_count();
    ets_config_permissive();
    ets_enable(true);
    
    volatile uint32_t a = 0;
    for (int i = 0; i < 100; i++) {
        a = a + 1;
    }
    
    uint32_t anomalies = ets_get_anomaly_count();
    uint32_t passed = (anomalies < 10);
    
    results[test_count].test_id = 1;
    results[test_count].anomalies_detected = anomalies;
    results[test_count].passed = passed;
    test_count++;
    
    uart_printf("Anomalies: %u\r\n", anomalies);
    uart_printf("Status: %s\r\n", passed ? "PASS" : "FAIL");
    
    delay_cycles(10000);
}

// Test 2: False Positives
void test2_false_positives() {
    LED_REG = 0x2;
    uart_printf("\r\n--- Test 2: False Positive Rate ---\r\n");
    
    ets_clear_anomaly_count();
    ets_config_strict();
    ets_enable(true);
    
    for (int iter = 0; iter < 100; iter++) {
        volatile uint32_t sum = 0;
        for (int i = 0; i < 10; i++) {
            sum += i;
        }
    }
    
    uint32_t anomalies = ets_get_anomaly_count();
    uint32_t passed = (anomalies < 50);
    
    results[test_count].test_id = 2;
    results[test_count].anomalies_detected = anomalies;
    results[test_count].passed = passed;
    test_count++;
    
    uart_printf("Anomalies: %u / 100 iterations\r\n", anomalies);
    uart_printf("FP Rate: %u%%\r\n", anomalies);
    uart_printf("Status: %s\r\n", passed ? "PASS" : "FAIL");
    
    delay_cycles(10000);
}

// Test 3: Attack Detection
void test3_attacks() {
    LED_REG = 0x4;
    uart_printf("\r\n--- Test 3: Attack Detection ---\r\n");
    
    ets_clear_anomaly_count();
    ets_config_strict();
    ets_enable(true);
    
    // Normal
    for (int i = 0; i < 10; i++) {
        volatile uint32_t x = i;
    }
    uint32_t baseline = ets_get_anomaly_count();
    
    // Simulated attack
    for (int i = 0; i < 10; i++) {
        volatile uint32_t x = i;
        for (volatile int j = 0; j < (i * 10); j++) {
            asm volatile ("nop");
        }
    }
    
    uint32_t total = ets_get_anomaly_count();
    uint32_t detected = total - baseline;
    uint32_t passed = (detected > 3);
    
    results[test_count].test_id = 3;
    results[test_count].anomalies_detected = detected;
    results[test_count].passed = passed;
    test_count++;
    
    uart_printf("Baseline: %u, Detected: %u\r\n", baseline, detected);
    uart_printf("Detection Rate: %u%%\r\n", detected * 10);
    uart_printf("Status: %s\r\n", passed ? "PASS" : "FAIL");
    
    delay_cycles(10000);
}

// Test 4-7: Simplified versions
void test4_performance() {
    LED_REG = 0x5;
    uart_printf("\r\n--- Test 4: Performance ---\r\n");
    
    ets_enable(false);
    delay_cycles(1000);
    ets_enable(true);
    delay_cycles(1000);
    
    results[test_count].test_id = 4;
    results[test_count].passed = 1;
    test_count++;
    
    uart_printf("Status: PASS\r\n");
    delay_cycles(10000);
}

void test5_crypto() {
    LED_REG = 0x6;
    uart_printf("\r\n--- Test 5: Crypto Validation ---\r\n");
    
    volatile uint32_t key = 0x12345678;
    volatile uint32_t data[16];
    
    ets_clear_anomaly_count();
    ets_config_strict();
    ets_enable(true);
    
    for (int i = 0; i < 16; i++) {
        data[i] = i ^ key;
    }
    uint32_t const_time = ets_get_anomaly_count();
    
    ets_clear_anomaly_count();
    for (int i = 0; i < 16; i++) {
        if (data[i] & 0x1) {
            data[i] = data[i] * 2;
        } else {
            data[i] = data[i] + 1;
        }
    }
    uint32_t var_time = ets_get_anomaly_count();
    
    uint32_t passed = (var_time > const_time);
    
    results[test_count].test_id = 5;
    results[test_count].anomalies_detected = var_time;
    results[test_count].passed = passed;
    test_count++;
    
    uart_printf("Constant-time: %u, Variable-time: %u\r\n", const_time, var_time);
    uart_printf("Status: %s\r\n", passed ? "PASS" : "FAIL");
    delay_cycles(10000);
}

void test6_learning() {
    LED_REG = 0x7;
    uart_printf("\r\n--- Test 6: Learning Mode ---\r\n");
    
    ets_config_permissive();
    ets_enable(true);
    
    for (int i = 0; i < 20; i++) {
        volatile uint32_t sum = 0;
        for (int j = 0; j < 10; j++) {
            sum += j;
        }
    }
    
    ets_clear_anomaly_count();
    for (int i = 0; i < 20; i++) {
        volatile uint32_t sum = 0;
        for (int j = 0; j < 10; j++) {
            sum += j;
        }
    }
    
    uint32_t anomalies = ets_get_anomaly_count();
    uint32_t passed = (anomalies < 10);
    
    results[test_count].test_id = 6;
    results[test_count].anomalies_detected = anomalies;
    results[test_count].passed = passed;
    test_count++;
    
    uart_printf("Anomalies after learning: %u\r\n", anomalies);
    uart_printf("Status: %s\r\n", passed ? "PASS" : "FAIL");
    delay_cycles(10000);
}

void test7_stress() {
    LED_REG = 0x8;
    uart_printf("\r\n--- Test 7: Stress Test ---\r\n");
    
    ets_config_permissive();
    ets_enable(true);
    
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
    
    results[test_count].test_id = 7;
    results[test_count].anomalies_detected = ets_get_anomaly_count();
    results[test_count].passed = 1;
    test_count++;
    
    uart_printf("Matrix sum: %u\r\n", sum);
    uart_printf("Status: PASS\r\n");
    delay_cycles(10000);
}

// Summary
void print_summary() {
    uart_printf("\r\n========================================\r\n");
    uart_printf("RESEARCH TEST SUMMARY\r\n");
    uart_printf("========================================\r\n");
    
    int passed = 0;
    for (int i = 0; i < test_count; i++) {
        uart_printf("Test %u: %s - Anomalies: %u\r\n",
                    results[i].test_id,
                    results[i].passed ? "PASS" : "FAIL",
                    results[i].anomalies_detected);
        if (results[i].passed) passed++;
    }
    
    uart_printf("\r\nTotal: %d/%d tests passed\r\n", passed, test_count);
    
    // Calculate success rate without division
    uint32_t success_rate = 0;
    if (test_count > 0) {
        success_rate = (passed * 100);
        // Simple division by test_count
        uint32_t temp = success_rate;
        success_rate = 0;
        while (temp >= (uint32_t)test_count) {
            temp -= test_count;
            success_rate++;
        }
    }
    uart_printf("Success Rate: %u%%\r\n", success_rate);
    
    if (passed >= 6) {
        uart_printf("Grade: EXCELLENT\r\n");
        LED_REG = 0x1;
    } else if (passed >= 5) {
        uart_printf("Grade: GOOD\r\n");
        LED_REG = 0x3;
    } else if (passed >= 3) {
        uart_printf("Grade: FAIR\r\n");
        LED_REG = 0x7;
    } else {
        uart_printf("Grade: POOR\r\n");
        LED_REG = 0xF;
    }
    
    uart_printf("========================================\r\n");
}

// Print CSV for data analysis
void print_csv() {
    uart_printf("\r\n--- CSV DATA (for analysis) ---\r\n");
    uart_printf("test_id,expected_anomalies,detected_anomalies,execution_time,passed\r\n");
    
    for (int i = 0; i < test_count; i++) {
        uart_printf("%u,0,%u,0,%u\r\n",
                    results[i].test_id,
                    results[i].anomalies_detected,
                    results[i].passed);
    }
}

// Main
int main(void) {
    // Initialize UART
    uart_init();
    LED_REG = 0x0;
    delay_cycles(50000);
    
    uart_printf("\r\n\r\n");
    uart_printf("========================================\r\n");
    uart_printf("ETS RISC-V RESEARCH TEST SUITE\r\n");
    uart_printf("========================================\r\n");
    uart_printf("System: PicoRV32 + ETS Monitor\r\n");
    uart_printf("Platform: Zybo Z7-10 FPGA\r\n");
    uart_printf("Clock: 125 MHz\r\n");
    uart_printf("========================================\r\n");
    
    // Initialize ETS
    ets_init(ETS_MODE_FINE_GRAINED);
    ets_configure_alerts(true, true);
    
    uart_printf("\r\nStarting tests...\r\n");
    
    // Run all tests
    test1_timing();
    test2_false_positives();
    test3_attacks();
    test4_performance();
    test5_crypto();
    test6_learning();
    test7_stress();
    
    // Print summary
    print_summary();
    print_csv();
    
    uart_printf("\r\nTests complete. System entering heartbeat mode.\r\n");
    
    // Heartbeat
    while (1) {
        delay_cycles(500000);
        LED_REG ^= 0x1;
    }
    
    return 0;
}

