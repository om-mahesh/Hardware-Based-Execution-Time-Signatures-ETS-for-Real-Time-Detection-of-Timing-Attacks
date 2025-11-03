# Makefile for ETS Test Programs
# Compiles C programs for RISC-V (PicoRV32)

# Toolchain
CROSS_COMPILE = riscv-none-elf-
CC = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
SIZE = $(CROSS_COMPILE)size

# Architecture flags
ARCH_FLAGS = -march=rv32i -mabi=ilp32 -mstrict-align

# Compiler flags
CFLAGS = $(ARCH_FLAGS) -O2 -g -Wall -Wextra
CFLAGS += -ffreestanding -nostdlib -nostartfiles
CFLAGS += -I../common

# Linker flags
LDFLAGS = $(ARCH_FLAGS) -T../common/linker.ld
LDFLAGS += -Wl,--gc-sections -Wl,-Map=$@.map

# Common sources
COMMON_SRC = ../common/ets_lib.c ../common/start.S

# Test programs
TESTS = test_basic test_anomaly test_learning

# Default target
all: $(TESTS)

# Pattern rule for building test programs
%: %.c $(COMMON_SRC)
	@echo "Building $@..."
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@.elf $< $(COMMON_SRC)
	$(OBJCOPY) -O binary $@.elf $@.bin
	$(OBJDUMP) -d $@.elf > $@.asm
	$(SIZE) $@.elf
	@echo "Generating Verilog hex file..."
	python3 ../common/makehex.py $@.bin > $@.hex
	@echo "Done: $@.hex"
	@echo ""

# Clean
clean:
	rm -f *.elf *.bin *.hex *.asm *.map

# Print toolchain info
info:
	@echo "Toolchain: $(CC)"
	@$(CC) --version
	@echo ""
	@echo "CFLAGS: $(CFLAGS)"
	@echo "LDFLAGS: $(LDFLAGS)"

.PHONY: all clean info

