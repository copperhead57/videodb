# ============================================
# Portable Environment Verification (Windows)
# ============================================

$ErrorActionPreference = "Stop"

# Load config (defines $nodeRoot, $pwRoot, etc.)
. "$PSScriptRoot\config.ps1"

Write-Host "=== Portable Environment Verification (Node + Playwright) ==="
Write-Host ""
Write-Host "Node folder        : $nodeRT"
Write-Host "Playwright folder  : $pwRoot"
Write-Host "Playwright Browsers: $pwBrowsers"
Write-Host ""

function Check($label, $path) {
    if (Test-Path $path) {
        Write-Host "[OK]   $label"
    } else {
        Write-Host "[FAIL] $label"
    }
}

# ---------------------------------------------------------
# Node Runtime
# ---------------------------------------------------------
Write-Host "--- Node Runtime ---"

Check "node.exe" (Join-Path $nodeRT "node.exe")
Check "npm.cmd"  (Join-Path $nodeRT "npm.cmd")

# Node version
$nodeExe = Join-Path $nodeRT "node.exe"
$nodeVersion = & $nodeExe -p "process.version" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK]   Node runtime detected ($nodeVersion)"
} else {
    Write-Host "[FAIL] Node runtime"
}

# ---------------------------------------------------------
# Playwright Runtime
# ---------------------------------------------------------
Write-Host ""
Write-Host "--- Playwright Runtime ---"

$pwNodeModules = Join-Path $pwRoot "node_modules"
$pwPackage     = Join-Path $pwNodeModules "playwright"
$pwCli         = Join-Path $pwPackage "cli.js"

Check "Playwright package" $pwPackage
Check "Playwright CLI"     $pwCli

# ---------------------------------------------------------
# Browsers
# ---------------------------------------------------------
Write-Host ""
Write-Host "--- Playwright Browsers ---"

Check "Browser root folder" $pwBrowsers

# Chromium
$chromium = Get-ChildItem $pwBrowsers -Directory -Filter "chromium-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($chromium) {
    Write-Host "[OK]   Chromium installed ($($chromium.Name))"
} else {
    Write-Host "[FAIL] Chromium not found"
}

# FFmpeg
$ffmpeg = Get-ChildItem $pwBrowsers -Directory -Filter "ffmpeg-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($ffmpeg) {
    Write-Host "[OK]   FFmpeg installed ($($ffmpeg.Name))"
} else {
    Write-Host "[FAIL] FFmpeg not found"
}

# Headless Shell
$headless = Get-ChildItem $pwBrowsers -Directory -Filter "chromium_headless_shell-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($headless) {
    Write-Host "[OK]   Chromium Headless Shell installed ($($headless.Name))"
} else {
    Write-Host "[FAIL] Chromium Headless Shell not found"
}

# Winldd
$winldd = Get-ChildItem $pwBrowsers -Directory -Filter "winldd-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($winldd) {
    Write-Host "[OK]   Winldd installed ($($winldd.Name))"
} else {
    Write-Host "[FAIL] Winldd not found"
}

Write-Host ""
Write-Host "=== Verification complete ==="
