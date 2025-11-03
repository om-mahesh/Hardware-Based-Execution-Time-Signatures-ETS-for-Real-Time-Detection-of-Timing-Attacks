/**
 * test_basic.c
 * 
 * Basic ETS functionality test program.
 * Tests:
 * - ETS initialization
 * - Signature configuration
 * - Normal operation (no anomalies)
 * - Status reading
 */

#include "../common/ets_lib.h"

// LED control (memory-mapped GPIO, if available)
#define LED_BASE 0x90000000
#define LED_REG (*(volatile uint32_t*)LED_BASE)

// Simple delay function
void delay(int cycles) {
    for (volatile int i = 0; i < cycles; i++) {
        asm volatile ("nop");
    }
}

// Test function with predictable timing
void predictable_task(void) {
    volatile int sum = 0;
    for (int i = 0; i < 10; i++) {
        sum += i;
    }
}

// Main test
int main(void) {
    // Initialize ETS in fine-grained mode
    ets_init(ETS_MODE_FINE_GRAINED);
    
    // Configure some basic signatures
    // These are examples - actual values depend on PicoRV32 timing
    ets_set_signature(0x13, 2, 1);   // ADDI: 2 cycles ± 1
    ets_set_signature(0x33, 3, 1);   // ADD:  3 cycles ± 1
    ets_set_signature(0x03, 5, 2);   // LOAD: 5 cycles ± 2
    ets_set_signature(0x23, 5, 2);   // STORE: 5 cycles ± 2
    ets_set_signature(0x63, 3, 2);   // BRANCH: 3 cycles ± 2
    
    // Enable ETS monitoring
    ets_enable(true);
    
    // Run predictable task (should not trigger anomalies)
    for (int i = 0; i < 5; i++) {
        predictable_task();
        delay(1000);
    }
    
    // Check for anomalies
    uint32_t anomaly_count = ets_get_anomaly_count();
    
    // Signal result via LED
    if (anomaly_count == 0) {
        LED_REG = 0x1;  // Success: LED on
    } else {
        // Blink LED to indicate anomalies detected
        for (int i = 0; i < anomaly_count && i < 10; i++) {
            LED_REG = 0x1;
            delay(10000);
            LED_REG = 0x0;
            delay(10000);
        }
    }
    
    // Disable ETS
    ets_enable(false);
    
    // Infinite loop
    while (1) {
        delay(100000);
    }
    
    return 0;
}

