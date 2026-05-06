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

# === SUMMARY (Windows Portable Node Installer) ===
Write-Host "=== Portable Node.js Installer (Test Mode) ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script performs a single function:"
Write-Host "  Install a fully portable, self-contained Node.js environment"
Write-Host ""
Write-Host "It will:"
Write-Host "  • Detect the latest Node.js LTS version"
Write-Host "  • Download the official Windows ZIP package"
Write-Host "  • Extract it to a temporary folder"
Write-Host "  • Copy ONLY the required portable components into:"
Write-Host "        $target"
Write-Host ""
Write-Host "Installed components:"
Write-Host "  • node.exe"
Write-Host "  • npm.cmd"
Write-Host "  • npx.cmd"
Write-Host "  • node_modules/"
Write-Host ""
Write-Host "Temporary paths used:"
Write-Host "  • ZIP download:  $env:TEMP"
Write-Host "  • Extraction:    $env:TEMP\node-extract"
Write-Host ""
Write-Host "No system changes:"
Write-Host "  • No PATH edits"
Write-Host "  • No registry writes"
Write-Host "  • No admin rights required"
Write-Host ""
Write-Host "After installation:"
Write-Host "  • A post-install test will run automatically"
Write-Host ""
# Pause-Step "STEP 0: Review summary"

Write-Host "Target folder: $target"
Pause-Step "STEP 1: Ready to begin"   # ACTIVE

# Step 1: Create target folder
if (!(Test-Path $target)) {
    New-Item -ItemType Directory -Path $target | Out-Null
}
# Pause-Step "STEP 2: Target folder created or already exists"

# Step 2: Query latest LTS version
Write-Host "Fetching latest Node.js LTS version..."
$nodeInfo = Invoke-RestMethod "https://nodejs.org/dist/index.json"
$lts = $nodeInfo | Where-Object { $_.lts } | Select-Object -First 1
$version = $lts.version.TrimStart("v")
Write-Host "Latest LTS version: $version"
# Pause-Step "STEP 3: LTS version detected"

# Step 3: Build ZIP URL
$zipName = "node-v$version-win-x64.zip"
$url = "https://nodejs.org/dist/v$version/$zipName"
Write-Host "Download URL: $url"
# Pause-Step "STEP 4: Ready to download ZIP"

# Step 4: Download ZIP
$tmpZip = Join-Path $env:TEMP $zipName
Invoke-WebRequest -Uri $url -OutFile $tmpZip
Write-Host "Download complete: $tmpZip"
# Pause-Step "STEP 5: ZIP downloaded"

# Step 5: Extract ZIP
$tmpExtract = Join-Path $env:TEMP "node-extract"
if (Test-Path $tmpExtract) { Remove-Item -Recurse -Force $tmpExtract }
Expand-Archive -Path $tmpZip -DestinationPath $tmpExtract
Write-Host "Extraction complete: $tmpExtract"
# Pause-Step "STEP 6: ZIP extracted"

# Step 6: Copy portable Node files
$src = Join-Path $tmpExtract "node-v$version-win-x64"

Write-Host "Copying Node files to portable folder..."
Copy-Item "$src\node.exe" $target -Force
Copy-Item "$src\npm.cmd" $target -Force
Copy-Item "$src\npx.cmd" $target -Force
Copy-Item "$src\node_modules" $target -Recurse -Force
Write-Host "Node.js portable installation complete."
# Pause-Step "STEP 7: Node files copied"

# Step 7: Cleanup
Remove-Item $tmpZip -Force
Remove-Item $tmpExtract -Recurse -Force
Write-Host "Temporary files cleaned up."
# Pause-Step "STEP 8: Cleanup done"

# === POST-INSTALL TEST ===
Write-Host ""
Write-Host "=== Running post-install test ===" -ForegroundColor Cyan
$nodeExe = Join-Path $target "node.exe"

if (Test-Path $nodeExe) {
    $versionOutput = & $nodeExe --version
    Write-Host "Node version detected: $versionOutput" -ForegroundColor Green
} else {
    Write-Host "ERROR: node.exe not found in portable folder!" -ForegroundColor Red
}

# Pause-Step "STEP 9: Test complete"

Write-Host ""
Write-Host "=== DONE ==="
Write-Host "Portable Node.js installed and verified in:"
Write-Host "  $target"
Write-Host ""
