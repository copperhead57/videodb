# ============================================
# pw-11-uninstall-node.ps1
# Portable Node.js Uninstaller (Windows)
# ============================================

# Load shared config (defines $root, $pwRoot, $utils, etc.)
. "$PSScriptRoot\config.ps1"

# Node runtime folder (new architecture)
$nodeRT = Join-Path $root "node"

Write-Host "=== Portable Node.js Uninstaller ==="
Write-Host ""
Write-Host "This script will remove the ENTIRE portable Node.js runtime folder:"
Write-Host "  • $nodeRT"
Write-Host ""
Write-Host "Press Y to uninstall portable Node.js or any other key to cancel..." -NoNewline

$key  = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
$char = [string]$key.Character
Write-Host ""

if ($char.ToUpper() -ne 'Y') {
    Write-Host "Cancelled by user."
    exit
}

Write-Host ""
Write-Host "=== Removing Node runtime folder ==="

if (Test-Path $nodeRT) {
    Remove-Item $nodeRT -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[REMOVED] $nodeRT"
} else {
    Write-Host "[SKIP] Node runtime folder not found"
}

Write-Host ""
Write-Host "=== Node Uninstall Complete ==="
Write-Host "Portable Node.js runtime has been fully removed."
Write-Host ""
