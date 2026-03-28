// imdb-fetch.js — Generic Persistent Headful IMDb Fetcher (Win/Mac/Linux)

import { createRequire } from 'module';
import path from 'path';
import { fileURLToPath } from 'url';

// ------------------------------------------------------------
// 1. Resolve script directory (ESM-safe __dirname / __filename)
// ------------------------------------------------------------
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ------------------------------------------------------------
// 2. Create require() for ESM
// ------------------------------------------------------------
const require = createRequire(import.meta.url);

// ------------------------------------------------------------
// 3. Force portable browser path on Windows ONLY
// ------------------------------------------------------------
if (process.platform === 'win32') {
    process.env.PLAYWRIGHT_BROWSERS_PATH = path.join(
        __dirname,
        'win',
        'node_modules',
        'playwright-core',
        '.local-browsers'
    );
}

// ------------------------------------------------------------
// 4. OS folder mapping
// ------------------------------------------------------------
const platformMap = {
    win32: 'win',
    darwin: 'mac',
    linux: 'linux'
};

const osFolder = platformMap[process.platform];
if (!osFolder) {
    console.log(JSON.stringify({ ok: false, error: "Unsupported OS" }));
    process.exit(1);
}

// ------------------------------------------------------------
// 5. Inject NODE_PATH for module resolution
// ------------------------------------------------------------
const nodeModulesPath = path.join(__dirname, osFolder, 'node_modules');
process.env.NODE_PATH = nodeModulesPath;
require('module').Module._initPaths();

// ------------------------------------------------------------
// 6. Load Playwright
// ------------------------------------------------------------
const playwright = require('playwright');
const { chromium } = playwright;

// ------------------------------------------------------------
// 7. Input URL
// ------------------------------------------------------------
const url = process.argv[2];
if (!url) {
    console.log(JSON.stringify({ ok: false, error: "No URL provided" }));
    process.exit(1);
}

// ------------------------------------------------------------
// 8. Persistent profile folder
// ------------------------------------------------------------
const profileDir = path.join(__dirname, osFolder, 'chrome-profile');

// ------------------------------------------------------------
// 9. Main execution
// ------------------------------------------------------------
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