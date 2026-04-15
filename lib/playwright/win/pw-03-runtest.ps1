param(
    [string]$url = "https://example.com"
)

Write-Host "Launching Chromium for test..."
Write-Host "URL: $url"

.\node.exe -e "
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  // When the user closes the browser window, exit Node
  page.on('close', () => {
    process.exit(0);
  });

  await page.goto('$url');
})();
"