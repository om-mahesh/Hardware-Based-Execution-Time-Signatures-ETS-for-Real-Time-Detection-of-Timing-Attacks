/**
 * uart.h
 * 
 * Simple UART library for data logging
 * Provides printf-style output over UART
 */

#ifndef UART_H
#define UART_H

#include <stdint.h>
#include <stddef.h>

// UART base address (memory-mapped)
#define UART_BASE 0x80000000

// UART registers
#define UART_TX_DATA  (*(volatile uint32_t*)(UART_BASE + 0x00))
#define UART_TX_READY (*(volatile uint32_t*)(UART_BASE + 0x04))

// Initialize UART (optional - hardware auto-initializes)
void uart_init(void);

// Send single character
void uart_putc(char c);

// Send string
void uart_puts(const char* str);

// Send string with newline
void uart_putln(const char* str);

// Print hexadecimal number
void uart_puthex(uint32_t value);

// Print decimal number
void uart_putdec(int32_t value);

// Print unsigned decimal
void uart_putuint(uint32_t value);

// Simple printf-style output
// Supports: %d (decimal), %u (unsigned), %x (hex), %s (string), %c (char)
void uart_printf(const char* format, ...);

#endif // UART_H

