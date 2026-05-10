# Playwright NAS Setup (Docker‑Based, ARM64 & x86 Compatible)

This subsystem runs Playwright inside Docker, not on the NAS OS.  
The NAS only runs a lightweight Node.js wrapper that launches the container.

This implementation uses headless Chromium inside Docker.  
Stable on Synology ARM64 and expected to work on all x86 NAS models.

Works on:
- Synology DSM 7.x (ARM64 & x86)
- QNAP (ARM64 & x86)
- TrueNAS SCALE
- UnRAID
- Any Linux NAS with Docker support

Playwright browsers live inside Docker.  
Your NAS only stores the Node.js library + wrapper scripts.

Testing Status  
Fully tested on Synology ARM64.  
Expected to work on x86 NAS models and other NAS platforms.

------------------------------------------------------------
1. Requirements
------------------------------------------------------------

- Docker installed on the NAS
- Node.js installed
- SSH access (recommended)
- Playwright Docker image (v<version>-jammy)
- Local Playwright Node.js library (installed via pw‑02‑install.sh)

Supported architectures:

| Architecture | Supported | Notes |
|-------------|-----------|-------|
| ARM64       | ✔️ Yes    | Fully tested |
| x86_64      | ✔️ Yes    | Expected to work |

------------------------------------------------------------
2. NAS Script Workflow (Preferred Method)
------------------------------------------------------------

ssh <user>@<NAS-IP>
cd /volume1/web/<yourProject>/lib/playwright/linux-nas-arm64

pw-01-verify.sh  
    Checks Node, npm, Docker, Playwright, folder structure, socket permissions.

pw-02-install.sh  
    Installs the latest Playwright version (auto-detected from npm)  
    and pulls the matching Docker image (v<version>-jammy).

pw-03-runtest.sh  
    Runs a real IMDb fetch to confirm everything works.

pw-04-install-docker-socket-fix.sh  
    Installs the Docker socket permission fix (required on Synology DSM).  
    On Synology: prints Task Scheduler instructions.  
    On other NAS: installs an rc/init script automatically.

Reboot NAS

pw-01-verify.sh  
    Confirms Docker socket permissions are correct (666) and the fix is active.

------------------------------------------------------------
3. Folder Structure (Generic NAS)
------------------------------------------------------------

videodb/
  lib/
    playwright/
      linux-nas-arm64/
        imdb-fetch-linux-nas-headless.js
        imdb-fetch-linux-nas-headless.cjs
        pw-01-verify.sh
        pw-02-install.sh
        pw-03-runtest.sh
        pw-04-install-docker-socket-fix.sh
        package.json
        node_modules/   ← Playwright installed here (version-aware)

------------------------------------------------------------
4. Manual Install (If Script Workflow Not Used)
------------------------------------------------------------

cd /volume1/web/<yourProject>/lib/playwright/linux-nas-arm64
rm -rf node_modules package-lock.json
npm install playwright@<version>

Installs:
- playwright-core@<version>
- playwright@<version>

These modules are mounted into Docker at /app/node_modules.

------------------------------------------------------------
5. Download the Playwright Docker Image (Jammy)
------------------------------------------------------------

docker pull mcr.microsoft.com/playwright:v<version>-jammy

Verify:

docker images | grep playwright

Expected:

mcr.microsoft.com/playwright   v<version>-jammy   <image-id>

------------------------------------------------------------
6. How It Works
------------------------------------------------------------

6.1 NAS wrapper (runs on the NAS OS)

node imdb-fetch-linux-nas-headless.js "<IMDb URL>"

6.2 Wrapper launches Docker

docker run --rm \
  --shm-size=1gb \
  -v <projectRoot>:/app \
  mcr.microsoft.com/playwright:v<version>-jammy \
  node /app/lib/playwright/linux-nas-arm64/imdb-fetch-linux-nas-headless.cjs "<URL>"

6.3 Inside Docker:

- Node loads playwright-core from /app/node_modules
- Chromium launches headless
- IMDb page is fetched
- WAF detection runs
- HTML returned as JSON

This approach is stateless, portable, and requires no persistent container.

------------------------------------------------------------
7. Wrapper (imdb-fetch-linux-nas-headless.js) — ESM
------------------------------------------------------------

- Dynamically resolves project root
- Converts fetcher path to POSIX for Docker
- Uses execSync to run the container
- No hardcoded folder names
- Works on ARM64 and x86 NAS models

------------------------------------------------------------
8. Linux Fetcher (imdb-fetch-linux-nas-headless.cjs) — CommonJS
------------------------------------------------------------

- Ensures NODE_PATH points to /app/node_modules
- Loads playwright-core
- Launches Chromium headless
- Performs WAF wait + retry
- Returns JSON
- Uses high‑precision performance.now() timing

------------------------------------------------------------
9. Manual Test (Optional)
------------------------------------------------------------

cd /volume1/web/<yourProject>/lib/playwright/linux-nas-arm64
node imdb-fetch-linux-nas-headless.js "http://www.imdb.com"

Expected:

WRAPPER LOADED: /volume1/web/<yourProject>/lib/playwright/linux-nas-arm64/imdb-fetch-linux-nas-headless.js  
Received url: http://www.imdb.com  
Amended url: https://www.imdb.com  
hostFetcher: /volume1/web/<yourProject>/lib/playwright/linux-nas-arm64/imdb-fetch-linux-nas-headless.cjs  
projectRoot: /volume1/web  
containerFetcher: /app/<yourProject>/lib/playwright/linux-nas-arm64/imdb-fetch-linux-nas-headless.cjs  
EXEC CMD: docker run --rm --shm-size=1gb -v /volume1/web:/app mcr.microsoft.com/playwright:v<version>-jammy node "/app/<yourProject>/lib/playwright/linux-nas-arm64/imdb-fetch-linux-nas-headless.cjs" "https://www.imdb.com"  
FETCHER STARTED INSIDE DOCKER: /app/<yourProject>/lib/playwright/linux-nas-arm64/imdb-fetch-linux-nas-headless.cjs  
{ ok: true, wafDetected: false, html: "<!DOCTYPE html>..." }

------------------------------------------------------------
10. Docker Socket Permission Fix (Required on Synology DSM)
------------------------------------------------------------

Synology DSM resets Docker socket permissions on reboot:

/var/run/docker.sock  
→ becomes owned by root:docker  
→ not readable by Node/PHP  
→ Playwright Docker calls fail silently

Run the installer:

cd /volume1/web/<yourProject>/lib/playwright/linux-nas-arm64  
sh pw-04-install-docker-socket-fix.sh

The installer will:

- Detect Synology DSM
- Print Task Scheduler instructions
- Provide the exact script to paste
- OR install an rc/init script on other NAS platforms

After installing the fix, reboot and run:

pw-01-verify.sh

Expected:

✔ Docker socket permissions OK  
✔ Playwright Docker ready

------------------------------------------------------------
11. Architecture Notes
------------------------------------------------------------

ARM64 NAS (Synology, QNAP, TrueNAS SCALE ARM)  
✔ Fully supported  
✔ Playwright Docker image includes ARM64 Chromium  

x86 NAS (Synology Plus, QNAP x86, UnRAID, TrueNAS SCALE)  
✔ Expected to work  
⚠️ Not yet tested  
✔ Same Docker image and scripts apply
