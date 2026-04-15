Write-Host "=== Cleaning Playwright Bundle (Windows) ==="
Write-Host ""

$base = "node_modules/playwright-core/.local-browsers"

# --- Remove Firefox browsers ---
$firefox = Join-Path $base "firefox*"
if (Test-Path $firefox) {
    Write-Host "Removing Firefox browsers..."
    Remove-Item $firefox -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "No Firefox browsers found. Skipping."
}

Write-Host ""

# --- Remove WebKit browsers ---
$webkit = Join-Path $base "webkit*"
if (Test-Path $webkit) {
    Write-Host "Removing WebKit browsers..."
    Remove-Item $webkit -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "No WebKit browsers found. Skipping."
}

Write-Host ""
Write-Host "Cleanup complete."