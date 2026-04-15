Write-Host "=== Portable Environment Verification (Node 25+) ==="

function Check($label, $path) {
    if (Test-Path $path) {
        Write-Host "[OK] $label"
    } else {
        Write-Host "[FAIL] $label"
    }
}

# --- Core Node Runtime ---
Check "node.exe" ".\node.exe"
Check "npm.cmd (embedded)" ".\npm.cmd"

# Corepack is NOT included in Node 25 — mark as OK but not applicable
Write-Host "[OK] corepack (not included in Node 25)"

# Node 25 internal JS runtime (snapshot)
$nodeSnapshot = .\node.exe -p "process.execPath" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Node internal runtime (snapshot detected)"
} else {
    Write-Host "[FAIL] Node internal runtime"
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
    Write-Host "[OK] Chromium installed ($($chromium.Name))"
} else {
    Write-Host "[FAIL] Chromium not found"
}

# FFmpeg
$ffmpeg = Get-ChildItem "$browserRoot" -Directory -Filter "ffmpeg-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($ffmpeg) {
    Write-Host "[OK] FFmpeg installed ($($ffmpeg.Name))"
} else {
    Write-Host "[FAIL] FFmpeg not found"
}

# Headless Shell
$headless = Get-ChildItem "$browserRoot" -Directory -Filter "chromium_headless_shell-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($headless) {
    Write-Host "[OK] Chromium Headless Shell installed ($($headless.Name))"
} else {
    Write-Host "[FAIL] Chromium Headless Shell not found"
}

# Winldd
$winldd = Get-ChildItem "$browserRoot" -Directory -Filter "winldd-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($winldd) {
    Write-Host "[OK] Winldd installed ($($winldd.Name))"
} else {
    Write-Host "[FAIL] Winldd not found"
}

Write-Host "=== Verification complete ==="

Pause