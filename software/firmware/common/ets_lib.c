/**
 * ets_lib.c
 * 
 * Implementation of ETS library functions.
 */

#include <stddef.h>
#include "ets_lib.h"

// ========== Initialization ==========

void ets_init(ets_mode_t mode) {
    // Configure mode and enable
    uint32_t ctrl = ETS_CTRL_ENABLE | ((mode & ETS_CTRL_MODE_MASK) << ETS_CTRL_MODE_SHIFT);
    ETS_CTRL = ctrl;
    
    // Configure alerts: enable interrupts and logging by default
    ETS_ALERT_CONFIG = ETS_ALERT_ENABLE | ETS_ALERT_INTERRUPT | ETS_ALERT_LOG;
    
    // Clear counters and log
    ets_clear_anomaly_count();
    ets_clear_log();
}

void ets_enable(bool enable) {
    if (enable) {
        ETS_CTRL |= ETS_CTRL_ENABLE;
    } else {
        ETS_CTRL &= ~ETS_CTRL_ENABLE;
    }
}

// ========== Signature Management ==========

void ets_set_signature(uint8_t instr_id, uint16_t expected_cycles, uint8_t tolerance) {
    if (instr_id >= 64) return;  // Out of bounds
    
    // Pack signature: {expected[31:16], tolerance[15:8], flags[7:0]}
    uint32_t signature = ((uint32_t)expected_cycles << 16) | 
                         ((uint32_t)tolerance << 8) | 
                         0x01;  // flags: enabled
    
    ETS_SIGNATURE_DB[instr_id] = signature;
}

void ets_get_signature(uint8_t instr_id, ets_signature_t* sig) {
    if (instr_id >= 64 || sig == NULL) return;
    
    uint32_t signature = ETS_SIGNATURE_DB[instr_id];
    sig->expected_cycles = (uint16_t)((signature >> 16) & 0xFFFF);
    sig->tolerance       = (uint8_t) ((signature >> 8) & 0xFF);
    sig->flags           = (uint8_t) (signature & 0xFF);
}

// ========== Anomaly Monitoring ==========

void ets_clear_anomaly_count(void) {
    ETS_CTRL |= ETS_CTRL_CLEAR_COUNT;
    // Self-clearing bit
}

uint32_t ets_get_anomaly_count(void) {
    return ETS_ANOMALY_COUNT;
}

void ets_get_last_anomaly(uint32_t* pc, int32_t* delta) {
    if (pc != NULL) {
        *pc = ETS_LAST_ANOMALY_PC;
    }
    if (delta != NULL) {
        *delta = (int32_t)ETS_LAST_ANOMALY_DELTA;
    }
}

void ets_clear_log(void) {
    ETS_CTRL |= ETS_CTRL_CLEAR_LOG;
    // Self-clearing bit
}

bool ets_is_alert_active(void) {
    return (ETS_STATUS & ETS_STATUS_ALERT_ACTIVE) != 0;
}

// ========== Alert Configuration ==========

void ets_configure_alerts(bool enable_irq, bool enable_log) {
    uint32_t config = ETS_ALERT_ENABLE;
    if (enable_irq) config |= ETS_ALERT_INTERRUPT;
    if (enable_log) config |= ETS_ALERT_LOG;
    
    ETS_ALERT_CONFIG = config;
}

// ========== Learning Mode ==========

void ets_start_learning(void) {
    ETS_CTRL |= ETS_CTRL_LEARNING_MODE;
}

void ets_stop_learning(void) {
    ETS_CTRL &= ~ETS_CTRL_LEARNING_MODE;
}

void ets_learn_function(void (*func)(void), int iterations) {
    if (func == NULL) return;
    
    // Enable learning mode
    ets_start_learning();
    
    // Execute function multiple times
    for (int i = 0; i < iterations; i++) {
        func();
    }
    
    // Finalize learning
    ets_stop_learning();
}

// ========== Debug/Status ==========

void ets_print_status(void) {
    // Placeholder - implement when UART is available
    // Would print:
    // - ETS enabled/disabled
    // - Current mode
    // - Anomaly count
    // - Last anomaly PC and delta
}

