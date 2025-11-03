# Build Script for RISC-V Firmware (Windows PowerShell)
# Usage: .\build.ps1 [test_name]

param(
    [string]$TestName = "all"
)

# Setup environment
$TOOLCHAIN_DIR = "..\..\toolchain\riscv-toolchain"
$env:PATH = "$TOOLCHAIN_DIR\bin;$env:PATH"

# Toolchain binaries
$CC = "riscv-none-elf-gcc"
$OBJCOPY = "riscv-none-elf-objcopy"
$OBJDUMP = "riscv-none-elf-objdump"
$SIZE = "riscv-none-elf-size"

# Compiler flags
$ARCH_FLAGS = "-march=rv32i", "-mabi=ilp32"
$CFLAGS = $ARCH_FLAGS + @("-O2", "-g", "-Wall", "-Wextra", "-ffreestanding", "-nostdlib", "-nostartfiles")
$LDFLAGS = $ARCH_FLAGS + @("-T..\common\linker.ld", "-Wl,--gc-sections")

# Common sources
$COMMON_SRC = @("..\common\ets_lib.c", "..\common\uart.c", "..\common\start.S")

# Test programs
$TESTS = @("test_basic", "test_anomaly", "test_learning", "interactive_interface", "research_tests_simple", "research_uart")

function Build-Program {
    param([string]$Name)
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Building $Name..." -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Compile
    $sources = @("$Name.c") + $COMMON_SRC
    $cmd = @($CC) + $CFLAGS + $LDFLAGS + @("-o", "$Name.elf") + $sources
    
    Write-Host "Command: $($cmd -join ' ')" -ForegroundColor Gray
    & $cmd[0] $cmd[1..($cmd.Length-1)]
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Compilation failed for $Name" -ForegroundColor Red
        return $false
    }
    
    # Generate binary
    & $OBJCOPY -O binary "$Name.elf" "$Name.bin"
    
    # Generate assembly listing
    & $OBJDUMP -d "$Name.elf" > "$Name.asm"
    
    # Show size
    Write-Host "`nProgram size:" -ForegroundColor Yellow
    & $SIZE "$Name.elf"
    
    # Generate hex file for Verilog
    Write-Host "`nGenerating Verilog hex file..." -ForegroundColor Yellow
    python ..\common\makehex.py "$Name.bin" > "$Name.hex"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Success: $Name.hex generated!" -ForegroundColor Green
        Write-Host "  - ELF: $Name.elf" -ForegroundColor Gray
        Write-Host "  - BIN: $Name.bin" -ForegroundColor Gray
        Write-Host "  - HEX: $Name.hex" -ForegroundColor Gray
        Write-Host "  - ASM: $Name.asm" -ForegroundColor Gray
        return $true
    } else {
        Write-Host "ERROR: Hex generation failed" -ForegroundColor Red
        return $false
    }
}

# Main build logic
Write-Host "========================================" -ForegroundColor Green
Write-Host "RISC-V Firmware Build System" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Check toolchain
try {
    $version = & $CC --version 2>&1 | Select-Object -First 1
    Write-Host "Toolchain: $version" -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: RISC-V GCC not found!" -ForegroundColor Red
    Write-Host "Run: cd ..\..\toolchain; .\setup_env.ps1" -ForegroundColor Yellow
    exit 1
}

# Map shortcuts to full test names
$TEST_MAP = @{
    "basic"       = "test_basic"
    "anomaly"     = "test_anomaly"
    "learning"    = "test_learning"
    "interactive" = "interactive_interface"
    "research"    = "research_tests_simple"
    "uart"        = "research_uart"
}

# Resolve test name
$ResolvedName = $TestName
if ($TEST_MAP.ContainsKey($TestName)) {
    $ResolvedName = $TEST_MAP[$TestName]
    Write-Host "Mapping '$TestName' -> '$ResolvedName'" -ForegroundColor Cyan
}

# Build
if ($TestName -eq "all") {
    $success_count = 0
    foreach ($test in $TESTS) {
        if (Build-Program $test) {
            $success_count++
        }
    }
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "Build Complete: $success_count/$($TESTS.Length) programs built" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    if (Build-Program $ResolvedName) {
        Write-Host "`n[OK] Build successful!" -ForegroundColor Green
    } else {
        Write-Host "`n[FAIL] Build failed!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nNext step: Copy .hex file to memory initialization in Verilog" -ForegroundColor Yellow
Write-Host "Then rebuild FPGA bitstream with new firmware" -ForegroundColor Yellow

