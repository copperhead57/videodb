Write-Host "=== Playwright Portable Environment Installer ==="
Write-Host ""

# --- Summary ---
Write-Host "This launcher will run the following steps:"
Write-Host "  1. Install portable Node.js (pw-01-install-node.ps1)"
Write-Host "  2. Install Playwright + Chromium (pw-02-install-playwright.ps1)"
Write-Host "  3. Verify environment (pw-03-verify-install.ps1)"
Write-Host "  4. Run test harness (pw-04-run-test.ps1)"
Write-Host ""
Write-Host "No system changes will be made:"
Write-Host "  • No PATH edits"
Write-Host "  • No registry writes"
Write-Host "  • No admin rights required"
Write-Host ""

# --- Confirm ---
Write-Host "Press Y to begin installation or any other key to cancel..." -NoNewline
$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
$char = [string]$key.Character
Write-Host ""

if ($char.ToUpper() -ne 'Y') {
    Write-Host "Cancelled by user."
    exit 1
}

# ----------------------------------------
# Load config (single source of truth)
# ----------------------------------------
$root  = Split-Path -Parent $MyInvocation.MyCommand.Path
$utils = Join-Path $root "install-utils"
$config = Join-Path $utils "config.ps1"

if (!(Test-Path $config)) {
    Write-Host "ERROR: Missing config.ps1 at: $config" -ForegroundColor Red
    exit 1
}

. $config   # loads: $root, $nodeRT, $pwRoot, $nodeExe, $npmCmd, etc.

# ----------------------------------------
# Helper to run each step
# ----------------------------------------
function Run-Step($label, $script) {
    Write-Host ""
    Write-Host "=== $label ==="

    $full = Join-Path $utils $script

    if (!(Test-Path $full)) {
        Write-Host "ERROR: Script not found: $full" -ForegroundColor Red
        exit 1
    }

    powershell -ExecutionPolicy Bypass -File $full
    $code = $LASTEXITCODE

    if ($code -ne 0 -and $code -ne 10 -and $code -ne 11) {
        Write-Host ""
        Write-Host "ABORTED: $label failed or was cancelled." -ForegroundColor Red
        exit $code
    }
}

# ----------------------------------------
# STEP 1 — Install Node.js
# ----------------------------------------
Run-Step "STEP 1: Installing Node.js" "pw-01-install-node.ps1"
$nodeResult = $LASTEXITCODE

if ($nodeResult -eq 10 -or $nodeResult -eq 11) {
    Write-Host "Node changed — removing Playwright runtime..." -ForegroundColor Yellow
    & "$PSScriptRoot\install-utils\pw-remove-runtime.ps1" -pwRoot $pwRoot
}

# ----------------------------------------
# STEP 2 — Install Playwright
# ----------------------------------------
Run-Step "STEP 2: Installing Playwright" "pw-02-install-playwright.ps1"

# ----------------------------------------
# STEP 3 — Verify environment
# ----------------------------------------
Run-Step "STEP 3: Verifying Environment" "pw-03-verify-install.ps1"

# ----------------------------------------
# STEP 4 — Run test harness
# ----------------------------------------
Run-Step "STEP 4: Running Test Harness" "pw-04-run-test.ps1"

Write-Host ""
Write-Host "=== INSTALLATION + TEST COMPLETE ==="
Write-Host "Your portable Playwright environment is ready."
Write-Host ""
