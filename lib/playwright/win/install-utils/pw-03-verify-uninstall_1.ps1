param(
    [string]$target = "$PSScriptRoot"
)

Write-Host "=== Verify Uninstall (Node + Playwright) ==="
Write-Host ""
Write-Host "Checking that all uninstall targets are removed..."
Write-Host ""
Write-Host "Target folder:"
Write-Host "  $target"
Write-Host ""

Set-Location $target

function CheckGone($label, $path) {
    if (Test-Path $path) {
        Write-Host "[FAIL] $label still exists: $path"
    } else {
        Write-Host "[OK]   $label removed"
    }
}

Write-Host "=== Node Runtime ==="
CheckGone "node.exe" ".\node.exe"
CheckGone "npm.cmd" ".\npm.cmd"
CheckGone "npx.cmd" ".\npx.cmd"
Write-Host ""

Write-Host "=== Playwright Environment ==="
CheckGone "node_modules" ".\node_modules"
CheckGone "chrome-profile" ".\chrome-profile"
CheckGone "package-lock.json" ".\package-lock.json"
Write-Host ""

Write-Host "=== Verification Complete ==="
Write-Host "If all items show [OK], the environment is fully uninstalled."
Write-Host ""
