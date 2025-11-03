#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick demo script - Run your first ETS research test NOW!
    
.DESCRIPTION
    This script runs the complete research test suite in one command.
    Perfect for first-time testing and demonstrations.
#>

$ErrorActionPreference = "Stop"

Write-Host @"

╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   🔬 ETS RISC-V RESEARCH SYSTEM - QUICK DEMO                    ║
║                                                                  ║
║   This will run the complete research test suite:               ║
║   • 7 comprehensive tests                                       ║
║   • Automatic execution                                         ║
║   • LED-based results                                           ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

Write-Host "⏱️  Estimated time: 5-10 minutes (FPGA build)" -ForegroundColor Yellow
Write-Host "📍 Make sure your Zybo Z7-10 board is connected!`n" -ForegroundColor Yellow

# Prompt user
$response = Read-Host "Ready to start? (Y/N)"

if ($response -ne "Y" -and $response -ne "y") {
    Write-Host "`n❌ Demo cancelled. Run this script again when ready!" -ForegroundColor Red
    exit 0
}

Write-Host "`n🚀 Starting demo...`n" -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "tools\run_research_test.ps1")) {
    Write-Host "❌ Error: Run this script from the project root directory!" -ForegroundColor Red
    Write-Host "   Expected: C:\Users\omdag\OneDrive\Desktop\time_bound_processor" -ForegroundColor Yellow
    exit 1
}

# Run the research test
try {
    & .\tools\run_research_test.ps1 -TestType research
    
    Write-Host @"

╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   ✅ DEMO COMPLETE!                                             ║
║                                                                  ║
║   Your ETS RISC-V processor is now running research tests!      ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

    Write-Host "👀 OBSERVE THE LEDs ON YOUR BOARD:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   LED Pattern      | Meaning" -ForegroundColor Yellow
    Write-Host "   -----------------+------------------------" -ForegroundColor Yellow
    Write-Host "   0x1 (LED0)       | Test 1 - Timing Accuracy"
    Write-Host "   0x2 (LED1)       | Test 2 - False Positives"
    Write-Host "   0x4 (LED2)       | Test 3 - Attack Detection"
    Write-Host "   0x5 (LED0+2)     | Test 4 - Performance"
    Write-Host "   0x6 (LED1+2)     | Test 5 - Crypto"
    Write-Host "   0x7 (LED0+1+2)   | Test 6 - Learning"
    Write-Host "   0x8 (LED3)       | Test 7 - Stress Test"
    Write-Host ""
    Write-Host "   After all tests complete:" -ForegroundColor Cyan
    Write-Host "   • COUNT THE BLINKS = Number of passed tests"
    Write-Host "   • FINAL LED PATTERN = Overall grade"
    Write-Host "     - 0x1 = Excellent (>90%)"
    Write-Host "     - 0x3 = Good (70-90%)"
    Write-Host "     - 0x7 = Fair (50-70%)"
    Write-Host "     - 0xF = Poor (<50%)"
    Write-Host ""
    
    Write-Host "📚 NEXT STEPS:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   1. Read RESEARCH_READY.md for complete guide"
    Write-Host "   2. Try interactive mode:"
    Write-Host "      .\tools\run_research_test.ps1 -TestType interactive"
    Write-Host "   3. Review docs\QUICK_REFERENCE.md for all commands"
    Write-Host "   4. Explore docs\EXPERIMENTATION_GUIDE.md for experiments"
    Write-Host ""
    
    Write-Host "🎉 Congratulations! Your research system is operational!" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host "`n❌ Demo failed: $_" -ForegroundColor Red
    Write-Host "`nCheck the error above and refer to docs/QUICK_REFERENCE.md" -ForegroundColor Yellow
    exit 1
}

