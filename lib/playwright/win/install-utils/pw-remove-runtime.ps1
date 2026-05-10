param(
    [string]$pwRoot
)

Write-Host ""
Write-Host "Removing Playwright runtime..." -ForegroundColor Yellow

# Remove package-lock.json
$lockFile = Join-Path $pwRoot "package-lock.json"
if (Test-Path $lockFile) {
    Remove-Item $lockFile -Force
    Write-Host "  Removed package-lock.json"
}

# Remove node_modules
$nodeModules = Join-Path $pwRoot "node_modules"
if (Test-Path $nodeModules) {
    Remove-Item $nodeModules -Recurse -Force
    Write-Host "  Removed node_modules"
}

# Optional: remove browser profiles
$chromeProfile = Join-Path $root "chrome-profile"
if (Test-Path $chromeProfile) {
    Remove-Item $chromeProfile -Recurse -Force
    Write-Host "  Removed chrome-profile"
}

Write-Host "Playwright runtime removed (package.json preserved)." -ForegroundColor Green
