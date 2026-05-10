Write-Host "=== Playwright Portable Environment Uninstaller ==="
Write-Host ""
Write-Host "This launcher will run the following steps:"
Write-Host "  1. Uninstall portable Node.js (pw-02a-uninstall-node.ps1)"
Write-Host "  2. Uninstall Playwright + browsers (pw-02b-uninstall-playwright.ps1)"
Write-Host "  3. Verify uninstall (pw-03b-verify-uninstall.ps1)"
Write-Host ""
Write-Host "It will NOT remove:"
Write-Host "  • Any of your scripts"
Write-Host "  • pw-01 installers"
Write-Host "  • pw-04 test harness"
Write-Host ""
Write-Host "Press Y to begin uninstall or any other key to cancel..." -NoNewline

$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
$char = [string]$key.Character
Write-Host ""

if ($char.ToUpper() -ne 'Y') {
    Write-Host "Cancelled by user."
    exit
}

Write-Host ""
Write-Host "=== STEP 1: Uninstalling Node.js ==="
powershell -ExecutionPolicy Bypass -File ".\pw-02a-uninstall-node.ps1"
Write-Host ""

Write-Host "=== STEP 2: Uninstalling Playwright ==="
powershell -ExecutionPolicy Bypass -File ".\pw-02b-uninstall-playwright.ps1"
Write-Host ""

Write-Host "=== STEP 3: Verifying Uninstall ==="
powershell -ExecutionPolicy Bypass -File ".\pw-03-verify-uninstall.ps1"
Write-Host ""

Write-Host "=== UNINSTALL COMPLETE ==="
Write-Host "Your portable Playwright environment has been fully removed."
Write-Host ""
