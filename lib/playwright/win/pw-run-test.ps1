# ============================================
# Playwright Portable Environment - Test Launcher
# ============================================

# Enable ANSI escape sequences in this PowerShell session
#$env:TERM = "xterm"

$ErrorActionPreference = "Stop"

Write-Host "=== Playwright Portable Test Launcher ==="
Write-Host ""

# ---------------------------------------------------------
# Load config (defines $nodeRoot, $pwRoot, etc.)
# ---------------------------------------------------------
. "$PSScriptRoot\install-utils\config.ps1"

# ---------------------------------------------------------
# Test script path
# ---------------------------------------------------------
$testScript = Join-Path $utils "pw-04-run-test.ps1"

if (!(Test-Path $testScript)) {
    Write-Host "[ERROR] Test script not found:"
    Write-Host "        $testScript" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------
# Optional URL argument passthrough
# ---------------------------------------------------------
$url = "https://www.imdb.com/title/tt0133093/"

Write-Host "Running test script..."
Write-Host "URL: $url"
Write-Host ""

# ---------------------------------------------------------
# Execute test script
# ---------------------------------------------------------
#powershell -ExecutionPolicy Bypass -File $testScript -url $url
pwsh -ExecutionPolicy Bypass -File $testScript -url $url


$exitCode = $LASTEXITCODE

Write-Host ""
Write-Host "Test exit code: $exitCode"

# ---------------------------------------------------------
# Result handling
# ---------------------------------------------------------
if ($exitCode -ne 0) {
    Write-Host ""
    Write-Host "=== TEST FAILED ===" -ForegroundColor Red
    Write-Host "The Playwright test encountered an error."
    exit $exitCode
}

Write-Host ""
Write-Host "=== TEST SUCCESSFUL ===" -ForegroundColor Green
Write-Host "The Playwright test completed without errors."
Write-Host ""

exit 0
