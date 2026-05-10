# ============================================
# Playwright Portable Environment - Verify Launcher
# ============================================

$ErrorActionPreference = "Stop"

Write-Host "=== Playwright Portable Environment Verification ==="
Write-Host ""

# ---------------------------------------------------------
# Load config (defines $nodeRoot, $pwRoot, etc.)
# ---------------------------------------------------------
. "$PSScriptRoot\install-utils\config.ps1"

# ---------------------------------------------------------
# Paths
# ---------------------------------------------------------
$verifyScript = Join-Path $utils "pw-03-verify-install.ps1"

if (!(Test-Path $verifyScript)) {
    Write-Host "[ERROR] Verification script not found:"
    Write-Host "        $verifyScript" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------
# Run verification
# ---------------------------------------------------------
Write-Host "Running verification script..."
Write-Host ""

powershell -ExecutionPolicy Bypass -File $verifyScript

$exitCode = $LASTEXITCODE

Write-Host ""
Write-Host "Verification exit code: $exitCode"

# ---------------------------------------------------------
# Result handling
# ---------------------------------------------------------
if ($exitCode -ne 0) {
    Write-Host ""
    Write-Host "=== VERIFICATION FAILED ===" -ForegroundColor Red
    Write-Host "One or more components are missing or invalid."
    Write-Host "Please run the installer to repair the environment."
    exit $exitCode
}

Write-Host ""
Write-Host "=== VERIFICATION SUCCESSFUL ===" -ForegroundColor Green
Write-Host "Your portable Playwright environment is valid."
Write-Host ""

exit 0
