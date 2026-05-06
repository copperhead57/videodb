param(
    [string]$target = "$PSScriptRoot"
)

Write-Host "=== Portable Node Uninstaller ==="
Write-Host ""
Write-Host "This script will remove ONLY the portable Node.js runtime:"
Write-Host "  • node.exe"
Write-Host "  • npm.cmd"
Write-Host "  • npx.cmd"
Write-Host ""
Write-Host "It will NOT remove:"
Write-Host "  • package-lock.json"
Write-Host "  • node_modules"
Write-Host "  • Playwright"
Write-Host "  • Browsers"
Write-Host "  • chrome-profile"
Write-Host ""
Write-Host "Target folder:"
Write-Host "  $target"
Write-Host ""

# --- Confirm ---
Write-Host "Press Y to uninstall portable Node.js or any other key to cancel..." -NoNewline
$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
$char = [string]$key.Character
Write-Host ""

if ($char.ToUpper() -ne 'Y') {
    Write-Host "Cancelled by user."
    exit
}

Set-Location $target

function RemoveSafe($label, $path) {
    if (Test-Path $path) {
        Remove-Item $path -Force -ErrorAction SilentlyContinue
        Write-Host "[REMOVED] $label"
    } else {
        Write-Host "[SKIP]    $label (not found)"
    }
}

Write-Host ""
Write-Host "=== Removing Node runtime files ==="

RemoveSafe "node.exe" ".\node.exe"
RemoveSafe "npm.cmd" ".\npm.cmd"
RemoveSafe "npx.cmd" ".\npx.cmd"

Write-Host ""
Write-Host "=== Node Uninstall Complete ==="
Write-Host "Portable Node.js runtime has been removed."
Write-Host ""
