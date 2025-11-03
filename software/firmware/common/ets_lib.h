/**
 * ets_lib.h
 * 
 * Software library for interacting with ETS (Execution Time Signatures) module.
 * Provides C API for configuring, monitoring, and querying ETS hardware.
 */

#ifndef ETS_LIB_H
#define ETS_LIB_H

#include <stdint.h>
#include <stdbool.h>

// ========== ETS Register Base Address ==========
#define ETS_BASE_ADDR       0x80000000

// ========== ETS Register Offsets ==========
#define ETS_CTRL            (*(volatile uint32_t*)(ETS_BASE_ADDR + 0x000))
#define ETS_STATUS          (*(volatile uint32_t*)(ETS_BASE_ADDR + 0x004))
#define ETS_INTR_EN         (*(volatile uint32_t*)(ETS_BASE_ADDR + 0x008))
#define ETS_ALERT_CONFIG    (*(volatile uint32_t*)(ETS_BASE_ADDR + 0x00C))
#define ETS_CURRENT_CYCLES  (*(volatile uint32_t*)(ETS_BASE_ADDR + 0x010))
#define ETS_LAST_ANOMALY_PC (*(volatile uint32_t*)(ETS_BASE_ADDR + 0x014))
#define ETS_LAST_ANOMALY_DELTA (*(volatile uint32_t*)(ETS_BASE_ADDR + 0x018))
#define ETS_ANOMALY_COUNT   (*(volatile uint32_t*)(ETS_BASE_ADDR + 0x01C))

// Signature database (64 entries)
#define ETS_SIGNATURE_DB    ((volatile uint32_t*)(ETS_BASE_ADDR + 0x100))

// Log buffer (128 entries × 8 bytes = 1KB)
#define ETS_LOG_BUFFER      ((volatile uint32_t*)(ETS_BASE_ADDR + 0x200))

// ========== ETS Control Register Bits ==========
#define ETS_CTRL_ENABLE         (1 << 0)
#define ETS_CTRL_CLEAR_COUNT    (1 << 1)
#define ETS_CTRL_CLEAR_LOG      (1 << 2)
#define ETS_CTRL_LEARNING_MODE  (1 << 3)

#define ETS_CTRL_MODE_SHIFT     4
#define ETS_CTRL_MODE_MASK      0xF
#define ETS_CTRL_MODE_DISABLED  (0 << ETS_CTRL_MODE_SHIFT)
#define ETS_CTRL_MODE_FINE      (1 << ETS_CTRL_MODE_SHIFT)
#define ETS_CTRL_MODE_COARSE    (2 << ETS_CTRL_MODE_SHIFT)
#define ETS_CTRL_MODE_TASK      (3 << ETS_CTRL_MODE_SHIFT)

// ========== ETS Status Register Bits ==========
#define ETS_STATUS_ALERT_ACTIVE (1 << 0)
#define ETS_STATUS_IRQ_PENDING  (1 << 1)
#define ETS_STATUS_LOG_FULL     (1 << 2)
#define ETS_STATUS_LEARNING     (1 << 3)

// ========== ETS Alert Config Register Bits ==========
#define ETS_ALERT_ENABLE        (1 << 0)
#define ETS_ALERT_INTERRUPT     (1 << 1)
#define ETS_ALERT_HALT          (1 << 2)
#define ETS_ALERT_LOG           (1 << 3)

// ========== ETS Monitoring Modes ==========
typedef enum {
    ETS_MODE_DISABLED = 0,
    ETS_MODE_FINE_GRAINED = 1,    // Per-instruction
    ETS_MODE_COARSE_GRAINED = 2,  // Per-basic-block
    ETS_MODE_TASK_LEVEL = 3       // Per-task
} ets_mode_t;

// ========== ETS Signature Structure ==========
typedef struct {
    uint16_t expected_cycles;
    uint8_t  tolerance;
    uint8_t  flags;
} ets_signature_t;

// ========== Function Prototypes ==========

/**
 * Initialize ETS module
 * @param mode: Monitoring mode (fine/coarse/task)
 */
void ets_init(ets_mode_t mode);

/**
 * Enable or disable ETS monitoring
 * @param enable: true to enable, false to disable
 */
void ets_enable(bool enable);

/**
 * Set timing signature for a specific instruction type
 * @param instr_id: Instruction identifier (0-63)
 * @param expected_cycles: Expected execution time in cycles
 * @param tolerance: Allowed deviation (± cycles)
 */
void ets_set_signature(uint8_t instr_id, uint16_t expected_cycles, uint8_t tolerance);

/**
 * Get timing signature for a specific instruction type
 * @param instr_id: Instruction identifier (0-63)
 * @param sig: Pointer to signature structure to fill
 */
void ets_get_signature(uint8_t instr_id, ets_signature_t* sig);

/**
 * Clear anomaly counter
 */
void ets_clear_anomaly_count(void);

/**
 * Get total number of anomalies detected
 * @return: Anomaly count
 */
uint32_t ets_get_anomaly_count(void);

/**
 * Get information about the last detected anomaly
 * @param pc: Pointer to store program counter (can be NULL)
 * @param delta: Pointer to store timing delta (can be NULL)
 */
void ets_get_last_anomaly(uint32_t* pc, int32_t* delta);

/**
 * Clear the log buffer
 */
void ets_clear_log(void);

/**
 * Check if ETS alert is active
 * @return: true if alert is active
 */
bool ets_is_alert_active(void);

/**
 * Configure alert behavior
 * @param enable_irq: Generate interrupt on anomaly
 * @param enable_log: Log anomalies to buffer
 */
void ets_configure_alerts(bool enable_irq, bool enable_log);

/**
 * Enable learning mode to automatically build timing signatures
 * Call this before running representative workload
 */
void ets_start_learning(void);

/**
 * Disable learning mode and finalize signatures
 */
void ets_stop_learning(void);

/**
 * Run a function repeatedly in learning mode to build its timing signature
 * @param func: Function pointer to profile
 * @param iterations: Number of times to execute
 */
void ets_learn_function(void (*func)(void), int iterations);

/**
 * Print ETS status to console (if UART available)
 */
void ets_print_status(void);

#endif // ETS_LIB_H

