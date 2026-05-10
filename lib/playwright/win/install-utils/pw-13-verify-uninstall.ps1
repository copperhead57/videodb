# ============================================
# pw-13-verify-uninstall.ps1
# Verify Portable Uninstall (Windows)
# ============================================

# Load shared config (defines $root, $pwRoot, $utils, etc.)
. "$PSScriptRoot\config.ps1"

# Node runtime folder
$nodeRT = Join-Path $root "node"

# Playwright uninstall targets
$pwNodeModules = Join-Path $pwRoot "node_modules"
$pwLockFile    = Join-Path $pwRoot "package-lock.json"

# Persistent browser profile
$profileDir = Join-Path $root "chrome-profile"

Write-Host "=== Verify Uninstall (Node + Playwright) ==="
Write-Host ""
Write-Host "Checking that all uninstall targets are removed..."
Write-Host ""

function CheckGone($label, $path) {
    if (Test-Path $path) {
        Write-Host "[FAIL] $label still exists: $path"
    } else {
        Write-Host "[OK]   $label removed"
    }
}

Write-Host "=== Node Runtime ==="
CheckGone "Node runtime folder" $nodeRT
Write-Host ""

Write-Host "=== Playwright Environment ==="
CheckGone "Playwright node_modules" $pwNodeModules
CheckGone "Playwright package-lock.json" $pwLockFile
CheckGone "Chrome profile" $profileDir
Write-Host ""

Write-Host "=== Verification Complete ==="
Write-Host "If all items show [OK], the environment is fully uninstalled."
Write-Host ""
