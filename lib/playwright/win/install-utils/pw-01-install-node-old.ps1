param(
    [string]$target,
    [string]$version = "18.19.0"   # Change this to any older version you want
)

$ErrorActionPreference = "Stop"

Write-Host "=== Installing OLD Node.js version for testing ===" -ForegroundColor Cyan
Write-Host "Target folder: $target"
Write-Host "Version to install: v$version"
Write-Host ""

# Ensure target exists
if (!(Test-Path $target)) {
    New-Item -ItemType Directory -Path $target | Out-Null
}

# Clean any existing Node installation
Write-Host "Removing any existing Node.js installation..." -ForegroundColor Yellow

$pathsToRemove = @(
    (Join-Path $target "node.exe"),
    (Join-Path $target "npm.cmd"),
    (Join-Path $target "npx.cmd"),
    (Join-Path $target "node_modules")
)

foreach ($p in $pathsToRemove) {
    if (Test-Path $p) {
        Remove-Item $p -Recurse -Force
    }
}

Write-Host "Old Node.js removed."
Write-Host ""

# Build download URL
$zipName = "node-v$version-win-x64.zip"
$url = "https://nodejs.org/dist/v$version/$zipName"

Write-Host "Downloading Node.js v$version..."
Write-Host "URL: $url"

$tmpZip = Join-Path $env:TEMP $zipName
Invoke-WebRequest -Uri $url -OutFile $tmpZip
Write-Host "Download complete."

# Extract ZIP
$tmpExtract = Join-Path $env:TEMP "node-old-extract"
if (Test-Path $tmpExtract) { Remove-Item -Recurse -Force $tmpExtract }
Expand-Archive -Path $tmpZip -DestinationPath $tmpExtract
Write-Host "Extraction complete."

# Copy portable components
$src = Join-Path $tmpExtract "node-v$version-win-x64"

Write-Host "Copying Node files to portable folder..."
Copy-Item "$src\node.exe" $target -Force
Copy-Item "$src\npm.cmd" $target -Force
Copy-Item "$src\npx.cmd" $target -Force
Copy-Item "$src\node_modules" $target -Recurse -Force

Write-Host "Old Node.js version installed."

# Cleanup
Remove-Item $tmpZip -Force
Remove-Item $tmpExtract -Recurse -Force

Write-Host ""
Write-Host "=== DONE ==="
Write-Host "Installed old Node.js version v$version for upgrade testing."
Write-Host ""

exit 0
