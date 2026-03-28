# Synology NAS Playwright Setup (v1.58.x)
For Synology DSM 7.x — using Docker + Playwright 1.58.2 (Jammy)

This subsystem runs Playwright **inside Docker**, not on the NAS.
Synology only runs a lightweight Node.js wrapper that launches the container.

Playwright 1.58.x requires:
- Docker image: mcr.microsoft.com/playwright:v1.58.2-jammy
- Local Node.js library: playwright@1.58.2
- Linux fetcher: CommonJS (.cjs)
- Wrapper: ESM (.js)

Everything is aligned with your Windows environment.

------------------------------------------------------------
1. Requirements
------------------------------------------------------------

- DSM 7.x
- Docker installed from Package Center
- Node.js installed from Package Center
- SSH access (recommended)
- Playwright Docker image (Jammy)
- Local Playwright Node.js library (v1.58.x)

Playwright browsers live **inside Docker**.
Synology only stores the Node.js library + wrapper scripts.

------------------------------------------------------------
2. Install Playwright Node.js Library (v1.58.x)
------------------------------------------------------------

cd /volume1/web/videodb-devcode/lib/playwright/synology
rm -rf node_modules package-lock.json
npm install playwright@1.58.2

This installs:
- playwright-core@1.58.2
- playwright@1.58.2

These modules are mounted into Docker at /app/node_modules.

------------------------------------------------------------
3. Download the Playwright Docker Image (Jammy)
------------------------------------------------------------

ssh youruser@NAS_IP

docker pull mcr.microsoft.com/playwright:v1.58.2-jammy

Verify:

docker images | grep playwright

Expected:

mcr.microsoft.com/playwright   v1.58.2-jammy   <image-id>

------------------------------------------------------------
4. Folder Structure (Updated for v1.58)
------------------------------------------------------------

videodb/
  lib/
    playwright/
      synology/
        imdb-fetch.js              ← Synology wrapper (ESM)
        imdb-fetch-linux.cjs       ← Linux fetcher (CommonJS)
        pw-01-verify.sh            ← Verify environment
        pw-02-install.sh           ← Install dependencies
        pw-03-runtest.sh           ← Run test fetch
        package.json               ← Contains "type": "module"
        node_modules/              ← Playwright 1.58.x installed here

------------------------------------------------------------
5. How It Works
------------------------------------------------------------

5.1 PHP calls the Synology wrapper:

node imdb-fetch.js "<IMDb URL>"

5.2 Wrapper builds and executes Docker command:

docker run --rm \
  --shm-size=1gb \
  -v /volume1/web/videodb-devcode:/app \
  mcr.microsoft.com/playwright:v1.58.2-jammy \
  node /app/lib/playwright/synology/imdb-fetch-linux.cjs "<URL>"

5.3 Inside Docker:

- Node loads playwright-core from /app/node_modules
- Chromium (v1.58) launches headless
- IMDb page is fetched
- WAF detection runs
- HTML returned as JSON

------------------------------------------------------------
6. Wrapper (imdb-fetch.js) — ESM
------------------------------------------------------------

- Uses import syntax
- Uses execSync with increased buffer
- Calls Docker with correct Jammy image
- Passes URL to Linux fetcher

------------------------------------------------------------
7. Linux Fetcher (imdb-fetch-linux.cjs) — CommonJS
------------------------------------------------------------

- Uses require()
- Sets NODE_PATH to /app/node_modules
- Launches Chromium via playwright-core
- Performs WAF wait + retry
- Returns JSON

------------------------------------------------------------
8. Running Manually (Test)
------------------------------------------------------------

cd /volume1/web/videodb-devcode/lib/playwright/synology

node imdb-fetch.js "https://www.imdb.com/title/tt0111161/"

Expected:

{ ok: true, wafDetected: false, html: "<!DOCTYPE html>..." }

------------------------------------------------------------
9. Synology Script Workflow (No Clean Script)
------------------------------------------------------------

Synology mirrors Windows with a simple, predictable workflow:

pw-01-verify.sh  
    Checks Node, npm, Docker, Playwright, folder structure.

pw-02-install.sh  
    Installs Playwright 1.58.2 + pulls Docker image.

pw-03-runtest.sh  
    Runs a real IMDb fetch to confirm everything works.

There is **no clean script** on Synology because:
- Browsers live inside Docker
- The Docker image should not be mutated
- node_modules must remain intact
- The environment must stay runnable

This keeps Synology stable, deterministic, and contributor-friendly.

------------------------------------------------------------
10. Version Strategy
------------------------------------------------------------

Windows and Synology now run:
- Playwright 1.58.x
- Chromium 1.58.x
- Identical behaviour across platforms

This ensures deterministic:
- HTML output
- WAF behaviour
- Timing
- API behaviour
- Fingerprinting