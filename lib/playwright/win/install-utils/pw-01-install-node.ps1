# ============================================
# Portable Node.js Installer (Windows)
# ============================================

$ErrorActionPreference = "Stop"

# --------------------------------------------
# Load shared config (single source of truth)
# --------------------------------------------
. "$PSScriptRoot\config.ps1"

function Ask-YesNo($msg) {
    Write-Host ""
    Write-Host "$msg (Y/N)" -ForegroundColor Yellow -NoNewline
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $char = [string]$key.Character
    Write-Host ""
    return ($char.ToUpper() -eq 'Y')
}

Write-Host "=== Portable Node.js Installer (Windows) ===" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------
# Detect existing Node installation
# ---------------------------------------------------------
$existingVersion = $null
$upgradeChosen = $false
$exitCode = 0

if (Test-Path $nodeExe) {
    $existingVersion = (& $nodeExe --version).Trim()
    Write-Host "Existing Node.js detected: $existingVersion" -ForegroundColor Yellow
}

# ---------------------------------------------------------
# TESTING OVERRIDE (optional)
# ---------------------------------------------------------
# $existingVersion = "24.10.0"

# ---------------------------------------------------------
# Fetch latest LTS version
# ---------------------------------------------------------
Write-Host "Fetching latest Node.js LTS version..."
$nodeInfo = Invoke-RestMethod "https://nodejs.org/dist/index.json"
$lts = $nodeInfo | Where-Object { $_.lts } | Select-Object -First 1
$latestVersion = $lts.version.TrimStart("v")
Write-Host "Latest LTS version: $latestVersion"

# ---------------------------------------------------------
# TESTING OVERRIDE (optional)
# ---------------------------------------------------------
# $latestVersion = "24.10.0"
# Write-Host "Testing Override Latest LTS version to : $latestVersion"

# ---------------------------------------------------------
# If Node exists, offer 3‑way menu
# ---------------------------------------------------------
if ($existingVersion) {

    Write-Host ""
    Write-Host "Choose an action:"
    Write-Host "  1) Reinstall version $existingVersion (repair / force clean install)"
    Write-Host "  2) Upgrade to latest LTS ($latestVersion)"
    Write-Host "  3) Keep existing version $existingVersion (bypass)"
    Write-Host ""

    Write-Host "Select option (1/2/3): " -NoNewline
    $choice = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
    Write-Host ""

    switch ($choice) {
        '1' {
            Write-Host "Reinstall selected." -ForegroundColor Cyan
            $upgradeChosen = $true
            $exitCode = 10
        }
        '2' {
            if ($existingVersion.TrimStart("v") -eq $latestVersion) {
                Write-Host "Already latest LTS. No upgrade needed." -ForegroundColor Green
                exit 0
            }
            Write-Host "Upgrade selected." -ForegroundColor Cyan
            $upgradeChosen = $true
            $exitCode = 11
        }
        '3' {
            Write-Host "Keeping existing Node.js version." -ForegroundColor Green
            exit 0
        }
        default {
            Write-Host "Invalid choice. Aborting." -ForegroundColor Red
            exit 1
        }
    }
}

# ---------------------------------------------------------
# Decide which version to install (reinstall vs upgrade)
# ---------------------------------------------------------
if ($upgradeChosen -and $exitCode -eq 10) {
    # Reinstall same version (repair)
    $versionToInstall = $existingVersion.TrimStart("v")
} else {
    # Upgrade or fresh install
    $versionToInstall = $latestVersion
}

# ---------------------------------------------------------
# Remove old Node installation
# ---------------------------------------------------------
if ($upgradeChosen) {
    Write-Host ""
    Write-Host "Removing old Node.js installation..." -ForegroundColor Yellow

    if (Test-Path $nodeRT) {
        Remove-Item $nodeRT -Recurse -Force
    }

    Write-Host "Old Node.js removed."
}

# ---------------------------------------------------------
# Install Node.js
# ---------------------------------------------------------
Write-Host ""
Write-Host "Installing Node.js $versionToInstall..." -ForegroundColor Cyan

if (!(Test-Path $nodeRT)) {
    New-Item -ItemType Directory -Path $nodeRT | Out-Null
}

$zipName = "node-v$versionToInstall-win-x64.zip"
$url = "https://nodejs.org/dist/v$versionToInstall/$zipName"

Write-Host "Download URL: $url"

$tmpZip = Join-Path $env:TEMP $zipName
Invoke-WebRequest -Uri $url -OutFile $tmpZip
Write-Host "Download complete: $tmpZip"

$tmpExtract = Join-Path $env:TEMP "node-extract"
if (Test-Path $tmpExtract) { Remove-Item -Recurse -Force $tmpExtract }
Expand-Archive -Path $tmpZip -DestinationPath $tmpExtract
Write-Host "Extraction complete: $tmpExtract"

$src = Join-Path $tmpExtract "node-v$versionToInstall-win-x64"

Write-Host "Copying Node files to portable runtime folder..."
Copy-Item "$src\node.exe" $nodeRT -Force
Copy-Item "$src\npm.cmd" $nodeRT -Force
Copy-Item "$src\npx.cmd" $nodeRT -Force
Copy-Item "$src\node_modules" $nodeRT -Recurse -Force
Write-Host "Node.js portable installation complete."

Remove-Item $tmpZip -Force
Remove-Item $tmpExtract -Recurse -Force
Write-Host "Temporary files cleaned up."

Write-Host ""
Write-Host "=== Running post-install test ===" -ForegroundColor Cyan
$versionOutput = & $nodeExe --version
Write-Host "Node version detected: $versionOutput" -ForegroundColor Green

Write-Host ""
Write-Host "=== DONE ==="
Write-Host "Portable Node.js installed and verified in:"
Write-Host "  $nodeRT"
Write-Host ""

if ($exitCode) {
    exit $exitCode
} else {
    exit 0
}
