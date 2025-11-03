/**
 * start.S
 * 
 * Startup code for RISC-V bare-metal programs.
 * Sets up stack, initializes BSS, and calls main().
 */

.section .text.init
.global _start
.type _start, @function

_start:
    # Set up stack pointer
    la sp, _stack_top
    
    # Clear BSS section
    la t0, _bss_start
    la t1, _bss_end
clear_bss:
    beq t0, t1, bss_done
    sw zero, 0(t0)
    addi t0, t0, 4
    j clear_bss

bss_done:
    # Call main function
    call main
    
    # If main returns, loop forever
hang:
    j hang

.size _start, . - _start

# Interrupt/exception handler (basic)
.global _irq_handler
.type _irq_handler, @function
_irq_handler:
    # Save context (simplified - only save what we use)
    addi sp, sp, -16
    sw ra, 0(sp)
    sw t0, 4(sp)
    sw t1, 8(sp)
    sw t2, 12(sp)
    
    # Handle interrupt (placeholder)
    # TODO: Call C interrupt handler
    
    # Restore context
    lw ra, 0(sp)
    lw t0, 4(sp)
    lw t1, 8(sp)
    lw t2, 12(sp)
    addi sp, sp, 16
    
    # Return from interrupt
    mret

.size _irq_handler, . - _irq_handler

