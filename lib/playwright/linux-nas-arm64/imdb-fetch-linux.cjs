// imdb-fetch-linux.cjs — Linux Playwright Fetcher (Headless, for Docker)

console.error("FETCHER STARTED INSIDE DOCKER:", __filename);

// Ensure Node can resolve modules from the mounted folder
process.env.NODE_PATH = '/app/node_modules';
require('module').Module._initPaths();

const { chromium } = require('playwright-core');

const url = process.argv[2];

function output(ok, html, wafDetected, error) {
    console.log(JSON.stringify({
        ok,
        html,
        wafDetected,
        error
    }));
}

if (!url) {
    output(false, null, false, "No URL provided");
    process.exit(1);
}

(async () => {
    let browser;

    try {
        browser = await chromium.launch({
            headless: true,
            args: [
                '--disable-blink-features=AutomationControlled',
                '--disable-dev-shm-usage',
                '--no-sandbox'
            ]
        });

        const page = await browser.newPage({
            userAgent:
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ' +
                'AppleWebKit/537.36 (KHTML, like Gecko) ' +
                'Chrome/120.0.0.0 Safari/537.36'
        });

        await page.goto(url, { waitUntil: 'domcontentloaded' });

        // Give AWS WAF time to run its JS challenge
        await page.waitForTimeout(3000);

        let html = await page.content();

        // If WAF still present, wait again
        if (html.includes("waf") || html.includes("challenge")) {
            await page.waitForTimeout(3000);
            html = await page.content();
        }

        const wafDetected = html.includes("AwsWafIntegration");

        output(true, html, wafDetected, null);

    } catch (err) {
        output(false, null, false, err.message);
    } finally {
        if (browser) await browser.close();
    }
})();
