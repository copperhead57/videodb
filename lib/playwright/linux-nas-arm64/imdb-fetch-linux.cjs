// imdb-fetch-linux.cjs — ARM64‑Optimized Linux Playwright Fetcher (Headless, for Docker)

console.error("FETCHER STARTED INSIDE DOCKER:", __filename);

// Ensure Node can resolve modules from the mounted folder
process.env.NODE_PATH = '/app/node_modules';
require('module').Module._initPaths();

const { chromium } = require('playwright-core');

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
    const scriptStart = Date.now();
    let browser;

    try {
        // -------------------------
        // Browser Launch Timing
        // -------------------------
        const launchStart = Date.now();
        browser = await chromium.launch({
            headless: true,
            args: [
                '--disable-blink-features=AutomationControlled',
                '--disable-dev-shm-usage',
                '--no-sandbox'
            ]
        });
        const launchEnd = Date.now();
        console.error("[TIMING] Browser launch:", (launchEnd - launchStart), "ms");

        // -------------------------
        // Context Creation Timing
        // -------------------------
        const contextStart = Date.now();
        const context = await browser.newContext({
            userAgent:
                'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123 Safari/537.36',
            locale: 'en-US',
            extraHTTPHeaders: {
                'Accept-Language': 'en-US,en;q=0.9'
            }
        });

        await context.addInitScript(() => {
            Object.defineProperty(navigator, 'webdriver', { get: () => false });
        });

        const page = await context.newPage();
        const contextEnd = Date.now();
        console.error("[TIMING] Context + page creation:", (contextEnd - contextStart), "ms");

        // -------------------------
        // Navigation + Retry Timing
        // -------------------------
        let lastError = null;
        let gotoStart, gotoEnd;

        for (let attempt = 1; attempt <= 3; attempt++) {
            try {
                console.error(`[TIMING] goto() attempt ${attempt} started`);
                gotoStart = Date.now();

                await page.goto(url, {
                    timeout: 90000,
                    waitUntil: 'domcontentloaded'
                });

                gotoEnd = Date.now();
                console.error(`[TIMING] goto() attempt ${attempt} duration:`, (gotoEnd - gotoStart), "ms");
                break;

            } catch (err) {
                gotoEnd = Date.now();
                console.error(`[TIMING] goto() attempt ${attempt} FAILED after`, (gotoEnd - gotoStart), "ms");

                lastError = err;
                if (attempt === 3) throw err;

                await page.waitForTimeout(2000);
            }
        }

        // -------------------------
        // WAF Wait #1 Timing
        // -------------------------
        const wafStart1 = Date.now();
        console.error("[TIMING] WAF wait #1 started");
        await page.waitForTimeout(5000);
        const wafEnd1 = Date.now();
        console.error("[TIMING] WAF wait #1 duration:", (wafEnd1 - wafStart1), "ms");

        // -------------------------
        // Content Extraction Timing #1
        // -------------------------
        const contentStart1 = Date.now();
        let html = await page.content();
        const contentEnd1 = Date.now();
        console.error("[TIMING] page.content() #1:", (contentEnd1 - contentStart1), "ms");

        // -------------------------
        // WAF Wait #2 Timing (conditional)
        // -------------------------
        if (html.includes("waf") || html.includes("challenge")) {
            const wafStart2 = Date.now();
            console.error("[TIMING] WAF wait #2 started (WAF detected)");
            await page.waitForTimeout(5000);
            const wafEnd2 = Date.now();
            console.error("[TIMING] WAF wait #2 duration:", (wafEnd2 - wafStart2), "ms");

            // -------------------------
            // Content Extraction Timing #2
            // -------------------------
            const contentStart2 = Date.now();
            html = await page.content();
            const contentEnd2 = Date.now();
            console.error("[TIMING] page.content() #2:", (contentEnd2 - contentStart2), "ms");
        }

        const wafDetected = html.includes("AwsWafIntegration");

        // -------------------------
        // Total Script Runtime
        // -------------------------
        const scriptEnd = Date.now();
        console.error("[TIMING] TOTAL fetcher runtime:", (scriptEnd - scriptStart), "ms");

        output(true, html, wafDetected, null);

    } catch (err) {
        const scriptEnd = Date.now();
        console.error("[TIMING] TOTAL fetcher runtime (FAILED):", (scriptEnd - scriptStart), "ms");

        output(false, null, false, err.message || String(err));

    } finally {
        if (browser) await browser.close();
    }
})();
