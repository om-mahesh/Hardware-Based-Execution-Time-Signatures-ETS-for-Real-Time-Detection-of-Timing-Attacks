/**
 * interactive_interface.c
 * 
 * Interactive software interface for ETS RISC-V system.
 * Provides menu-driven control and testing capabilities.
 * 
 * Features:
 * - Real-time ETS monitoring
 * - Signature configuration
 * - Test execution
 * - Data logging
 * - Performance measurement
 */

#include "../common/ets_lib.h"

// GPIO & LED control
#define GPIO_BASE 0x90000000
#define LED_REG   (*(volatile uint32_t*)(GPIO_BASE + 0x00))
#define BTN_REG   (*(volatile uint32_t*)(GPIO_BASE + 0x04))
#define SW_REG    (*(volatile uint32_t*)(GPIO_BASE + 0x08))

// Test results storage
typedef struct {
    uint32_t test_id;
    uint32_t cycles_measured;
    uint32_t anomalies_detected;
    uint32_t pc_at_anomaly;
    int32_t  timing_delta;
    uint32_t timestamp;
} test_result_t;

#define MAX_RESULTS 10
test_result_t results[MAX_RESULTS];
int result_count = 0;

// Global state
static uint32_t timestamp_counter = 0;
static uint8_t current_mode = 0;
static bool ets_active = false;

// ========== Utility Functions ==========

void delay_cycles(uint32_t cycles) {
    for (volatile uint32_t i = 0; i < cycles; i++) {
        asm volatile ("nop");
    }
}

void led_pattern(uint8_t pattern) {
    LED_REG = pattern;
}

void led_blink(int times, uint32_t delay) {
    for (int i = 0; i < times; i++) {
        LED_REG = 0xF;
        delay_cycles(delay);
        LED_REG = 0x0;
        delay_cycles(delay);
    }
}

// Signal via LED patterns
void signal_ready() {
    led_pattern(0x1);  // LED0 ON = Ready
}

void signal_running() {
    led_pattern(0x3);  // LED0+1 ON = Running
}

void signal_error() {
    led_blink(5, 10000);  // Blink 5 times = Error
    led_pattern(0xF);  // All ON = Error state
}

void signal_success() {
    led_blink(2, 20000);  // Blink 2 times = Success
    led_pattern(0x1);
}

// ========== Test Functions ==========

// Predictable timing test (should NOT trigger anomaly)
void test_normal_execution() {
    volatile uint32_t sum = 0;
    for (int i = 0; i < 10; i++) {
        sum += i;
    }
}

// Variable timing test (SHOULD trigger anomaly with strict settings)
void test_variable_execution() {
    volatile uint32_t sum = 0;
    for (int i = 0; i < 100; i++) {  // More iterations = longer time
        sum += i * i;
    }
}

// Memory-intensive test
void test_memory_access() {
    volatile uint32_t data[20];
    for (int i = 0; i < 20; i++) {
        data[i] = i * 2;
    }
    volatile uint32_t sum = 0;
    for (int i = 0; i < 20; i++) {
        sum += data[i];
    }
}

// Branch-heavy test
void test_branch_heavy() {
    volatile int result = 0;
    for (int i = 0; i < 20; i++) {
        if (i % 2 == 0) {
            result += i;
        } else {
            result -= i;
        }
    }
}

// Simulated crypto operation (constant-time goal)
void test_crypto_simulation() {
    volatile uint32_t key[4] = {0x12345678, 0x9ABCDEF0, 0x11111111, 0x22222222};
    volatile uint32_t data[4] = {0xAABBCCDD, 0xEEFF0011, 0x22334455, 0x66778899};
    
    // Simulate simple XOR encryption (should be constant-time)
    for (int i = 0; i < 4; i++) {
        data[i] ^= key[i];
    }
}

// ========== ETS Configuration Presets ==========

void ets_config_permissive() {
    // Permissive - large tolerances, few false positives
    ets_set_signature(0x13, 10, 10);  // ADDI
    ets_set_signature(0x33, 15, 10);  // ADD
    ets_set_signature(0x03, 20, 15);  // LOAD
    ets_set_signature(0x23, 20, 15);  // STORE
    ets_set_signature(0x63, 15, 10);  // BRANCH
    led_blink(1, 5000);  // Signal: permissive mode
}

void ets_config_strict() {
    // Strict - tight tolerances, will detect variations
    ets_set_signature(0x13, 5, 1);    // ADDI
    ets_set_signature(0x33, 6, 1);    // ADD
    ets_set_signature(0x03, 10, 2);   // LOAD
    ets_set_signature(0x23, 10, 2);   // STORE
    ets_set_signature(0x63, 8, 2);    // BRANCH
    led_blink(3, 5000);  // Signal: strict mode
}

void ets_config_research() {
    // Research - very tight for timing analysis
    ets_set_signature(0x13, 5, 0);    // ADDI - NO tolerance
    ets_set_signature(0x33, 6, 0);    // ADD - NO tolerance
    ets_set_signature(0x03, 10, 1);   // LOAD
    ets_set_signature(0x23, 10, 1);   // STORE
    ets_set_signature(0x63, 8, 1);    // BRANCH
    led_blink(5, 5000);  // Signal: research mode
}

// ========== Test Execution ==========

void run_test_suite(uint8_t mode) {
    signal_running();
    
    // Clear previous results
    ets_clear_anomaly_count();
    uint32_t baseline_anomalies = 0;
    
    // Test 1: Normal execution
    test_normal_execution();
    delay_cycles(1000);
    uint32_t test1_anomalies = ets_get_anomaly_count();
    
    // Test 2: Variable execution
    test_variable_execution();
    delay_cycles(1000);
    uint32_t test2_anomalies = ets_get_anomaly_count() - test1_anomalies;
    
    // Test 3: Memory access
    test_memory_access();
    delay_cycles(1000);
    uint32_t test3_anomalies = ets_get_anomaly_count() - test1_anomalies - test2_anomalies;
    
    // Test 4: Branch heavy
    test_branch_heavy();
    delay_cycles(1000);
    uint32_t test4_anomalies = ets_get_anomaly_count() - test1_anomalies - test2_anomalies - test3_anomalies;
    
    // Test 5: Crypto simulation
    test_crypto_simulation();
    delay_cycles(1000);
    uint32_t test5_anomalies = ets_get_anomaly_count() - test1_anomalies - test2_anomalies - test3_anomalies - test4_anomalies;
    
    // Store results
    if (result_count < MAX_RESULTS) {
        results[result_count].test_id = mode;
        results[result_count].cycles_measured = timestamp_counter;
        results[result_count].anomalies_detected = ets_get_anomaly_count();
        ets_get_last_anomaly(&results[result_count].pc_at_anomaly, 
                            &results[result_count].timing_delta);
        results[result_count].timestamp = timestamp_counter;
        result_count++;
    }
    
    // Display results via LED pattern
    uint32_t total_anomalies = ets_get_anomaly_count();
    
    if (total_anomalies == 0) {
        signal_success();  // All tests passed
    } else if (total_anomalies < 5) {
        led_pattern(0x3);  // Few anomalies
    } else if (total_anomalies < 20) {
        led_pattern(0x7);  // Some anomalies
    } else {
        led_pattern(0xF);  // Many anomalies
    }
}

// ========== State Machine / Menu System ==========

typedef enum {
    STATE_INIT,
    STATE_IDLE,
    STATE_CONFIG_PERMISSIVE,
    STATE_CONFIG_STRICT,
    STATE_CONFIG_RESEARCH,
    STATE_RUN_TESTS,
    STATE_DISPLAY_RESULTS,
    STATE_CONTINUOUS_MONITOR
} system_state_t;

system_state_t current_state = STATE_INIT;

void process_button_input() {
    // Use switches and buttons for control
    // SW0: ETS on/off
    // SW1: Mode select
    // BTN1: Run tests
    // BTN2: Change config
    
    // Simulated button reading (replace with actual GPIO)
    static uint32_t btn_counter = 0;
    btn_counter++;
    
    // Every 50000 cycles, change state (simulated button press)
    if (btn_counter > 50000) {
        btn_counter = 0;
        
        switch (current_state) {
            case STATE_INIT:
                current_state = STATE_IDLE;
                signal_ready();
                break;
                
            case STATE_IDLE:
                current_state = STATE_CONFIG_PERMISSIVE;
                ets_config_permissive();
                ets_active = true;
                break;
                
            case STATE_CONFIG_PERMISSIVE:
                current_state = STATE_RUN_TESTS;
                break;
                
            case STATE_RUN_TESTS:
                run_test_suite(current_mode);
                current_state = STATE_DISPLAY_RESULTS;
                break;
                
            case STATE_DISPLAY_RESULTS:
                current_state = STATE_CONFIG_STRICT;
                ets_config_strict();
                break;
                
            case STATE_CONFIG_STRICT:
                current_mode++;
                current_state = STATE_RUN_TESTS;
                break;
                
            case STATE_CONTINUOUS_MONITOR:
                current_state = STATE_IDLE;
                break;
                
            default:
                current_state = STATE_IDLE;
        }
    }
}

// ========== Main Interface ==========

int main(void) {
    // Initialize
    led_pattern(0x0);
    delay_cycles(10000);
    
    // Startup sequence
    led_blink(3, 10000);  // Blink 3 times = Starting
    
    // Initialize ETS
    ets_init(ETS_MODE_FINE_GRAINED);
    ets_configure_alerts(true, true);
    
    // Start with permissive config
    ets_config_permissive();
    ets_enable(true);
    ets_active = true;
    
    signal_ready();
    
    // Main loop - State machine
    while (1) {
        timestamp_counter++;
        
        // Process state transitions
        process_button_input();
        
        // Periodic monitoring
        if (ets_active && (timestamp_counter % 100000 == 0)) {
            uint32_t anomalies = ets_get_anomaly_count();
            
            // Visual feedback
            if (anomalies > 0) {
                led_pattern(0xF);  // Alert
                delay_cycles(5000);
            } else {
                led_pattern(0x1);  // Normal
            }
        }
        
        // Small delay to prevent tight loop
        if (timestamp_counter % 1000 == 0) {
            delay_cycles(10);
        }
    }
    
    return 0;
}

