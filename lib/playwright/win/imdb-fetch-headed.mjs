// imdb-fetch-headed.mjs — Windows-Only Persistent Headful IMDb Fetcher

import { createRequire } from 'module';
import path from 'path';
import { fileURLToPath } from 'url';

// 1. Resolve script directory
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.error("[DEBUG] Fetcher LOADED:", __filename);

// 2. Stable JSON output helper
function output(ok, html, wafDetected, error) {
    console.log(JSON.stringify({ ok, html, wafDetected, error }));
}

// 3. require() for ESM
const require = createRequire(import.meta.url);

// 4. Force portable browser path
process.env.PLAYWRIGHT_BROWSERS_PATH = path.join(
    __dirname,
    "node_modules",
    "playwright-core",
    ".local-browsers"
);

// 5. Load Playwright
const t0 = performance.now();
console.error("[TIMING-0] Script start");

const playwright = require("playwright");
const { chromium } = playwright;

console.error("[TIMING-1] Playwright loaded in", (performance.now() - t0).toFixed(1), "ms");

// 6. Input URL
const url = process.argv[2];
console.error("[DEBUG] URL:", url);

if (!url) {
    output(false, null, false, "No URL provided");
    process.exit(1);
}

// 7. Persistent profile folder
const profileDir = path.join(__dirname, "chrome-profile");

// 8. Main execution
(async () => {
    let browser;

    try {
        console.error("[DEBUG] Launching persistent context…");

        const t2_start = performance.now();
        browser = await chromium.launchPersistentContext(profileDir, {
            headless: false,
            viewport: { width: 1280, height: 900 },
            args: [
                "--start-maximized",
                "--disable-blink-features=AutomationControlled"
            ],
            userAgent:
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) " +
                "AppleWebKit/537.36 (KHTML, like Gecko) " +
                "Chrome/120.0.0.0 Safari/537.36"
        });

        console.error("[TIMING-2] Browser launched in", (performance.now() - t2_start).toFixed(1), "ms");

        const t3_start = performance.now();
        const page = await browser.newPage();
        console.error("[TIMING-3] newPage() in", (performance.now() - t3_start).toFixed(1), "ms");

        // Navigation with retry
        let t4_start = performance.now();
        console.error("[DEBUG] goto(networkidle) start");

        try {
            await page.goto(url, { waitUntil: "networkidle", timeout: 15000 });
            console.error("[TIMING-4] goto(networkidle) OK in", (performance.now() - t4_start).toFixed(1), "ms");
        } catch {
            console.error("[TIMING-4] goto(networkidle) FAILED in", (performance.now() - t4_start).toFixed(1), "ms");
            
            console.error("[DEBUG] goto(networkidle) FAILED, retrying…");

            let t5_start = performance.now();
            await page.goto(url, { waitUntil: "domcontentloaded", timeout: 15000 });
            console.error("[TIMING-5] goto(domcontentloaded) OK in", (performance.now() - t5_start).toFixed(1), "ms");
        }

         // HTML extraction (double-read)
        await page.waitForTimeout(2000);
        const t6_start = performance.now();
        let html = await page.content();

        console.error("[TIMING-6] First HTML read in", (performance.now() - t6_start).toFixed(1), "ms");

        await page.waitForTimeout(2000);
        const t7_start = performance.now();
        html = await page.content();
 
        console.error("[TIMING-7] Second HTML read in", (performance.now() - t7_start).toFixed(1), "ms");

        const wafDetected = html.includes("AwsWafIntegration");

        console.error("[TIMING-8] Total runtime:", (performance.now() - t0).toFixed(1), "ms");

        output(true, html, wafDetected, null);

    } catch (err) {
        output(false, null, false, err.message);
    } finally {
        if (browser) await browser.close();
    }
})();
