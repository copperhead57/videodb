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

// Shared script
check("Shared imdb-fetch.js", file_exists("$root/imdb-fetch.js"));

// Windows
check("Windows node.exe", file_exists("$root/win/node.exe"));
check("Windows node_modules", file_exists("$root/win/node_modules/playwright"));
check("Windows browsers", file_exists("$root/win/node_modules/playwright-core/.local-browsers"));
echo "Windows browser: " . browserVersion("$root/win/node_modules/playwright-core/.local-browsers") . "\n\n";

// Linux
check("Linux node_modules", file_exists("$root/linux/node_modules/playwright"));
check("Linux browsers", file_exists("$root/linux/playwright-core/.local-browsers"));
echo "Linux browser: " . browserVersion("$root/linux/playwright-core/.local-browsers") . "\n\n";

// macOS
check("macOS node_modules", file_exists("$root/mac/node_modules/playwright"));
check("macOS browsers", file_exists("$root/mac/playwright-core/.local-browsers"));
echo "macOS browser: " . browserVersion("$root/mac/playwright-core/.local-browsers") . "\n\n";

// Docker
$docker = trim(shell_exec("docker --version 2>&1"));
check("Docker available", str_contains($docker, "version"));

echo "\nDoctor complete.\n";

echo nl2br(htmlspecialchars(ob_get_clean(), ENT_QUOTES, 'UTF-8'));