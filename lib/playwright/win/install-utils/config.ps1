# Resolve root folder (win/)
$root = Split-Path -Parent $PSScriptRoot

# Node runtime folder
$nodeRT = Join-Path $root "node"

# Playwright project folder
$pwRoot = Join-Path $root "pw"

# Executables
$nodeExe = Join-Path $nodeRT "node.exe"
$npmCmd  = Join-Path $nodeRT "npm.cmd"
$npxCmd  = Join-Path $nodeRT "npx.cmd"

# Playwright paths
$pwNodeModules = Join-Path $pwRoot "node_modules"
$pwBrowsers    = Join-Path $pwNodeModules "playwright-core\.local-browsers"

# utils lib
$utils = Join-Path $root "install-utils"
