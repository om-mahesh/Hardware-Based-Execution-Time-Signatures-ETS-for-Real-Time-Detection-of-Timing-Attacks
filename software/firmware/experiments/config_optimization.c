/**
 * config_optimization.c
 * 
 * EXPERIMENT: Configuration Optimization
 * 
 * Goal: Find optimal ETS tolerance settings by measuring:
 *   - False Positive Rate (FPR) with different configs
 *   - True Positive Rate (TPR) with different configs
 *   - Plot ROC curve (TPR vs FPR)
 * 
 * Method:
 *   1. Test 3 configurations: Permissive, Strict, Research
 *   2. For each config:
 *      a. Run normal code → measure FP rate
 *      b. Inject timing attacks → measure TP rate
 *   3. Output data for ROC curve plotting
 */

#include "../common/ets_lib.h"
#include "../common/uart.h"

#define LED_REG (*(volatile uint32_t*)0x90000000)

// Experiment parameters
#define NORMAL_ITERATIONS 100
#define ATTACK_ITERATIONS 20

// Results storage
typedef struct {
    const char* config_name;
    uint32_t tolerance;
    uint32_t fp_count;      // False positives in normal code
    uint32_t tp_count;      // True positives in attack code
    uint32_t fp_rate;       // FP rate (%)
    uint32_t tp_rate;       // TP rate (%)
} config_result_t;

config_result_t results[5];
int result_count = 0;

void delay_cycles(uint32_t cycles) {
    for (volatile uint32_t i = 0; i < cycles; i++) {
        asm volatile ("nop");
    }
}

// Test configurations with varying strictness
void config_permissive() {
    ets_set_signature(0x13, 10, 10);  // ADDI: 10 cycles ±10
    ets_set_signature(0x33, 15, 10);  // ADD:  15 cycles ±10
    ets_set_signature(0x03, 20, 15);  // LOAD: 20 cycles ±15
}

void config_moderate() {
    ets_set_signature(0x13, 8, 5);    // ADDI: 8 cycles ±5
    ets_set_signature(0x33, 10, 5);   // ADD:  10 cycles ±5
    ets_set_signature(0x03, 15, 8);   // LOAD: 15 cycles ±8
}

void config_strict() {
    ets_set_signature(0x13, 5, 1);    // ADDI: 5 cycles ±1
    ets_set_signature(0x33, 6, 1);    // ADD:  6 cycles ±1
    ets_set_signature(0x03, 10, 2);   // LOAD: 10 cycles ±2
}

void config_very_strict() {
    ets_set_signature(0x13, 5, 0);    // ADDI: 5 cycles ±0 (exact!)
    ets_set_signature(0x33, 6, 0);    // ADD:  6 cycles ±0 (exact!)
    ets_set_signature(0x03, 10, 1);   // LOAD: 10 cycles ±1
}

void config_custom(uint32_t tolerance) {
    ets_set_signature(0x13, 5, tolerance);
    ets_set_signature(0x33, 6, tolerance);
    ets_set_signature(0x03, 10, tolerance);
}

// Normal code - should NOT trigger anomalies
void run_normal_code() {
    volatile uint32_t sum = 0;
    for (int i = 0; i < 10; i++) {
        sum += i;
    }
}

// Attack simulation - SHOULD trigger anomalies
void run_attack_code(int intensity) {
    volatile uint32_t sum = 0;
    for (int i = 0; i < 10; i++) {
        sum += i;
        // Variable timing delay (simulates timing attack)
        for (volatile int j = 0; j < (i * intensity); j++) {
            asm volatile ("nop");
        }
    }
}

// Test a specific configuration
void test_configuration(const char* name, void (*config_func)(void), uint32_t tolerance) {
    LED_REG = result_count + 1;
    
    uart_printf("\r\n========================================\r\n");
    uart_printf("Testing Configuration: %s\r\n", name);
    uart_printf("Tolerance: %u cycles\r\n", tolerance);
    uart_printf("========================================\r\n");
    
    // Apply configuration
    config_func();
    ets_enable(true);
    
    // Phase 1: Test False Positive Rate (normal code)
    uart_printf("\r\nPhase 1: Testing False Positive Rate...\r\n");
    ets_clear_anomaly_count();
    
    for (int i = 0; i < NORMAL_ITERATIONS; i++) {
        run_normal_code();
    }
    
    uint32_t fp_count = ets_get_anomaly_count();
    uint32_t fp_rate = (fp_count * 100);
    // Software division
    uint32_t temp = fp_rate;
    fp_rate = 0;
    while (temp >= NORMAL_ITERATIONS) {
        temp -= NORMAL_ITERATIONS;
        fp_rate++;
    }
    
    uart_printf("Normal iterations: %d\r\n", NORMAL_ITERATIONS);
    uart_printf("False positives: %u\r\n", fp_count);
    uart_printf("FP Rate: %u%%\r\n", fp_rate);
    
    // Phase 2: Test True Positive Rate (attack simulation)
    uart_printf("\r\nPhase 2: Testing True Positive Rate...\r\n");
    ets_clear_anomaly_count();
    
    int attack_intensity = 5; // Moderate attack intensity
    for (int i = 0; i < ATTACK_ITERATIONS; i++) {
        run_attack_code(attack_intensity);
    }
    
    uint32_t tp_count = ets_get_anomaly_count();
    uint32_t tp_rate = (tp_count * 100);
    // Software division
    temp = tp_rate;
    tp_rate = 0;
    while (temp >= ATTACK_ITERATIONS) {
        temp -= ATTACK_ITERATIONS;
        tp_rate++;
    }
    
    uart_printf("Attack iterations: %d\r\n", ATTACK_ITERATIONS);
    uart_printf("True positives: %u\r\n", tp_count);
    uart_printf("TP Rate: %u%%\r\n", tp_rate);
    
    // Store results
    results[result_count].config_name = name;
    results[result_count].tolerance = tolerance;
    results[result_count].fp_count = fp_count;
    results[result_count].tp_count = tp_count;
    results[result_count].fp_rate = fp_rate;
    results[result_count].tp_rate = tp_rate;
    result_count++;
    
    uart_printf("\r\nResult: FPR=%u%%, TPR=%u%%\r\n", fp_rate, tp_rate);
    
    delay_cycles(50000);
}

// Print ROC data for plotting
void print_roc_data() {
    uart_printf("\r\n========================================\r\n");
    uart_printf("ROC CURVE DATA\r\n");
    uart_printf("========================================\r\n");
    uart_printf("Configuration,Tolerance,FPR,TPR\r\n");
    
    for (int i = 0; i < result_count; i++) {
        uart_printf("%s,%u,%u,%u\r\n",
                    results[i].config_name,
                    results[i].tolerance,
                    results[i].fp_rate,
                    results[i].tp_rate);
    }
    
    uart_printf("\r\n========================================\r\n");
    uart_printf("ANALYSIS\r\n");
    uart_printf("========================================\r\n");
    
    // Find optimal configuration (best TPR with acceptable FPR)
    int best_config = -1;
    uint32_t best_score = 0;
    
    for (int i = 0; i < result_count; i++) {
        // Score = TPR - (FPR * 2)  (penalize false positives more)
        uint32_t score = results[i].tp_rate;
        if (score > (results[i].fp_rate * 2)) {
            score -= (results[i].fp_rate * 2);
        } else {
            score = 0;
        }
        
        if (score > best_score) {
            best_score = score;
            best_config = i;
        }
    }
    
    if (best_config >= 0) {
        uart_printf("\r\nOptimal Configuration: %s\r\n", results[best_config].config_name);
        uart_printf("  Tolerance: %u cycles\r\n", results[best_config].tolerance);
        uart_printf("  FP Rate: %u%%\r\n", results[best_config].fp_rate);
        uart_printf("  TP Rate: %u%%\r\n", results[best_config].tp_rate);
        uart_printf("  Score: %u\r\n", best_score);
    }
    
    uart_printf("\r\n========================================\r\n");
}

// Main experiment
int main(void) {
    uart_init();
    LED_REG = 0x0;
    delay_cycles(50000);
    
    uart_printf("\r\n\r\n");
    uart_printf("========================================\r\n");
    uart_printf("EXPERIMENT: Configuration Optimization\r\n");
    uart_printf("========================================\r\n");
    uart_printf("Goal: Find optimal ETS tolerance settings\r\n");
    uart_printf("Method: Measure TPR vs FPR for different configs\r\n");
    uart_printf("\r\n");
    uart_printf("Test Parameters:\r\n");
    uart_printf("  Normal iterations: %d\r\n", NORMAL_ITERATIONS);
    uart_printf("  Attack iterations: %d\r\n", ATTACK_ITERATIONS);
    uart_printf("========================================\r\n");
    
    // Initialize ETS
    ets_init(ETS_MODE_FINE_GRAINED);
    ets_configure_alerts(true, true);
    
    // Test different configurations
    uart_printf("\r\nStarting experiments...\r\n");
    
    test_configuration("Permissive", config_permissive, 10);
    test_configuration("Moderate", config_moderate, 5);
    test_configuration("Strict", config_strict, 1);
    test_configuration("Very Strict", config_very_strict, 0);
    
    // Print ROC data
    print_roc_data();
    
    uart_printf("\r\nExperiment complete!\r\n");
    uart_printf("Use this data to plot ROC curve (TPR vs FPR)\r\n");
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

