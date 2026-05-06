Write-Host "=== Playwright Portable Environment Installer ==="
Write-Host ""

# --- Summary ---
Write-Host "This launcher will run the following steps:"
Write-Host "  1. Install portable Node.js (pw-01a-install-node.ps1)"
Write-Host "  2. Install Playwright + Chromium (pw-01b-install-playwright.ps1)"
Write-Host "  3. Verify environment (pw-03-install-verify.ps1)"
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
    exit
}

Write-Host ""
Write-Host "=== STEP 1: Installing Node.js ==="
powershell -ExecutionPolicy Bypass -File ".\pw-01a-install-node.ps1"
Write-Host ""

Write-Host "=== STEP 2: Installing Playwright ==="
powershell -ExecutionPolicy Bypass -File ".\pw-01b-install-playwright.ps1"
Write-Host ""

Write-Host "=== STEP 3: Verifying Environment ==="
powershell -ExecutionPolicy Bypass -File ".\pw-03-verify-install.ps1"
Write-Host ""

Write-Host "=== STEP 4: Running Test Harness ==="
powershell -ExecutionPolicy Bypass -File ".\pw-04-run-test.ps1"
Write-Host ""

Write-Host "=== INSTALLATION + TEST COMPLETE ==="
Write-Host "Your portable Playwright environment is ready."
Write-Host ""
