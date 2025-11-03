#!/usr/bin/env pwsh
# Automated research test runner for ETS RISC-V system

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("interactive", "research", "basic", "anomaly", "learning")]
    [string]$TestType,
    
    [switch]$SkipBuild,
    [switch]$CleanBuild
)

$ErrorActionPreference = "Stop"

$ProjectRoot = "C:\Users\omdag\OneDrive\Desktop\time_bound_processor"
$VivadoPath = "vivado"

function Write-Header($message) {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  $message" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
}

function Write-Step($step, $message) {
    Write-Host "[$step]" -ForegroundColor Yellow -NoNewline
    Write-Host " $message"
}

function Write-Success($message) {
    Write-Host "[OK] $message" -ForegroundColor Green
}

function Write-Fail($message) {
    Write-Host "[FAIL] $message" -ForegroundColor Red
}

function Write-Info($message) {
    Write-Host "[INFO] $message" -ForegroundColor Blue
}

try {
    Write-Header "ETS RISC-V Research Test Runner"
    
    Set-Location $ProjectRoot
    Write-Info "Working directory: $ProjectRoot"
    
    # ========== Step 1: Compile Firmware ==========
    
    Write-Step "1/5" "Compiling firmware ($TestType)..."
    
    Set-Location "software\firmware\tests"
    
    # Map test types to source files and hex files
    $testMapping = @{
        "interactive" = @{ source = "interactive_interface.c"; hex = "interactive_interface.hex" }
        "research"    = @{ source = "research_tests_simple.c"; hex = "research_tests_simple.hex" }
        "basic"       = @{ source = "test_basic.c"; hex = "test_basic.hex" }
        "anomaly"     = @{ source = "test_anomaly.c"; hex = "test_anomaly.hex" }
        "learning"    = @{ source = "test_learning.c"; hex = "test_learning.hex" }
    }
    
    $firmwareFile = $testMapping[$TestType].source
    $hexFile = $testMapping[$TestType].hex
    
    Write-Info "Compiling: $firmwareFile"
    
    # Run build script
    & .\build.ps1 $TestType
    
    if ($LASTEXITCODE -ne 0) {
        throw "Firmware compilation failed"
    }
    
    Write-Success "Firmware compiled successfully"
    
    # Check if hex file exists
    if (-not (Test-Path $hexFile)) {
        throw "Hex file not found: $hexFile"
    }
    
    Write-Info "Hex file: $hexFile"
    
    # ========== Step 2: Generate Firmware Init ==========
    
    Write-Step "2/5" "Generating firmware initialization..."
    
    Set-Location $ProjectRoot
    
    & .\generate_firmware_init.ps1 -hexFile "software\firmware\tests\$hexFile"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Firmware init generation failed"
    }
    
    Write-Success "Firmware initialization generated"
    
    # ========== Step 3: Build FPGA Bitstream ==========
    
    if ($CleanBuild) {
        Write-Step "3/5" "Cleaning previous build..."
        Remove-Item -Recurse -Force "vivado_project" -ErrorAction SilentlyContinue
        Write-Success "Build artifacts cleaned"
    }
    
    if (-not $SkipBuild) {
        Write-Step "3/5" "Building FPGA bitstream..."
        Write-Info "This may take 5-10 minutes..."
        
        & $VivadoPath -mode batch -source build.tcl 2>&1 | Tee-Object -FilePath "build_$TestType_log.txt"
        
        if ($LASTEXITCODE -ne 0) {
            throw "FPGA build failed. Check build_$TestType_log.txt"
        }
        
        Write-Success "Bitstream built successfully"
    } else {
        Write-Step "3/5" "Skipping FPGA build (using existing bitstream)..."
        Write-Info "Ensure bitstream is up-to-date!"
    }
    
    # ========== Step 4: Check Board Connection ==========
    
    Write-Step "4/5" "Checking board connection..."
    
    $hwCheck = & $VivadoPath -mode batch -source program.tcl 2>&1 | Select-String "xc7z010"
    
    if (-not $hwCheck) {
        Write-Fail "Board not detected. Please check:"
        Write-Host "  1. Board is powered on"
        Write-Host "  2. USB cable is connected"
        Write-Host "  3. Drivers are installed"
        throw "Board connection check failed"
    }
    
    Write-Success "Board detected"
    
    # ========== Step 5: Program Board ==========
    
    Write-Step "5/5" "Programming board..."
    
    & $VivadoPath -mode batch -source program.tcl 2>&1 | Tee-Object -FilePath "program_$TestType_log.txt"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Board programming failed. Check program_$TestType_log.txt"
    }
    
    Write-Success "Board programmed successfully"
    
    # ========== Complete ==========
    
    Write-Header "TEST READY!"
    
    Write-Host "Test Type: $TestType" -ForegroundColor Green
    Write-Host "Firmware:  $firmwareFile" -ForegroundColor Green
    
    Write-Host "`nWhat to do next:" -ForegroundColor Yellow
    
    switch ($TestType) {
        "interactive" {
            Write-Host "  - Use switches and buttons on the board to interact"
            Write-Host "  - Watch LED patterns for feedback"
            Write-Host "  - Refer to docs\RESEARCH_TESTING_GUIDE.md for LED codes"
        }
        "research" {
            Write-Host "  - Tests are running automatically"
            Write-Host "  - Watch LEDs for test progress (1-7)"
            Write-Host "  - Count final blinks for number of passed tests"
            Write-Host "  - Final LED pattern shows overall grade"
        }
        "basic" {
            Write-Host "  - Basic functionality test"
            Write-Host "  - LEDs show ETS status"
            Write-Host "  - Should see heartbeat pattern"
        }
        "anomaly" {
            Write-Host "  - Anomaly detection test"
            Write-Host "  - LEDs will show alerts when anomalies detected"
        }
        "learning" {
            Write-Host "  - Learning mode test"
            Write-Host "  - System will auto-learn instruction timings"
        }
    }
    
    Write-Host "`nDocumentation:" -ForegroundColor Yellow
    Write-Host "  - Research Guide: docs\RESEARCH_TESTING_GUIDE.md"
    Write-Host "  - LED Codes: See guide for pattern meanings"
    Write-Host "  - Logs: build_$TestType" + "_log.txt, program_$TestType" + "_log.txt"
    
    Write-Host "`nAll done! The test is now running on your board.`n" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "Script failed: $_" -ForegroundColor Red
    Write-Host "`nPlease check the error message above and try again."
    Write-Host "For help, refer to docs\RESEARCH_TESTING_GUIDE.md"
    exit 1
}
