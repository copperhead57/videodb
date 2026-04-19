#!/usr/bin/env node

// ============================================================================
// imdb-fetch.mjs — Unified Windows + Linux/macOS x86 Fetcher
// ARM64 NAS gracefully exits (Docker wrapper required)
// Stable JSON schema, explicit platform branching
// ============================================================================

import path from 'path';
import { fileURLToPath } from 'url';
import process from 'process';
import os from 'os';

// ------------------------------------------------------------
// 1. Resolve script directory (ESM-safe __dirname / __filename)
// ------------------------------------------------------------
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.error("[DEBUG]-Fetcher LOADED:", __filename);

// ------------------------------------------------------------
// 2. Stable JSON output helper
// ------------------------------------------------------------
function output(ok, html, wafDetected, error) {
    console.log(JSON.stringify({ ok, html, wafDetected, error }));
}

// ------------------------------------------------------------
// 3. Input URL
// ------------------------------------------------------------
let url = process.argv[2];
if (!url) {
    output(false, null, false, "No URL provided");
    process.exit(1);
}

url = url.replace(/^http:\/\//i, "https://");
console.error("[DEBUG]-URL:", url);

// ------------------------------------------------------------
// 4. Platform + architecture detection
// ------------------------------------------------------------
const PLATFORM = process.platform;     // win32, linux, darwin
const ARCH = os.arch();                // x64, arm64, etc.

console.error("[DEBUG]-Platform:", PLATFORM, "Arch:", ARCH);

// ------------------------------------------------------------
// 5. Loader selection
// ------------------------------------------------------------
let chromium = null;
let profileDir = path.join(__dirname, "chrome-profile");
let launchOptions = {
    headless: false,
    viewport: { width: 1280, height: 900 },
    args: [
        '--start-maximized',
        '--disable-blink-features=AutomationControlled'
    ],
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ' +
        'AppleWebKit/537.36 (KHTML, like Gecko) ' +
        'Chrome/120.0.0.0 Safari/537.36'
};

// ============================================================================
// ARM64 NAS — NOT SUPPORTED HERE (Docker wrapper required)
// ============================================================================
if (PLATFORM === "linux" && ARCH === "arm64") {
    console.error("[DEBUG]-Loader: Linux ARM64 detected — use Docker wrapper");

    output(false, null, false,
        "ARM64 requires Docker wrapper (imdb-fetch.js). Unified fetcher cannot run natively."
    );

    process.exit(0);
}

// ============================================================================
// WINDOWS LOADER
// ============================================================================
if (PLATFORM === "win32") {
    console.error("[DEBUG]-Loader: Windows");

    const { createRequire } = await import('module');
    const require = createRequire(import.meta.url);

    // Force portable browser path
    process.env.PLAYWRIGHT_BROWSERS_PATH = path.join(
        __dirname,
        'node_modules',
        'playwright-core',
        '.local-browsers'
    );

    const playwright = require('playwright');
    chromium = playwright.chromium;

    // Windows does NOT need executablePath
}

// ============================================================================
// LINUX / MACOS x86 LOADER
// ============================================================================
else if ((PLATFORM === "linux" || PLATFORM === "darwin") && ARCH === "x64") {
    console.error("[DEBUG]-Loader: Linux/macOS x86");

    const { chromium: chromiumCore } = await import('playwright-core');
    chromium = chromiumCore;

    // Fix NODE_PATH for playwright-core
    process.env.NODE_PATH = path.resolve(__dirname, "node_modules");
    const { Module } = await import('module');
    Module._initPaths();

    // Portable browser folder
    const PLATFORM_DIR = PLATFORM === "darwin" ? "mac" : "linux";
    const BROWSER_DIR = path.resolve(__dirname, `${PLATFORM_DIR}/browsers`);

    let chromiumExecutable;

    if (PLATFORM === "darwin") {
        chromiumExecutable = path.join(
            BROWSER_DIR,
            'chromium-1217',
            'chrome-mac',
            'Chromium.app',
            'Contents',
            'MacOS',
            'Chromium'
        );
    } else {
        chromiumExecutable = path.join(
            BROWSER_DIR,
            'chromium-1217',
            'chrome-linux64',
            'chrome'
        );
    }

    console.error("[DEBUG]-Chromium executable:", chromiumExecutable);

    launchOptions.executablePath = chromiumExecutable;
}

// ============================================================================
// Unsupported platform
// ============================================================================
else {
    output(false, null, false, `Unsupported platform/architecture: ${PLATFORM}/${ARCH}`);
    process.exit(1);
}

// ============================================================================
// MAIN EXECUTION
// ============================================================================
(async () => {
    let browser;

    try {
        console.error("[DEBUG]-Launching persistent context...");

        if (profileDir) {
            browser = await chromium.launchPersistentContext(profileDir, launchOptions);
        } else {
            browser = await chromium.launch(launchOptions);
        }

        const page = await browser.newPage();

        console.error("[DEBUG]-goto:", url);

        try {
            await page.goto(url, { waitUntil: 'networkidle', timeout: 15000 });
        } catch {
            await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 15000 });
        }

        await page.waitForTimeout(2000);
        let html = await page.content();

        await page.waitForTimeout(2000);
        html = await page.content();

        const wafDetected = html.includes("AwsWafIntegration");

        output(true, html, wafDetected, null);

    } catch (err) {
        output(false, null, false, err.message);
    } finally {
        if (browser) await browser.close();
    }
})();
