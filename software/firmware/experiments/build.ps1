# Build Script for Research Experiments

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("config", "crypto", "all")]
    [string]$Experiment
)

$ErrorActionPreference = "Stop"

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

# Experiments
$EXPERIMENTS = @{
    "config" = "config_optimization.c"
    "crypto" = "crypto_validation.c"
}

function Build-Experiment {
    param([string]$Name, [string]$SourceFile)
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Building Experiment: $Name" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Compile
    $sources = @($SourceFile) + $COMMON_SRC
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

# Main
Write-Host "========================================" -ForegroundColor Green
Write-Host "RISC-V Experiment Build System" -ForegroundColor Green
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

# Build
if ($Experiment -eq "all") {
    $success_count = 0
    foreach ($key in $EXPERIMENTS.Keys) {
        if (Build-Experiment $key $EXPERIMENTS[$key]) {
            $success_count++
        }
    }
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "Build Complete: $success_count/$($EXPERIMENTS.Count) experiments built" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    $sourceFile = $EXPERIMENTS[$Experiment]
    if (Build-Experiment $Experiment $sourceFile) {
        Write-Host "`n[OK] Build successful!" -ForegroundColor Green
    } else {
        Write-Host "`n[FAIL] Build failed!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nNext step: Use ../../../generate_firmware_init.ps1 to integrate firmware" -ForegroundColor Yellow
Write-Host "Then rebuild FPGA bitstream with new experiment" -ForegroundColor Yellow

