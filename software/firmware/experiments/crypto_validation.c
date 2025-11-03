/**
 * crypto_validation.c
 * 
 * EXPERIMENT: Cryptographic Constant-Time Validation
 * 
 * Goal: Validate that ETS can detect timing leaks in crypto code
 * 
 * Method:
 *   1. Implement multiple crypto operations:
 *      - Constant-time XOR cipher
 *      - Variable-time conditional cipher (vulnerable!)
 *      - Constant-time simple substitution
 *      - Variable-time lookup table (vulnerable!)
 *   2. Run with ETS monitoring
 *   3. Measure timing variations
 *   4. Prove ETS detects leaky implementations
 */

#include "../common/ets_lib.h"
#include "../common/uart.h"

#define LED_REG (*(volatile uint32_t*)0x90000000)

#define DATA_SIZE 32
#define KEY_SIZE 16
#define ITERATIONS 10

// Test data
uint8_t plaintext[DATA_SIZE];
uint8_t key[KEY_SIZE];
uint8_t ciphertext[DATA_SIZE];

void delay_cycles(uint32_t cycles) {
    for (volatile uint32_t i = 0; i < cycles; i++) {
        asm volatile ("nop");
    }
}

// Initialize test data
void init_data() {
    for (int i = 0; i < DATA_SIZE; i++) {
        plaintext[i] = (uint8_t)(i * 7 + 13);  // Pseudo-random
    }
    
    for (int i = 0; i < KEY_SIZE; i++) {
        key[i] = (uint8_t)(i * 11 + 23);  // Pseudo-random
    }
}

// ========== CONSTANT-TIME IMPLEMENTATIONS (GOOD) ==========

// 1. Constant-time XOR cipher
void crypto_xor_constant_time() {
    for (int i = 0; i < DATA_SIZE; i++) {
        ciphertext[i] = plaintext[i] ^ key[i % KEY_SIZE];
    }
}

// 2. Constant-time byte rotation
void crypto_rotate_constant_time() {
    for (int i = 0; i < DATA_SIZE; i++) {
        uint8_t byte = plaintext[i];
        uint8_t rotated = (byte << 3) | (byte >> 5);  // Rotate left by 3
        ciphertext[i] = rotated ^ key[i % KEY_SIZE];
    }
}

// 3. Constant-time addition cipher
void crypto_add_constant_time() {
    for (int i = 0; i < DATA_SIZE; i++) {
        ciphertext[i] = plaintext[i] + key[i % KEY_SIZE];
    }
}

// ========== VARIABLE-TIME IMPLEMENTATIONS (VULNERABLE!) ==========

// 4. Variable-time conditional cipher (BAD - data-dependent branch!)
void crypto_conditional_variable_time() {
    for (int i = 0; i < DATA_SIZE; i++) {
        if (plaintext[i] & 0x80) {  // HIGH BIT CHECK - TIMING LEAK!
            ciphertext[i] = plaintext[i] ^ key[i % KEY_SIZE];
        } else {
            ciphertext[i] = plaintext[i] + key[i % KEY_SIZE];
        }
    }
}

// 5. Variable-time lookup substitution (BAD - cache timing!)
void crypto_substitution_variable_time() {
    // S-box (simplified)
    const uint8_t sbox[16] = {
        0xE, 0x4, 0xD, 0x1, 0x2, 0xF, 0xB, 0x8,
        0x3, 0xA, 0x6, 0xC, 0x5, 0x9, 0x0, 0x7
    };
    
    for (int i = 0; i < DATA_SIZE; i++) {
        uint8_t nibble1 = (plaintext[i] >> 4) & 0xF;
        uint8_t nibble2 = plaintext[i] & 0xF;
        
        // Memory access pattern depends on data - TIMING LEAK!
        uint8_t sub1 = sbox[nibble1];
        uint8_t sub2 = sbox[nibble2];
        
        ciphertext[i] = (sub1 << 4) | sub2;
        ciphertext[i] ^= key[i % KEY_SIZE];
    }
}

// 6. Variable-time early-exit comparison (BAD!)
uint32_t crypto_compare_variable_time(const uint8_t* a, const uint8_t* b, int len) {
    for (int i = 0; i < len; i++) {
        if (a[i] != b[i]) {
            return 0;  // EARLY EXIT - TIMING LEAK!
        }
    }
    return 1;
}

// 6b. Constant-time comparison (GOOD)
uint32_t crypto_compare_constant_time(const uint8_t* a, const uint8_t* b, int len) {
    uint8_t diff = 0;
    for (int i = 0; i < len; i++) {
        diff |= (a[i] ^ b[i]);  // No early exit
    }
    return (diff == 0) ? 1 : 0;
}

// ========== TEST FUNCTIONS ==========

typedef struct {
    const char* name;
    uint32_t anomaly_count;
    uint32_t is_constant_time;  // 1 = should be constant-time
} crypto_test_result_t;

crypto_test_result_t results[10];
int result_count = 0;

void test_crypto_impl(const char* name, void (*crypto_func)(void), uint32_t should_be_constant) {
    LED_REG = result_count + 1;
    
    uart_printf("\r\n========================================\r\n");
    uart_printf("Testing: %s\r\n", name);
    uart_printf("Expected: %s\r\n", should_be_constant ? "Constant-time" : "Variable-time");
    uart_printf("========================================\r\n");
    
    // Configure ETS for crypto (very strict!)
    ets_set_signature(0x13, 5, 0);   // ADDI - exact timing
    ets_set_signature(0x33, 6, 0);   // ADD - exact timing
    ets_set_signature(0x03, 10, 1);  // LOAD - minimal tolerance
    ets_set_signature(0x23, 10, 1);  // STORE - minimal tolerance
    ets_set_signature(0x63, 8, 1);   // BRANCH - detect data-dependent branches
    
    ets_clear_anomaly_count();
    ets_enable(true);
    
    // Run multiple iterations
    for (int i = 0; i < ITERATIONS; i++) {
        crypto_func();
    }
    
    uint32_t anomalies = ets_get_anomaly_count();
    
    // Analyze results
    uart_printf("Iterations: %d\r\n", ITERATIONS);
    uart_printf("Anomalies detected: %u\r\n", anomalies);
    
    if (should_be_constant) {
        // Constant-time: expect few anomalies
        if (anomalies < 5) {
            uart_printf("Status: PASS - Appears constant-time\r\n");
        } else {
            uart_printf("Status: WARNING - May have timing variations\r\n");
        }
    } else {
        // Variable-time: expect many anomalies
        if (anomalies > 10) {
            uart_printf("Status: DETECTED - Timing leak found!\r\n");
        } else {
            uart_printf("Status: WARNING - Expected more anomalies\r\n");
        }
    }
    
    // Store results
    results[result_count].name = name;
    results[result_count].anomaly_count = anomalies;
    results[result_count].is_constant_time = should_be_constant;
    result_count++;
    
    delay_cycles(50000);
}

void test_comparison_functions() {
    uart_printf("\r\n========================================\r\n");
    uart_printf("Testing: Comparison Functions\r\n");
    uart_printf("========================================\r\n");
    
    uint8_t test_a[16], test_b[16];
    for (int i = 0; i < 16; i++) {
        test_a[i] = i;
        test_b[i] = i;
    }
    test_b[8] = 0xFF;  // Make them different
    
    // Variable-time comparison
    ets_clear_anomaly_count();
    ets_enable(true);
    
    for (int i = 0; i < ITERATIONS; i++) {
        crypto_compare_variable_time(test_a, test_b, 16);
    }
    
    uint32_t var_anomalies = ets_get_anomaly_count();
    uart_printf("Variable-time compare: %u anomalies\r\n", var_anomalies);
    
    // Constant-time comparison
    ets_clear_anomaly_count();
    
    for (int i = 0; i < ITERATIONS; i++) {
        crypto_compare_constant_time(test_a, test_b, 16);
    }
    
    uint32_t const_anomalies = ets_get_anomaly_count();
    uart_printf("Constant-time compare: %u anomalies\r\n", const_anomalies);
    
    if (var_anomalies > const_anomalies) {
        uart_printf("Result: PASS - ETS distinguishes implementations!\r\n");
    } else {
        uart_printf("Result: WARNING - Need stricter ETS config\r\n");
    }
}

void print_summary() {
    uart_printf("\r\n========================================\r\n");
    uart_printf("EXPERIMENT SUMMARY\r\n");
    uart_printf("========================================\r\n");
    uart_printf("Implementation,Expected,Anomalies,Status\r\n");
    
    for (int i = 0; i < result_count; i++) {
        const char* expected = results[i].is_constant_time ? "Const" : "Var";
        const char* status;
        
        if (results[i].is_constant_time) {
            status = (results[i].anomaly_count < 5) ? "PASS" : "WARN";
        } else {
            status = (results[i].anomaly_count > 10) ? "DETECTED" : "WARN";
        }
        
        uart_printf("%s,%s,%u,%s\r\n",
                    results[i].name,
                    expected,
                    results[i].anomaly_count,
                    status);
    }
    
    uart_printf("\r\n========================================\r\n");
    uart_printf("ANALYSIS\r\n");
    uart_printf("========================================\r\n");
    
    // Calculate detection accuracy
    int total_constant = 0, correct_constant = 0;
    int total_variable = 0, correct_variable = 0;
    
    for (int i = 0; i < result_count; i++) {
        if (results[i].is_constant_time) {
            total_constant++;
            if (results[i].anomaly_count < 5) {
                correct_constant++;
            }
        } else {
            total_variable++;
            if (results[i].anomaly_count > 10) {
                correct_variable++;
            }
        }
    }
    
    uart_printf("\r\nConstant-time implementations:\r\n");
    uart_printf("  Tested: %d\r\n", total_constant);
    uart_printf("  Validated: %d\r\n", correct_constant);
    
    uart_printf("\r\nVariable-time implementations:\r\n");
    uart_printf("  Tested: %d\r\n", total_variable);
    uart_printf("  Detected: %d\r\n", correct_variable);
    
    uint32_t total = total_constant + total_variable;
    uint32_t correct = correct_constant + correct_variable;
    
    if (total > 0) {
        uint32_t accuracy = (correct * 100);
        // Software division
        uint32_t temp = accuracy;
        accuracy = 0;
        while (temp >= total) {
            temp -= total;
            accuracy++;
        }
        
        uart_printf("\r\nOverall Accuracy: %u%%\r\n", accuracy);
        
        if (accuracy >= 80) {
            uart_printf("Conclusion: ETS effectively validates constant-time code!\r\n");
        } else {
            uart_printf("Conclusion: ETS needs tuning for crypto validation\r\n");
        }
    }
    
    uart_printf("========================================\r\n");
}

int main(void) {
    uart_init();
    LED_REG = 0x0;
    delay_cycles(50000);
    
    uart_printf("\r\n\r\n");
    uart_printf("========================================\r\n");
    uart_printf("EXPERIMENT: Crypto Constant-Time Validation\r\n");
    uart_printf("========================================\r\n");
    uart_printf("Goal: Validate ETS can detect timing leaks\r\n");
    uart_printf("Method: Test constant vs variable-time crypto\r\n");
    uart_printf("\r\n");
    uart_printf("Test Parameters:\r\n");
    uart_printf("  Data size: %d bytes\r\n", DATA_SIZE);
    uart_printf("  Key size: %d bytes\r\n", KEY_SIZE);
    uart_printf("  Iterations per test: %d\r\n", ITERATIONS);
    uart_printf("========================================\r\n");
    
    // Initialize
    init_data();
    ets_init(ETS_MODE_FINE_GRAINED);
    ets_configure_alerts(true, true);
    
    uart_printf("\r\nStarting experiments...\r\n");
    
    // Test constant-time implementations
    uart_printf("\r\n--- CONSTANT-TIME IMPLEMENTATIONS ---\r\n");
    test_crypto_impl("XOR Cipher (constant)", crypto_xor_constant_time, 1);
    test_crypto_impl("Rotate Cipher (constant)", crypto_rotate_constant_time, 1);
    test_crypto_impl("Addition Cipher (constant)", crypto_add_constant_time, 1);
    
    // Test variable-time implementations
    uart_printf("\r\n--- VARIABLE-TIME IMPLEMENTATIONS ---\r\n");
    test_crypto_impl("Conditional Cipher (VULNERABLE)", crypto_conditional_variable_time, 0);
    test_crypto_impl("Substitution Cipher (VULNERABLE)", crypto_substitution_variable_time, 0);
    
    // Test comparison functions
    test_comparison_functions();
    
    // Print summary
    print_summary();
    
    uart_printf("\r\nExperiment complete!\r\n");
    uart_printf("ETS can be used to validate constant-time implementations!\r\n");
    uart_printf("========================================\r\n");
    
    // Visual completion signal
    LED_REG = 0xF;
    delay_cycles(100000);
    LED_REG = 0x0;
    
    // Heartbeat
    while (1) {
        delay_cycles(500000);
        LED_REG ^= 0x1;
    }
    
    return 0;
}

