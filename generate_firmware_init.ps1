# Generate firmware_init.vh from hex file

param(
    [Parameter(Mandatory=$true)]
    [string]$hexFile
)

$ErrorActionPreference = "Stop"

Write-Host "Generating firmware initialization from: $hexFile" -ForegroundColor Cyan

if (-not (Test-Path $hexFile)) {
    Write-Host "Error: Hex file not found: $hexFile" -ForegroundColor Red
    exit 1
}

# Read hex file
$hexLines = Get-Content $hexFile

# Generate Verilog initialization
$output = "// Auto-generated from $hexFile`n"
$output += "// Generated: $(Get-Date)`n`n"

$address = 0
foreach ($line in $hexLines) {
    $line = $line.Trim()
    if ($line -and $line -ne "") {
        $output += "mem[$address] = 32'h$line;`n"
        $address++
    }
}

# Write to rtl/top/firmware_init.vh
$outputFile = "rtl\top\firmware_init.vh"
$output | Out-File -FilePath $outputFile -Encoding ASCII

Write-Host "[OK] Generated $outputFile with $address words" -ForegroundColor Green
Write-Host "     ($($address * 4) bytes)" -ForegroundColor Gray

