#!/usr/bin/env node

// ============================================================================
// imdb-fetch-unix.mjs — Linux/macOS Persistent Headful Fetcher
// Unified with Windows architecture (launchPersistentContext)
// ============================================================================

import path from 'path';
import { fileURLToPath } from 'url';
import process from 'process';
import { Module } from 'module';
import { chromium } from 'playwright-core';

// Resolve script directory
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.error("[DEBUG]-Fetcher LOADED:", __filename);

// Output helper
function output(ok, html, wafDetected, error) {
  console.log(JSON.stringify({ ok, html, wafDetected, error }));
}

// URL
let url = process.argv[2];
if (!url) {
  output(false, null, false, "No URL provided");
  process.exit(1);
}

url = url.replace(/^http:\/\//i, "https://");
console.error("[DEBUG]-URL:", url);

// Detect platform
const PLATFORM = process.platform === "darwin" ? "mac" : "linux";
const BROWSER_DIR = path.resolve(__dirname, `${PLATFORM}/browsers`);

// Chromium executable path (Linux vs macOS)
let chromiumExecutable;

if (process.platform === "darwin") {
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

// Persistent profile folder (Linux/mac)
const profileDir = path.join(__dirname, 'chrome-profile');
console.error("[DEBUG]-Profile dir:", profileDir);

// Ensure NODE_PATH for playwright-core
process.env.NODE_PATH = path.resolve(__dirname, "node_modules");
Module._initPaths();

// Main
(async () => {
  let browser;

  try {
    console.error("[DEBUG]-Launching persistent context...");

    browser = await chromium.launchPersistentContext(profileDir, {
      headless: false,
      executablePath: chromiumExecutable,
      viewport: { width: 1280, height: 900 },
      args: [
        '--start-maximized',
        '--disable-blink-features=AutomationControlled',
        '--no-sandbox'
      ],
      userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ' +
        'AppleWebKit/537.36 (KHTML, like Gecko) ' +
        'Chrome/120.0.0.0 Safari/537.36'
    });

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
