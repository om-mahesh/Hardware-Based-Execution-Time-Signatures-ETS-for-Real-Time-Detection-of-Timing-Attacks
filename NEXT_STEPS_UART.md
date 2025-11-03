# Next Step: Add UART for Data Logging

## Why UART?
- **Serial output** from board to PC
- **Real data** instead of LED observation
- **CSV export** for analysis
- **Research-grade** data collection

## Implementation Plan:

### 1. Add UART to Design (Hardware)

**File**: `rtl/uart/uart_tx.v` (simple transmit-only)

```verilog
module uart_tx #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] tx_data,
    input wire tx_valid,
    output reg tx_ready,
    output wire tx_pin
);
    // Simple UART transmitter
    // ~50 lines of code
endmodule
```

### 2. Connect UART to PS UART Pins

**File**: `constraints/zybo_z7.xdc`

The Zybo Z7 has UART accessible via **USB-UART bridge**:
- No additional wiring needed
- Shows up as COM port on PC
- Just enable the pins

### 3. Add Printf Library

**File**: `software/firmware/common/uart_printf.c`

Simple printf-style output:
```c
uart_printf("Test %d: PASS - Anomalies: %d\n", test_id, count);
```

### 4. Modify Tests to Print Results

```c
void test1_timing_accuracy() {
    // ... test code ...
    
    uart_printf("Test 1: Timing Accuracy\n");
    uart_printf("  Anomalies: %d\n", anomalies);
    uart_printf("  Status: %s\n", passed ? "PASS" : "FAIL");
}
```

### 5. Collect Data on PC

Use serial terminal (PuTTY, RealTerm, etc.):
- Connect to COM port
- Set 115200 baud
- Log to CSV file
- Analyze with Python tools

## Timeline:
- **Hardware UART**: 2-3 hours
- **Software UART**: 1-2 hours
- **Test integration**: 1 hour
- **Total**: ~6 hours

## Benefit:
- **10x better data collection**
- **Real numbers** for analysis
- **Publication-ready graphs**
- **Scientific validation**

## Want me to implement this?
Just say "ADD UART" and I'll create all the files!

