// imdb-fetch-linux-headless.mjs — Full Chromium, no persistent profile (working version)

import { fileURLToPath } from "url";
import { dirname } from "path";
import { chromium } from "playwright-core";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

console.error("FETCHER STARTED:", __filename);

// Force system-install mode (this is what worked earlier)
process.env.PLAYWRIGHT_BROWSERS_PATH = "0";

// Chromium path provided by wrapper
const CHROMIUM_PATH = process.env.PW_CHROMIUM_PATH;
if (!CHROMIUM_PATH) {
    console.error("ERROR: PW_CHROMIUM_PATH not set");
    process.exit(1);
}

const urlArg = process.argv[2];
console.error("[DEBUG]-url:", urlArg);

function output(ok, html, wafDetected, error) {
    console.log(JSON.stringify({ ok, html, wafDetected, error }));
}

if (!urlArg) {
    output(false, null, false, "No URL provided");
    process.exit(1);
}

(async () => {
    const scriptStart = performance.now();
    let browser;

    try {
        // Browser Launch (full Chromium)
        const launchStart = performance.now();
        browser = await chromium.launch({
            headless: true,
            executablePath: CHROMIUM_PATH,
            args: [
                '--disable-blink-features=AutomationControlled',
                '--disable-dev-shm-usage',
                '--no-sandbox'
            ]
        });
        console.error("[TIMING] Browser launch:", performance.now() - launchStart, "ms");

        // Context + Page
        const contextStart = performance.now();
        const context = await browser.newContext({
            userAgent:
                'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123 Safari/537.36',
            locale: 'en-US',
            extraHTTPHeaders: { 'Accept-Language': 'en-US,en;q=0.9' }
        });

        await context.addInitScript(() => {
            Object.defineProperty(navigator, 'webdriver', { get: () => false });
        });

        const page = await context.newPage();
        console.error("[TIMING] Context + page creation:", performance.now() - contextStart, "ms");

        // -------------------------
        // Navigation + Retry
        // -------------------------
        let html = "";
        for (let attempt = 1; attempt <= 3; attempt++) {
            try {
                console.error(`[TIMING] goto() attempt ${attempt} started`);
                const start = performance.now();

                await page.goto(urlArg, {
                    timeout: 90000,
                    waitUntil: 'domcontentloaded'
                });

                console.error(`[TIMING] goto() attempt ${attempt} duration:`, performance.now() - start, "ms");
                break;

            } catch (err) {
                console.error(`[TIMING] goto() attempt ${attempt} FAILED`);
                if (attempt === 3) throw err;
                await page.waitForTimeout(2000);
            }
        }

        // -------------------------
        // WAF Wait #1
        // -------------------------
        console.error("[TIMING] WAF wait #1 started");
        await page.waitForTimeout(5000);

        // First content extraction
        html = await page.content();
        console.error("[TIMING] page.content() #1");

        // -------------------------
        // WAF Wait #2 (conditional)
        // -------------------------
        if (html.includes("challenge") || html.includes("waf")) {
            console.error("[TIMING] WAF wait #2 started");
            await page.waitForTimeout(5000);
            html = await page.content();
            console.error("[TIMING] page.content() #2");
        }

        const wafDetected = html.includes("AwsWafIntegration");

        console.error("[TIMING] TOTAL fetcher runtime:", performance.now() - scriptStart, "ms");

        output(true, html, wafDetected, null);

    } catch (err) {
        console.error("[TIMING] TOTAL fetcher runtime (FAILED):", performance.now() - scriptStart, "ms");
        output(false, null, false, err.message || String(err));

    } finally {
        if (browser) await browser.close();
    }
})();
