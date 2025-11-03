/**
 * uart.c
 * 
 * Simple UART library implementation
 */

#include "uart.h"
#include <stdarg.h>

// Initialize UART (hardware handles this, but good practice)
void uart_init(void) {
    // Nothing needed - hardware auto-initializes
    // Could add baud rate configuration here if needed
}

// Send single character
void uart_putc(char c) {
    // Wait for UART to be ready
    while (UART_TX_READY == 0) {
        // Spin wait
    }
    
    // Send character
    UART_TX_DATA = (uint32_t)c;
}

// Send string
void uart_puts(const char* str) {
    if (!str) return;
    
    while (*str) {
        uart_putc(*str);
        str++;
    }
}

// Send string with newline
void uart_putln(const char* str) {
    uart_puts(str);
    uart_putc('\r');
    uart_putc('\n');
}

// Print hexadecimal number
void uart_puthex(uint32_t value) {
    const char hex_chars[] = "0123456789ABCDEF";
    
    uart_puts("0x");
    
    int started = 0;
    for (int i = 7; i >= 0; i--) {
        int nibble = (value >> (i * 4)) & 0xF;
        if (nibble != 0 || started || i == 0) {
            uart_putc(hex_chars[nibble]);
            started = 1;
        }
    }
}

// Software division helpers (no hardware division support)
static uint32_t div10(uint32_t n) {
    uint32_t q = 0;
    while (n >= 10) {
        n -= 10;
        q++;
    }
    return q;
}

static uint32_t mod10(uint32_t n) {
    while (n >= 10) {
        n -= 10;
    }
    return n;
}

// Print unsigned decimal
void uart_putuint(uint32_t value) {
    if (value == 0) {
        uart_putc('0');
        return;
    }
    
    char buffer[12];  // Max 10 digits for 32-bit + sign + null
    int pos = 0;
    
    while (value > 0) {
        buffer[pos++] = '0' + mod10(value);
        value = div10(value);
    }
    
    // Print in reverse order
    for (int i = pos - 1; i >= 0; i--) {
        uart_putc(buffer[i]);
    }
}

// Print signed decimal
void uart_putdec(int32_t value) {
    if (value < 0) {
        uart_putc('-');
        value = -value;
    }
    uart_putuint((uint32_t)value);
}

// Simple printf implementation
// Supports: %d, %u, %x, %s, %c, %%
void uart_printf(const char* format, ...) {
    if (!format) return;
    
    va_list args;
    va_start(args, format);
    
    while (*format) {
        if (*format == '%') {
            format++;
            
            switch (*format) {
                case 'd': {  // Signed decimal
                    int32_t val = va_arg(args, int32_t);
                    uart_putdec(val);
                    break;
                }
                
                case 'u': {  // Unsigned decimal
                    uint32_t val = va_arg(args, uint32_t);
                    uart_putuint(val);
                    break;
                }
                
                case 'x': {  // Hexadecimal
                    uint32_t val = va_arg(args, uint32_t);
                    uart_puthex(val);
                    break;
                }
                
                case 's': {  // String
                    const char* str = va_arg(args, const char*);
                    uart_puts(str ? str : "(null)");
                    break;
                }
                
                case 'c': {  // Character
                    char c = (char)va_arg(args, int);
                    uart_putc(c);
                    break;
                }
                
                case '%': {  // Literal %
                    uart_putc('%');
                    break;
                }
                
                default: {
                    uart_putc('%');
                    uart_putc(*format);
                    break;
                }
            }
        } else {
            uart_putc(*format);
        }
        
        format++;
    }
    
    va_end(args);
}

