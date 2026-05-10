# ============================================
# pw-12-uninstall-playwright.ps1
# Portable Playwright Uninstaller (Windows)
# ============================================

# Load shared config (defines $root, $pwRoot, $utils, etc.)
. "$PSScriptRoot\config.ps1"

# Persistent browser profile folder
$profileDir = Join-Path $root "chrome-profile"

Write-Host "=== Playwright Uninstaller ==="
Write-Host ""
Write-Host "This script will remove the Playwright environment:"
Write-Host "  • $pwRoot\node_modules"
Write-Host "  • $pwRoot\package-lock.json"
Write-Host "  • $profileDir"
Write-Host ""
Write-Host "Press Y to uninstall Playwright or any other key to cancel..." -NoNewline

$key  = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
$char = [string]$key.Character
Write-Host ""

if ($char.ToUpper() -ne 'Y') {
    Write-Host "Cancelled by user."
    exit
}

function RemoveFolder($label, $path) {
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[REMOVED] $label"
    } else {
        Write-Host "[SKIP]    $label (not found)"
    }
}

function RemoveFile($label, $path) {
    if (Test-Path $path) {
        Remove-Item $path -Force -ErrorAction SilentlyContinue
        Write-Host "[REMOVED] $label"
    } else {
        Write-Host "[SKIP]    $label (not found)"
    }
}

Write-Host ""
Write-Host "=== Removing Playwright environment ==="

# Remove ONLY Playwright’s node_modules
RemoveFolder "Playwright node_modules" (Join-Path $pwRoot "node_modules")

# Remove ONLY Playwright’s package-lock.json
RemoveFile "Playwright package-lock.json" (Join-Path $pwRoot "package-lock.json")

# Remove persistent browser profile
RemoveFolder "Chrome profile" $profileDir

Write-Host ""
Write-Host "=== Playwright Uninstall Complete ==="
Write-Host "Portable Playwright environment has been removed."
Write-Host ""
