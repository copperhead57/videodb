param(
    [string]$target = "$PSScriptRoot"
)

function Pause-Step($message) {
    Write-Host ""
    Write-Host $message -ForegroundColor Yellow
    Write-Host "Press Y to continue or any other key to cancel..." -NoNewline

    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $char = [string]$key.Character

    if ($char.ToUpper() -ne 'Y') {
        Write-Host ""
        Write-Host "Cancelled by user." -ForegroundColor Red
        exit
    }

    Write-Host ""
}

# === SUMMARY (Windows Portable Playwright Installer) ===
Write-Host "=== Portable Playwright Installer ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script performs a single function:"
Write-Host "  Install Playwright and Chromium into a portable environment"
Write-Host ""
Write-Host "It will:"
Write-Host "  • Use the portable Node.js environment in:"
Write-Host "        $target"
Write-Host "  • Install the Playwright NPM package locally"
Write-Host "  • Install Chromium into:"
Write-Host "        $target\node_modules\playwright-core\.local-browsers"
Write-Host ""
Write-Host "No system changes:"
Write-Host "  • No PATH edits"
Write-Host "  • No registry writes"
Write-Host "  • No admin rights required"
Write-Host ""
Write-Host "After installation:"
Write-Host "  • A Playwright version test will run automatically"
Write-Host ""
# Pause-Step "STEP 0: Review summary"

Write-Host "Target folder: $target"
Pause-Step "STEP 1: Ready to begin"   # ACTIVE

# Ensure we are inside the target folder
Set-Location $target

# Ensure package.json exists
if (!(Test-Path "$target\package.json")) {
    Write-Host "Creating package.json..."
    .\node.exe -e "require('fs').writeFileSync('package.json','{}')"
}

# Install Playwright package
Write-Host "Installing Playwright..."
.\npm.cmd install playwright --save-exact

# Install Chromium browser
Write-Host "Installing Chromium..."
$env:PLAYWRIGHT_BROWSERS_PATH = "0"
.\node.exe node_modules\playwright\cli.js install chromium

# === POST-INSTALL TEST ===
Write-Host ""
Write-Host "=== Running Playwright test ===" -ForegroundColor Cyan

$pwCli = ".\node.exe node_modules\playwright\cli.js --version"
$pwVersion = Invoke-Expression $pwCli

Write-Host "Playwright version detected: $pwVersion" -ForegroundColor Green

Pause-Step "STEP 2: Test complete"   # ACTIVE

Write-Host ""
Write-Host "=== DONE ==="
Write-Host "Playwright installed in:"
Write-Host "  $target"
Write-Host ""
Write-Host "Browsers installed in:"
Write-Host "  $target\node_modules\playwright-core\.local-browsers"
Write-Host ""
