# ============================================
# Portable Playwright Installer (Windows)
# ============================================

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------
# Load config (portable Node + Playwright paths)
# ---------------------------------------------------------
. "$PSScriptRoot\config.ps1"

# Shared runtime removal util
$removeRuntime = "$PSScriptRoot\pw-remove-runtime.ps1"

function Ask-YesNo($msg) {
    Write-Host ""
    Write-Host "$msg (Y/N)" -ForegroundColor Yellow -NoNewline
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $char = [string]$key.Character
    Write-Host ""
    return ($char.ToUpper() -eq 'Y')
}

Write-Host "=== Portable Playwright Installer ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Target folder: $pwRoot"
Write-Host ""

# ---------------------------------------------------------
# Detect fresh install
# ---------------------------------------------------------
$pwFreshInstall = -not (Test-Path $pwRoot)

if ($pwFreshInstall) {
    Write-Host "Playwright folder missing - performing fresh install." -ForegroundColor Yellow
}

# ---------------------------------------------------------
# Detect existing installed version
# ---------------------------------------------------------
$existingVersion = $null
$pwPackageJson = Join-Path $pwRoot "node_modules\playwright\package.json"

if (!$pwFreshInstall -and (Test-Path $pwPackageJson)) {
    $json = Get-Content $pwPackageJson | ConvertFrom-Json
    $existingVersion = $json.version
    Write-Host "Existing Playwright detected: v$existingVersion" -ForegroundColor Yellow
}

# ---------------------------------------------------------
# Read version from Git-tracked package.json
# ---------------------------------------------------------
$pkgJson = Join-Path $pwRoot "package.json"
$packageJsonVersion = $null

if (Test-Path $pkgJson) {
    $jsonPkg = Get-Content $pkgJson | ConvertFrom-Json
    $packageJsonVersion = $jsonPkg.dependencies.playwright
    $packageJsonVersion = $packageJsonVersion -replace '[^\d\.]', ''
}

# ---------------------------------------------------------
# Fetch latest version from npm
# ---------------------------------------------------------
Write-Host "Fetching latest Playwright version..."
$npmInfo = Invoke-RestMethod "https://registry.npmjs.org/playwright/latest"
$latestVersion = $npmInfo.version
Write-Host "Latest Playwright version: v$latestVersion"

# ---------------------------------------------------------
# Version decision logic (Repair / Upgrade / Bypass)
# ---------------------------------------------------------
$upgradeMode = $null

$runtimeExists = Test-Path (Join-Path $pwRoot "node_modules")

if ($packageJsonVersion) {

    Write-Host ""
    Write-Host "Playwright version check:" -ForegroundColor Cyan
    Write-Host "  package.json:  v$packageJsonVersion"
    Write-Host "  Latest (npm):  v$latestVersion"

    if ($existingVersion) {
        Write-Host "  Installed:     v$existingVersion"
    } else {
        Write-Host "  Installed:     (none detected)"
    }

    Write-Host ""

    if ($runtimeExists) {
        # Node did NOT change → runtime still exists → allow bypass
        Write-Host "Choose Playwright install mode:" -ForegroundColor Cyan
        Write-Host "  1) Repair (use package.json version: v$packageJsonVersion)"
        Write-Host "  2) Upgrade (use latest version: v$latestVersion)"
        Write-Host "  3) Bypass (skip Playwright install)"
        Write-Host ""

        $choice = Read-Host "Enter choice (1, 2, or 3)"

        switch ($choice) {
            "1" { $upgradeMode = "repair" }
            "2" { $upgradeMode = "upgrade" }
            "3" { $upgradeMode = "bypass" }
            default {
                Write-Host "Invalid choice. Cancelling." -ForegroundColor Red
                exit 1
            }
        }
    }
    else {
        # Node changed → runtime wiped → bypass not allowed
        Write-Host "Playwright runtime missing (Node changed). Installation required." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Choose Playwright install mode:" -ForegroundColor Cyan
        Write-Host "  1) Repair (use package.json version: v$packageJsonVersion)"
        Write-Host "  2) Upgrade (use latest version: v$latestVersion)"
        Write-Host ""

        $choice = Read-Host "Enter choice (1 or 2)"

        switch ($choice) {
            "1" { $upgradeMode = "repair" }
            "2" { $upgradeMode = "upgrade" }
            default {
                Write-Host "Invalid choice. Cancelling." -ForegroundColor Red
                exit 1
            }
        }
    }
}
else {
    # No package.json version → must install latest
    $upgradeMode = "upgrade"
}


# ---------------------------------------------------------
# Apply chosen mode
# ---------------------------------------------------------
switch ($upgradeMode) {

    "repair" {
        Write-Host ""
        Write-Host "Repairing Playwright runtime..." -ForegroundColor Yellow
        & $removeRuntime -pwRoot $pwRoot

        $installVersion = $packageJsonVersion
        Write-Host "Installing Playwright v$installVersion..." -ForegroundColor Cyan
    }

    "upgrade" {
        Write-Host ""
        Write-Host "Upgrading Playwright runtime..." -ForegroundColor Yellow
        & $removeRuntime -pwRoot $pwRoot

        $installVersion = $latestVersion
        Write-Host "Installing Playwright v$installVersion..." -ForegroundColor Cyan
    }

    "bypass" {
        Write-Host ""
        Write-Host "Bypassing Playwright installation (runtime preserved)." -ForegroundColor Yellow
        exit 0
    }
}

# ---------------------------------------------------------
# Ensure pwRoot exists
# ---------------------------------------------------------
if (!(Test-Path $pwRoot)) {
    New-Item -ItemType Directory -Path $pwRoot | Out-Null
}

# ---------------------------------------------------------
# Ensure package.json exists
# ---------------------------------------------------------
if (!(Test-Path $pkgJson)) {
    Write-Host "Creating package.json..."
    Push-Location $pwRoot
    & $nodeExe -e "require('fs').writeFileSync('package.json','{}')"
    Pop-Location
}

# ---------------------------------------------------------
# Install Playwright package
# ---------------------------------------------------------
& $npmCmd install "playwright@$installVersion" --save-exact --prefix $pwRoot

# ---------------------------------------------------------
# Install Chromium browser
# ---------------------------------------------------------
Write-Host "Installing Chromium..."
$env:PLAYWRIGHT_BROWSERS_PATH = "0"
& $nodeExe "$pwRoot\node_modules\playwright\cli.js" install chromium

# ---------------------------------------------------------
# Post-install test
# ---------------------------------------------------------
Write-Host ""
Write-Host "=== Running Playwright test ===" -ForegroundColor Cyan

$pwVersion = & $nodeExe "$pwRoot\node_modules\playwright\cli.js" --version

Write-Host "Playwright version detected: $pwVersion" -ForegroundColor Green

Write-Host ""
Write-Host "=== DONE ==="
Write-Host "Playwright installed in:"
Write-Host "  $pwRoot"
Write-Host ""
Write-Host "Browsers installed in:"
$browserPath = Join-Path $pwRoot 'node_modules\playwright-core\.local-browsers'
Write-Host "  $browserPath"
Write-Host ""

exit 0
