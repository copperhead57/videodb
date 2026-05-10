param(
    [string]$url = "https://www.imdb.com/title/tt0133093/"
)

# Enable ANSI escape sequences in this PowerShell session
#$env:TERM = "xterm"

# Load portable environment config
. "$PSScriptRoot\config.ps1"

Write-Host "Launching Chromium test using imdb-fetch-win-headed.mjs..."
Write-Host "URL: $url"
Write-Host ""

# === Red bordered warning box ===
$red   = "`e[1;31m"
$reset = "`e[0m"

Write-Host ""
Write-Host "$red###############################################$reset"
Write-Host "$red#                                             #$reset"
Write-Host "$red#   WARNING: A browser window will open       #$reset"
Write-Host "$red#   during this test. DO NOT CLOSE IT.        #$reset"
Write-Host "$red#                                             #$reset"
Write-Host "$red###############################################$reset"
Write-Host ""

Write-Host "Press any key to continue..." -NoNewline
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""
Write-Host ""

# --- Start process and capture both streams ---
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $nodeExe
$psi.Arguments = "`"$root\imdb-fetch-win-headed.mjs`" `"$url`""
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi
$proc.Start() | Out-Null

$stdout = $proc.StandardOutput.ReadToEnd()
$stderr = $proc.StandardError.ReadToEnd()

$proc.WaitForExit()

Write-Host "=== DEBUG / TIMING ==="
Write-Host $stderr
Write-Host ""

# --- Parse JSON safely ---
try {
    $json = $stdout | ConvertFrom-Json
} catch {
    Write-Host "ERROR: JSON parse failed."
    Write-Host "Raw output:"
    Write-Host $stdout
    exit
}

# --- HTML truncation ---
$limit = 800
$html  = $json.html

if ([string]::IsNullOrEmpty($html)) {
    $truncated = "[NO HTML RETURNED]"
} else {
    $max = [Math]::Min($limit, $html.Length)
    $truncated = $html.Substring(0, $max)

    if ($html.Length -gt $limit) {
        $truncated += "[TRUNCATED]"
    }
}

Write-Host "=== JSON SUMMARY ==="
Write-Host "ok:          $($json.ok)"
Write-Host "wafDetected: $($json.wafDetected)"
Write-Host "error:       $($json.error)"
Write-Host ""

Write-Host "=== HTML (first $limit chars) ==="
Write-Host $truncated
Write-Host ""
