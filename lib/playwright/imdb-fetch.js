// imdb-fetch.js — Generic Persistent Headful IMDb Fetcher (Win/Mac/Linux)

import { createRequire } from 'module';
import path from 'path';
import { fileURLToPath } from 'url';

// Resolve script directory (KEEP THIS — only once)
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Create require() for ESM (KEEP THIS — only once)
const require = createRequire(import.meta.url);

// Force portable browser path on Windows
if (process.platform === 'win32') {
    process.env.PLAYWRIGHT_BROWSERS_PATH = path.join(
        __dirname,
        'win',
        'node_modules',
        'playwright-core',
        '.local-browsers'
    );
}

// Map Node platform → your folder names
const platformMap = {
    win32: 'win',
    darwin: 'mac',
    linux: 'linux'
};

// Determine OS folder
const osFolder = platformMap[process.platform];
if (!osFolder) {
    console.log(JSON.stringify({ ok: false, error: "Unsupported OS" }));
    process.exit(1);
}

// Build path to correct node_modules
const nodeModulesPath = path.join(__dirname, osFolder, 'node_modules');

// Inject NODE_PATH for module resolution
process.env.NODE_PATH = nodeModulesPath;
require('module').Module._initPaths();

// Load Playwright
const playwright = require('playwright');
const { chromium } = playwright;

// Input URL
const url = process.argv[2];
if (!url) {
    console.log(JSON.stringify({ ok: false, error: "No URL provided" }));
    process.exit(1);
}

// Persistent profile folder (per OS)
const profileDir = path.join(__dirname, osFolder, 'chrome-profile');

(async () => {
    let browser;

    try {
        browser = await chromium.launchPersistentContext(profileDir, {
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
        });

        const page = await browser.newPage();

        await page.goto(url, { waitUntil: 'domcontentloaded' });

        await page.waitForTimeout(2000);
        let html = await page.content();

        await page.waitForTimeout(2000);
        html = await page.content();

        console.log(JSON.stringify({
            ok: true,
            wafDetected: html.includes("AwsWafIntegration"),
            html
        }));

    } catch (err) {
        console.log(JSON.stringify({
            ok: false,
            error: err.message
        }));
    } finally {
        if (browser) await browser.close();
    }
})();