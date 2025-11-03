# Setup RISC-V Toolchain Environment for PowerShell
# Run this before compiling firmware: .\setup_env.ps1

$TOOLCHAIN_DIR = "$PSScriptRoot\riscv-toolchain"
$TOOLCHAIN_BIN = "$TOOLCHAIN_DIR\bin"

# Add to PATH
$env:PATH = "$TOOLCHAIN_BIN;$env:PATH"
$env:RISCV = $TOOLCHAIN_DIR

Write-Host "========================================" -ForegroundColor Green
Write-Host "RISC-V Toolchain Environment Configured" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "GCC Version:" -ForegroundColor Cyan
& riscv-none-elf-gcc --version | Select-Object -First 1
Write-Host ""
Write-Host "Toolchain Path: $TOOLCHAIN_BIN" -ForegroundColor Yellow
Write-Host ""
Write-Host "Ready to compile firmware!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

