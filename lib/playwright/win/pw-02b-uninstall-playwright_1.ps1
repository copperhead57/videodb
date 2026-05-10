param(
    [string]$target = "$PSScriptRoot"
)

Write-Host "=== Playwright Uninstaller ==="
Write-Host ""
Write-Host "This script will remove ONLY the Playwright environment:"
Write-Host "  • node_modules (entire Folder)"
Write-Host "  • chrome-profile (dir)"
Write-Host "  • package-lock.json"
Write-Host ""
Write-Host "It will NOT remove:"
Write-Host "  • node.exe"
Write-Host "  • npm.cmd"
Write-Host "  • npx.cmd"
Write-Host ""
Write-Host "Target folder:"
Write-Host "  $target"
Write-Host ""

# --- Confirm ---
Write-Host "Press Y to uninstall Playwright or any other key to cancel..." -NoNewline
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
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[REMOVED] $label"
    } else {
        Write-Host "[SKIP]    $label (not found)"
    }
}

Write-Host ""
Write-Host "=== Removing Playwright files ==="

RemoveSafe "node_modules      " ".\node_modules"
RemoveSafe "Chrome profile    " ".\chrome-profile"
RemoveSafe "package-lock.json " ".\package-lock.json"

Write-Host ""
Write-Host "=== Playwright Uninstall Complete ==="
Write-Host "Portable Playwright environment has been removed."
Write-Host ""
