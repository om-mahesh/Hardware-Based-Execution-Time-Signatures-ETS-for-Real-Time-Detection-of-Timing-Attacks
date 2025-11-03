/**
 * test_anomaly.c
 * 
 * Test ETS anomaly detection capability.
 * Deliberately introduces timing variations to trigger ETS alerts.
 */

#include "../common/ets_lib.h"

#define LED_BASE 0x90000000
#define LED_REG (*(volatile uint32_t*)LED_BASE)

void delay(int cycles) {
    for (volatile int i = 0; i < cycles; i++) {
        asm volatile ("nop");
    }
}

// Normal function with predictable timing
void normal_function(void) {
    volatile int x = 0;
    x = x + 1;
    x = x + 2;
    x = x + 3;
}

// Anomalous function with unpredictable timing (simulates attack)
void anomalous_function(void) {
    volatile int x = 0;
    // Add extra iterations to cause timing anomaly
    for (int i = 0; i < 100; i++) {
        x = x + i;
    }
}

int main(void) {
    // Initialize ETS
    ets_init(ETS_MODE_FINE_GRAINED);
    
    // Set tight timing constraints
    ets_set_signature(0x13, 2, 0);   // ADDI: 2 cycles, 0 tolerance (strict!)
    ets_set_signature(0x33, 3, 0);   // ADD:  3 cycles, 0 tolerance
    
    // Configure alerts
    ets_configure_alerts(true, true);  // Enable interrupts and logging
    
    // Enable monitoring
    ets_enable(true);
    
    // Phase 1: Run normal function (should not trigger)
    LED_REG = 0x1;  // LED on
    for (int i = 0; i < 10; i++) {
        normal_function();
    }
    uint32_t count1 = ets_get_anomaly_count();
    delay(50000);
    
    // Phase 2: Run anomalous function (should trigger alerts!)
    LED_REG = 0x2;  // LED pattern change
    for (int i = 0; i < 10; i++) {
        anomalous_function();
    }
    uint32_t count2 = ets_get_anomaly_count();
    delay(50000);
    
    // Phase 3: Check results
    LED_REG = 0x0;  // LED off
    
    // If anomalies detected in phase 2 but not phase 1, test passed!
    if (count1 == 0 && count2 > 0) {
        // Success! Blink LED rapidly
        while (1) {
            LED_REG = 0x1;
            delay(5000);
            LED_REG = 0x0;
            delay(5000);
        }
    } else {
        // Test failed - slow blink
        while (1) {
            LED_REG = 0x1;
            delay(50000);
            LED_REG = 0x0;
            delay(50000);
        }
    }
    
    return 0;
}

