/**
 * linker.ld
 * 
 * Linker script for RISC-V programs targeting PicoRV32 on Zybo Z7-10.
 * Memory layout:
 *   - 0x00000000: Instruction/Data RAM (16 KB)
 *   - 0x80000000: ETS registers
 *   - 0x90000000: GPIO/peripherals (future)
 */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 16K
}

SECTIONS
{
    . = 0x00000000;
    
    /* Code section */
    .text : {
        *(.text.init)      /* Startup code */
        *(.text*)          /* All code */
        . = ALIGN(4);
    } > RAM
    
    /* Read-only data */
    .rodata : {
        *(.rodata*)
        . = ALIGN(4);
    } > RAM
    
    /* Data section */
    .data : {
        _data_start = .;
        *(.data*)
        . = ALIGN(4);
        _data_end = .;
    } > RAM
    
    /* BSS section (uninitialized data) */
    .bss : {
        _bss_start = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
    } > RAM
    
    /* Stack (grows downward from end of RAM) */
    . = ORIGIN(RAM) + LENGTH(RAM);
    _stack_top = .;
    
    /* Heap (if needed) */
    _heap_start = _bss_end;
    _heap_end = _stack_top - 0x400;  /* Reserve 1KB for stack */
    
    /* Discard exception handling info */
    /DISCARD/ : {
        *(.eh_frame*)
        *(.comment)
    }
}

