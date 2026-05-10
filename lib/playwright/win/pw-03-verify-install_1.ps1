param(
    [string]$target = "$PSScriptRoot"
)

Write-Host "=== Portable Environment Verification (Node LTS) ==="

Set-Location $target

function Check($label, $path) {
    if (Test-Path $path) {
        Write-Host "[OK]   $label"
    } else {
        Write-Host "[FAIL] $label"
    }
}

# --- Core Node Runtime ---
Check "node.exe" ".\node.exe"
Check "npm.cmd (embedded)" ".\npm.cmd"

# Node internal runtime check
$nodeRuntime = .\node.exe -p "process.version" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK]   Node runtime detected ($nodeRuntime)"
} else {
    Write-Host "[FAIL] Node runtime"
}

# --- Playwright Runtime ---
Check "Playwright package" ".\node_modules\playwright"
Check "Playwright CLI" ".\node_modules\playwright\cli.js"

# --- Playwright Core + Browsers ---
$browserRoot = ".\node_modules\playwright-core\.local-browsers"
Check "Browser root folder" $browserRoot

# Chromium
$chromium = Get-ChildItem "$browserRoot" -Directory -Filter "chromium-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($chromium) {
    Write-Host "[OK]   Chromium installed ($($chromium.Name))"
} else {
    Write-Host "[FAIL] Chromium not found"
}

# FFmpeg
$ffmpeg = Get-ChildItem "$browserRoot" -Directory -Filter "ffmpeg-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($ffmpeg) {
    Write-Host "[OK]   FFmpeg installed ($($ffmpeg.Name))"
} else {
    Write-Host "[FAIL] FFmpeg not found"
}

# Headless Shell
$headless = Get-ChildItem "$browserRoot" -Directory -Filter "chromium_headless_shell-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($headless) {
    Write-Host "[OK]   Chromium Headless Shell installed ($($headless.Name))"
} else {
    Write-Host "[FAIL] Chromium Headless Shell not found"
}

# Winldd
$winldd = Get-ChildItem "$browserRoot" -Directory -Filter "winldd-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($winldd) {
    Write-Host "[OK]   Winldd installed ($($winldd.Name))"
} else {
    Write-Host "[FAIL] Winldd not found"
}

Write-Host "=== Verification complete ==="

Pause
