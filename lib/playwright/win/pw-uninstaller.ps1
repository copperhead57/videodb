Write-Host "=== Playwright Portable Environment Uninstaller ==="
Write-Host ""
Write-Host "This launcher will run the following steps:"
Write-Host "  1. Uninstall portable Node.js (pw-11-uninstall-node.ps1)"
Write-Host "  2. Uninstall Playwright + browsers (pw-12-uninstall-playwright.ps1)"
Write-Host "  3. Verify uninstall (pw-13-verify-uninstall.ps1)"
Write-Host ""
Write-Host "Press Y to begin uninstall or any other key to cancel..." -NoNewline

$key  = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
$char = [string]$key.Character
Write-Host ""

if ($char.ToUpper() -ne 'Y') {
    Write-Host "Cancelled by user."
    exit
}

# ---------------------------------------------------------
# Resolve install-utils folder ONCE (no repetition)
# ---------------------------------------------------------
$utils = Join-Path $PSScriptRoot "install-utils"

# ---------------------------------------------------------
# STEP 1 — Uninstall Node
# ---------------------------------------------------------
Write-Host ""
Write-Host "=== STEP 1: Uninstalling Node.js ==="
pwsh -ExecutionPolicy Bypass -File (Join-Path $utils "pw-11-uninstall-node.ps1")

# ---------------------------------------------------------
# STEP 2 — Uninstall Playwright
# ---------------------------------------------------------
Write-Host ""
Write-Host "=== STEP 2: Uninstalling Playwright ==="
pwsh -ExecutionPolicy Bypass -File (Join-Path $utils "pw-12-uninstall-playwright.ps1")

# ---------------------------------------------------------
# STEP 3 — Verify Uninstall
# ---------------------------------------------------------
Write-Host ""
Write-Host "=== STEP 3: Verifying Uninstall ==="
pwsh -ExecutionPolicy Bypass -File (Join-Path $utils "pw-13-verify-uninstall.ps1")

Write-Host ""
Write-Host "=== UNINSTALL COMPLETE ==="
Write-Host "Your portable Playwright environment has been fully removed."
Write-Host ""
