// imdb-fetch-win.mjs — Windows-Only Persistent Headful IMDb Fetcher
// Clean, ESM-native, no warnings, stable JSON schema

import { createRequire } from 'module';
import path from 'path';
import { fileURLToPath } from 'url';

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
    console.log(JSON.stringify({
        ok,
        html,
        wafDetected,
        error
    }));
}

// ------------------------------------------------------------
// 3. Create require() for ESM
// ------------------------------------------------------------
const require = createRequire(import.meta.url);

// ------------------------------------------------------------
// 4. Force portable browser path (Windows-only)
// ------------------------------------------------------------
process.env.PLAYWRIGHT_BROWSERS_PATH = path.join(
    __dirname,
    'node_modules',
    'playwright-core',
    '.local-browsers'
);

// ------------------------------------------------------------
// 5. Load Playwright (Windows-only)
// ------------------------------------------------------------
const playwright = require('playwright');
const { chromium } = playwright;

// ------------------------------------------------------------
// 6. Input URL
// ------------------------------------------------------------
const url = process.argv[2];
console.error("[DEBUG]-Received url:", url);

if (!url) {
    output(false, null, false, "No URL provided");
    process.exit(1);
}

// ------------------------------------------------------------
// 7. Persistent profile folder (Windows-only)
// ------------------------------------------------------------
const profileDir = path.join(__dirname, 'chrome-profile');

// ------------------------------------------------------------
// 8. Main execution
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

        // Improved navigation reliability
        try {
            console.error("[DEBUG]-try: page.goto(url, networkidle)");
            await page.goto(url, { waitUntil: 'networkidle', timeout: 15000 });
        } catch {
            console.error("[DEBUG]-catch: page.goto(url, domcontentloaded)");
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