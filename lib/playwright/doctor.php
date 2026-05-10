<?php

$root = __DIR__;

ob_start();

echo "=== Playwright Doctor ===\n\n";

function check($label, $ok) {
    echo $ok ? "[OK]   $label\n" : "[FAIL] $label\n";
}

function browserVersion($path) {
    if (!is_dir($path)) return "none";
    $dirs = glob("$path/*", GLOB_ONLYDIR);
    return $dirs ? basename($dirs[0]) : "none";
}

echo "=== WINDOWS ===\n";
check("imdb-fetch-win.mjs", file_exists("$root/win/imdb-fetch-win.mjs"));
check("node.exe", file_exists("$root/win/node.exe"));
check("node_modules/playwright", file_exists("$root/win/node_modules/playwright"));
check("node_modules/playwright-core", file_exists("$root/win/node_modules/playwright-core"));
check(".local-browsers", file_exists("$root/win/node_modules/playwright-core/.local-browsers"));
check("chrome-profile", is_dir("$root/win/chrome-profile"));
echo "Windows browser: " . browserVersion("$root/win/node_modules/playwright-core/.local-browsers") . "\n\n";


echo "=== LINUX ===\n";
check("imdb-fetch-unix.mjs", file_exists("$root/linux/imdb-fetch-unix.mjs"));
check("node_modules/playwright", file_exists("$root/linux/node_modules/playwright"));
check("node_modules/playwright-core", file_exists("$root/linux/node_modules/playwright-core"));
check("browsers/", is_dir("$root/linux/browsers"));
echo "Linux browser: " . browserVersion("$root/linux/browsers") . "\n\n";


echo "=== LINUX NAS ARM64 ===\n";
check("imdb-fetch-unix.mjs", file_exists("$root/linux-nas-arm64/imdb-fetch-unix.mjs"));
check("imdb-fetch-unix.cjs", file_exists("$root/linux-nas-arm64/imdb-fetch-unix.cjs"));
check("node_modules/playwright", file_exists("$root/linux-nas-arm64/node_modules/playwright"));
check("node_modules/playwright-core", file_exists("$root/linux-nas-arm64/node_modules/playwright-core"));
check("browsers/", is_dir("$root/linux-nas-arm64/browsers"));
echo "NAS browser: " . browserVersion("$root/linux-nas-arm64/browsers") . "\n\n";


echo "=== DOCKER ===\n";
$docker = trim(shell_exec("docker --version 2>&1"));
check("Docker available", str_contains($docker, "version"));
echo "\n";


echo "Doctor complete.\n";

echo nl2br(htmlspecialchars(ob_get_clean(), ENT_QUOTES, 'UTF-8'));
