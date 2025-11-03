/**
 * test_learning.c
 * 
 * Test ETS learning mode functionality.
 * Demonstrates how to use learning mode to automatically build timing signatures.
 */

#include "../common/ets_lib.h"

#define LED_BASE 0x90000000
#define LED_REG (*(volatile uint32_t*)LED_BASE)

void delay(int cycles) {
    for (volatile int i = 0; i < cycles; i++) {
        asm volatile ("nop");
    }
}

// Target function to learn (typical IoT task)
void iot_sensor_read(void) {
    volatile uint32_t sensor_data = 0;
    
    // Simulate sensor reading (memory access + computation)
    sensor_data = *(volatile uint32_t*)0x00001000;
    sensor_data = sensor_data * 7 + 13;
    sensor_data = sensor_data & 0xFFFF;
    
    // Write back result
    *(volatile uint32_t*)0x00001004 = sensor_data;
}

// Another task to learn
void iot_data_process(void) {
    volatile int sum = 0;
    for (int i = 0; i < 20; i++) {
        sum += i * i;
    }
}

int main(void) {
    LED_REG = 0x1;  // Signal start
    
    // Initialize ETS but don't enable monitoring yet
    ets_init(ETS_MODE_FINE_GRAINED);
    ets_enable(false);
    
    // Phase 1: Learning mode
    LED_REG = 0x2;
    
    // Learn timing signatures for iot_sensor_read
    ets_learn_function(iot_sensor_read, 50);  // Run 50 times
    delay(10000);
    
    // Learn timing signatures for iot_data_process
    ets_learn_function(iot_data_process, 50);
    delay(10000);
    
    // At this point, ETS has built a timing database
    // Check a few signatures (optional)
    ets_signature_t sig;
    ets_get_signature(0x13, &sig);  // ADDI instruction
    
    // Phase 2: Enable monitoring with learned signatures
    LED_REG = 0x3;
    ets_enable(true);
    
    // Run tasks normally - should not trigger anomalies
    for (int i = 0; i < 20; i++) {
        iot_sensor_read();
        delay(1000);
        iot_data_process();
        delay(1000);
    }
    
    // Check results
    uint32_t anomaly_count = ets_get_anomaly_count();
    
    LED_REG = 0x4;
    
    if (anomaly_count == 0) {
        // Success: Learning worked correctly
        // Blink LED fast
        while (1) {
            LED_REG = 0xF;
            delay(5000);
            LED_REG = 0x0;
            delay(5000);
        }
    } else {
        // Some anomalies detected - possibly false positives
        // Blink LED slowly
        while (1) {
            LED_REG = 0x1;
            delay(25000);
            LED_REG = 0x0;
            delay(25000);
        }
    }
    
    return 0;
}

