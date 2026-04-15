<?php

$root = __DIR__;

ob_start();

echo "=== Playwright Doctor ===\n\n";

function check($label, $ok) {
    echo $ok ? "[OK]   $label\n" : "[FAIL] $label\n";
}

function browserVersion($path) {
    $dirs = glob("$path/*", GLOB_ONLYDIR);
    return $dirs ? basename($dirs[0]) : "none";
}

// Windows
check("Windows imdb-fetch-win.mjs", file_exists("$root/win/imdb-fetch-win.mjs"));
check("Windows node.exe", file_exists("$root/win/node.exe"));
check("Windows node_modules", file_exists("$root/win/node_modules/playwright"));
check("Windows browsers", file_exists("$root/win/node_modules/playwright-core/.local-browsers"));
echo "Windows browser: " . browserVersion("$root/win/node_modules/playwright-core/.local-browsers") . "\n\n";

// Linux-macos
check("Linux-mac imdb-fetch-unix.mjs", file_exists("$root/linux-mac/imdb-fetch-unix.mjs"));
check("Linux-mac node_modules", file_exists("$root/linux-mac/node_modules/playwright"));
check("Linux-mac node_modules-core", file_exists("$root/linux-mac/node_modules/playwright-core"));
check("Linux-mac browsers", file_exists("$root/linux-mac/browsers"));
echo "Linux-mac browser: " . browserVersion("$root/linux-mac/browsers") . "\n\n";

// linus nas arm64
check("Linux-nas-arm64 imdb-fetch-linux.mjs", file_exists("$root/linux-nas-arm64/imdb-fetch-unix.mjs"));
check("Linux-nas-arm64 imdb-fetch-linux.cjs", file_exists("$root/linux-nas-arm64/imdb-fetch-unix.cjs"));
check("Linux-nas-arm64 node_modules", file_exists("$root/linux-nas-arm64/node_modules/playwright"));
check("Linux-nas-arm64 node_modules-core", file_exists("$root/linux-nas-arm64/node_modules/playwright-core"));

$docker = trim(shell_exec("docker --version 2>&1"));
check("Docker available", str_contains($docker, "version"));

echo "\nDoctor complete.\n";

echo nl2br(htmlspecialchars(ob_get_clean(), ENT_QUOTES, 'UTF-8'));