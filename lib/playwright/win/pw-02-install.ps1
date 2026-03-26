Write-Host "=== Portable Playwright Installer ==="

$env:PLAYWRIGHT_BROWSERS_PATH = "0"

Write-Host "Installing Playwright..."
.\npm.cmd install playwright

Write-Host "Installing Chromium..."
.\node.exe node_modules\playwright\cli.js install chromium

Write-Host "=== Install complete ==="
Write-Host "Playwright installed in: $PWD"
Write-Host "Browsers installed in: $PWD\node_modules\playwright-core\.local-browsers"

Pause