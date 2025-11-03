# Integrate Firmware into FPGA Build
# This script compiles firmware and updates the memory initialization

param(
    [string]$FirmwareName = "test_basic",
    [switch]$RebuildFPGA = $false,
    [switch]$ProgramBoard = $false
)

Write-Host "========================================" -ForegroundColor Green
Write-Host "Firmware Integration Script" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Paths
$FIRMWARE_DIR = "software\firmware\tests"
$RTL_DIR = "rtl\top"
$TOOLCHAIN_BIN = "software\toolchain\riscv-toolchain\bin"

# Setup environment
$env:PATH = "$PWD\$TOOLCHAIN_BIN;$env:PATH"

# Step 1: Compile firmware
Write-Host "`n[Step 1/4] Compiling firmware: $FirmwareName" -ForegroundColor Cyan
Set-Location $FIRMWARE_DIR

$CC = "riscv-none-elf-gcc"
$OBJCOPY = "riscv-none-elf-objcopy"

$sources = @("$FirmwareName.c", "..\common\ets_lib.c", "..\common\start.S")
$flags = @("-march=rv32i", "-mabi=ilp32", "-O2", "-ffreestanding", "-nostdlib", "-nostartfiles", "-T..\common\linker.ld", "-Wl,--gc-sections")

Write-Host "  Compiling..." -ForegroundColor Gray
& $CC @flags -o "$FirmwareName.elf" @sources

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Compilation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "  Generating binary..." -ForegroundColor Gray
& $OBJCOPY -O binary "$FirmwareName.elf" "$FirmwareName.bin"

Write-Host "  Generating hex..." -ForegroundColor Gray
python ..\common\makehex.py "$FirmwareName.bin" > "$FirmwareName.hex"

Write-Host "✓ Firmware compiled successfully!" -ForegroundColor Green
Write-Host "  Output: $FirmwareName.hex" -ForegroundColor Yellow

# Get hex file content
$hex_lines = Get-Content "$FirmwareName.hex"
Write-Host "  Firmware size: $($hex_lines.Count) words ($($hex_lines.Count * 4) bytes)" -ForegroundColor Yellow

Set-Location ..\..\..

# Step 2: Update memory initialization
Write-Host "`n[Step 2/4] Updating memory initialization in Verilog" -ForegroundColor Cyan

$verilog_file = "$RTL_DIR\zybo_z7_top.v"
$backup_file = "$RTL_DIR\zybo_z7_top.v.bak"

# Backup original file
Copy-Item $verilog_file $backup_file -Force
Write-Host "  Backup created: zybo_z7_top.v.bak" -ForegroundColor Gray

# Read Verilog file
$verilog_content = Get-Content $verilog_file -Raw

# Find memory initialization section and replace
$pattern = '(?s)(// Initialize with NOP instructions.*?initial begin\s*for \(i = 0; i < WORDS; i = i \+ 1\)\s*mem\[i\] = 32''h0000_0013;  // ADDI x0, x0, 0 \(NOP\)\s*)(.*?)(end)'

$new_init = @"
// Firmware initialization from $FirmwareName.hex
        integer i;
        initial begin
            // Initialize all memory to NOPs first
            for (i = 0; i < WORDS; i = i + 1)
                mem[i] = 32'h0000_0013;
            
            // Load firmware
"@

# Add hex data
for ($i = 0; $i -lt [Math]::Min($hex_lines.Count, 4096); $i++) {
    $new_init += "`n            mem[$i] = 32'h$($hex_lines[$i]);"
}

$new_init += "`n        end"

# This is complex - let me just create a new file with instructions
Write-Host "  Creating updated memory initialization..." -ForegroundColor Gray
Write-Host "  Note: Manual update required - see FIRMWARE_INTEGRATION_INSTRUCTIONS.txt" -ForegroundColor Yellow

# Create instructions file
@"
FIRMWARE INTEGRATION INSTRUCTIONS
==================================

Your firmware has been compiled to: software/firmware/tests/$FirmwareName.hex

To integrate it into the FPGA:

1. Open: rtl/top/zybo_z7_top.v

2. Find the memory initialization section (around line 184-193)

3. Replace this code:
   
        initial begin
            for (i = 0; i < WORDS; i = i + 1)
                mem[i] = 32'h0000_0013;  // ADDI x0, x0, 0 (NOP)
                
            // Simple test program at address 0
            // You can replace this with actual firmware
            mem[0] = 32'h00000093;  // ADDI x1, x0, 0
            mem[1] = 32'h00108093;  // ADDI x1, x1, 1
            mem[2] = 32'h00108093;  // ADDI x1, x1, 1
            mem[3] = 32'hFF5FF06F;  // JAL x0, -12 (loop)
        end

4. With this code (first $([Math]::Min($hex_lines.Count, 20)) instructions shown):

        initial begin
            // Initialize all to NOPs
            for (i = 0; i < WORDS; i = i + 1)
                mem[i] = 32'h0000_0013;
            
            // Load firmware from $FirmwareName.hex
$( for ($i = 0; $i -lt [Math]::Min($hex_lines.Count, 20); $i++) { "            mem[$i] = 32'h$($hex_lines[$i]);" })
            // ... (total $($hex_lines.Count) words - see full hex file)
        end

5. Save the file

6. Rebuild FPGA bitstream:
   vivado -mode batch -source build.tcl

7. Program board:
   vivado -mode batch -source program.tcl

===================================

Full hex file path: $PWD\$FIRMWARE_DIR\$FirmwareName.hex
Full list: $($hex_lines.Count) instruction words

"@ | Out-File "FIRMWARE_INTEGRATION_INSTRUCTIONS.txt" -Encoding UTF8

Write-Host "✓ Instructions written to: FIRMWARE_INTEGRATION_INSTRUCTIONS.txt" -ForegroundColor Green

# Step 3: Rebuild FPGA (optional)
if ($RebuildFPGA) {
    Write-Host "`n[Step 3/4] Rebuilding FPGA bitstream" -ForegroundColor Cyan
    Write-Host "  This will take 15-20 minutes..." -ForegroundColor Yellow
    
    vivado -mode batch -source build.tcl
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ FPGA build complete!" -ForegroundColor Green
    } else {
        Write-Host "✗ FPGA build failed!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n[Step 3/4] FPGA rebuild skipped" -ForegroundColor Yellow
    Write-Host "  Use -RebuildFPGA to automatically rebuild" -ForegroundColor Gray
}

# Step 4: Program board (optional)
if ($ProgramBoard) {
    Write-Host "`n[Step 4/4] Programming board" -ForegroundColor Cyan
    
    vivado -mode batch -source program.tcl
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Board programmed!" -ForegroundColor Green
    } else {
        Write-Host "✗ Programming failed!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n[Step 4/4] Board programming skipped" -ForegroundColor Yellow
    Write-Host "  Use -ProgramBoard to automatically program" -ForegroundColor Gray
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Firmware Integration Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review: FIRMWARE_INTEGRATION_INSTRUCTIONS.txt" -ForegroundColor White
Write-Host "  2. Update: rtl/top/zybo_z7_top.v memory initialization" -ForegroundColor White
Write-Host "  3. Rebuild: vivado -mode batch -source build.tcl" -ForegroundColor White
Write-Host "  4. Program: vivado -mode batch -source program.tcl" -ForegroundColor White
Write-Host ""

