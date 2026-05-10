// imdb-fetch-linux-nas-headless.cjs — ARM64‑Optimized Linux Playwright Fetcher (Headless, for Docker)

console.error("FETCHER STARTED INSIDE DOCKER:", __filename);

process.env.NODE_PATH = '/app/node_modules';
require('module').Module._initPaths();

const { chromium } = require('playwright-core');
const { performance } = require('node:perf_hooks');

const url = process.argv[2];
console.error("[DEBUG]-url:", url);

function output(ok, html, wafDetected, error) {
    console.log(JSON.stringify({ ok, html, wafDetected, error }));
}

if (!url) {
    output(false, null, false, "No URL provided");
    process.exit(1);
}

(async () => {
    const scriptStart = performance.now();
    let browser;

    try {
        // Browser Launch Timing
        const launchStart = performance.now();
        browser = await chromium.launch({
            headless: true,
            args: [
                '--disable-blink-features=AutomationControlled',
                '--disable-dev-shm-usage',
                '--no-sandbox'
            ]
        });
        console.error("[TIMING] Browser launch:", ( performance.now() - launchStart).toFixed(2), "ms");

        // Context Creation Timing
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
        console.error("[TIMING] Context + page creation:", ( performance.now() - contextStart).toFixed(2), "ms");

        // Navigation + Retry Timing
        let lastError = null;

        for (let attempt = 1; attempt <= 3; attempt++) {
            try {
                console.error(`[TIMING] goto() attempt ${attempt} started`);
                const gotoStart = performance.now();

                await page.goto(url, {
                    timeout: 90000,
                    waitUntil: 'domcontentloaded'
                });

                console.error(`[TIMING] goto() attempt ${attempt} duration:`, ( performance.now() - gotoStart).toFixed(2), "ms");
                break;

            } catch (err) {
                console.error(`[TIMING] goto() attempt ${attempt} FAILED after`, ( performance.now() - gotoStart).toFixed(2), "ms");

                lastError = err;
                if (attempt === 3) throw err;

                await page.waitForTimeout(2000);
            }
        }

        // WAF Wait #1
        console.error("[TIMING] WAF wait #1 started");
        const wafStart1 = performance.now();
        await page.waitForTimeout(5000);
        console.error("[TIMING] WAF wait #1 duration:", ( performance.now() - wafStart1).toFixed(2), "ms");

        // Content Extraction #1
        const contentStart1 = performance.now();
        let html = await page.content();
        console.error("[TIMING] page.content() #1:", ( performance.now() - contentStart1).toFixed(2), "ms");

        // WAF Wait #2 (conditional)
        if (html.includes("waf") || html.includes("challenge")) {
            console.error("[TIMING] WAF wait #2 started (WAF detected)");
            const wafStart2 = performance.now();
            await page.waitForTimeout(5000);
            console.error("[TIMING] WAF wait #2 duration:", ( performance.now() - wafStart2).toFixed(2), "ms");

            const contentStart2 = performance.now();
            html = await page.content();
            console.error("[TIMING] page.content() #2:", ( performance.now() - contentStart2).toFixed(2), "ms");
        }

        const wafDetected = html.includes("AwsWafIntegration");

        // Total Runtime
        console.error("[TIMING] TOTAL fetcher runtime:", ( performance.now() - scriptStart).toFixed(2), "ms");

        output(true, html, wafDetected, null);

    } catch (err) {
        console.error("[TIMING] TOTAL fetcher runtime (FAILED):", ( performance.now() - scriptStart).toFixed(2), "ms");

        output(false, null, false, err.message || String(err));

    } finally {
        if (browser) await browser.close();
    }
})();
