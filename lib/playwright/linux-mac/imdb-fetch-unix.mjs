#!/usr/bin/env node

// ============================================================================
// imdb-fetch-unix.mjs — Unified Linux/macOS Fetcher (wrapper + Playwright)
// - Single process
// - Same logic/timing/output as old .mjs + .cjs combo
// ============================================================================

import os from 'os';
import path from 'path';
import { fileURLToPath } from 'url';
import process from 'process';
import { Module } from 'module';
import { chromium } from 'playwright-core';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.error("[DEBUG]-WRAPPER/FETCHER LOADED:", __filename);

// Detect current user
const USER = process.env.USER || os.userInfo().username;

// Detect OS → choose correct browser folder
const PLATFORM = process.platform === "darwin" ? "mac" : "linux";
console.error("[DEBUG]-Detected platform:", PLATFORM);

// URL argument
let url = process.argv[2];
console.error("[DEBUG]-Received url:", url);

if (!url) {
  console.log(JSON.stringify({ ok: false, html: null, wafDetected: false, error: "No URL provided" }));
  process.exit(1);
}

// Force HTTPS
url = url.replace(/^http:\/\//i, "https://");
console.error("[DEBUG]-Amended url:", url);

// Shared node_modules (linux-mac/node_modules)
const NODE_PATH_DIR = path.resolve(__dirname, "node_modules");

// OS-specific browser folder
const BROWSER_DIR = path.resolve(__dirname, `${PLATFORM}/browsers`);
console.error("[DEBUG]-Browser path:", BROWSER_DIR);

// Build the actual Chromium executable path
const chromiumExecutable = path.join(
  BROWSER_DIR,
  'chromium-1217',
  'chrome-linux64',
  'chrome'
);

console.error("[DEBUG]-Chromium executable:", chromiumExecutable);

// Apply environment similar to old wrapper
process.env.DISPLAY = process.env.DISPLAY || ":0";
process.env.XAUTHORITY = process.env.XAUTHORITY || `/home/${USER}/.Xauthority`;
process.env.DBUS_SESSION_BUS_ADDRESS =
  process.env.DBUS_SESSION_BUS_ADDRESS || `unix:path=/run/user/${process.getuid()}/bus`;

// Remove XAMPP poisoning
process.env.LD_LIBRARY_PATH = "";

// Correct Playwright paths
process.env.NODE_PATH = NODE_PATH_DIR;
process.env.PLAYWRIGHT_BROWSERS_PATH = BROWSER_DIR;

// Re-init module paths so NODE_PATH is honored
Module._initPaths();

// Helper to output JSON in the original fetcher format
function output(ok, html, wafDetected, error) {
  console.log(JSON.stringify({
    ok,
    html,
    wafDetected,
    error
  }));
}

(async () => {
  let browser;

  try {
    console.error("FETCHER STARTED (unified):", __filename);

    browser = await chromium.launch({
      headless: false,
      executablePath: chromiumExecutable,
      args: [
        '--start-maximized',
        '--disable-blink-features=AutomationControlled',
        '--no-sandbox'
      ]
    });

    const page = await browser.newPage({
      userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ' +
        'AppleWebKit/537.36 (KHTML, like Gecko) ' +
        'Chrome/120.0.0.0 Safari/537.36'
    });

    console.error("[DEBUG]-goto:", url);

    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 15000 });

    // Give AWS WAF time to run its JS challenge
    await page.waitForTimeout(6000);

    let html = await page.content();

    if (html.includes("AwsWafIntegration") || html.includes("challenge")) {
      await page.waitForTimeout(3000);
      html = await page.content();
    }

    const wafDetected = html.includes("AwsWafIntegration");

    output(true, html, wafDetected, null);

  } catch (err) {
    output(false, null, false, err.message);
  } finally {
    if (browser) {
      await browser.close();
    }
  }
})();
