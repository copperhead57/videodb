# Playwright NAS Setup (Docker‑Based, ARM64 & x86 Compatible)

This subsystem runs **Playwright inside Docker**, not on the NAS OS.  
The NAS only runs a lightweight Node.js wrapper that launches the container.

This implementation can be flakey as it uses **headless** rather than **headful** calls to IMDb.

Works on:
- Synology DSM 7.x (ARM64 & x86)
- QNAP (ARM64 & x86)
- TrueNAS SCALE
- UnRAID
- Any Linux NAS with Docker support

Playwright browsers live **inside Docker**.  
Your NAS only stores the Node.js library + wrapper scripts.

⚠️ Testing Status  
Fully tested on **Synology ARM64**.  
Expected to work on x86 NAS models and other NAS platforms.

------------------------------------------------------------
1. Requirements
------------------------------------------------------------

- Docker installed on the NAS  
- Node.js installed  
- SSH access (recommended)  
- Playwright Docker image (Jammy)  
- Local Playwright Node.js library (v1.58.x recommended)

Supported architectures:

| Architecture | Supported | Notes |
|-------------|-----------|-------|
| ARM64       | ✔️ Yes    | Fully tested |
| x86_64      | ✔️ Yes    | Expected to work |

------------------------------------------------------------
2. NAS Script Workflow (Preferred Method)
------------------------------------------------------------

pw-01-verify.sh  
    Checks Node, npm, Docker, Playwright, folder structure, socket permissions.

pw-02-install.sh  
    Installs Playwright 1.58.2 + pulls Docker image.

pw-03-runtest.sh  
    Runs a real IMDb fetch to confirm everything works.

pw-04-install-docker-socket-fix.sh  
    Installs the **Docker socket permission fix** (required on Synology DSM).  
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
        imdb-fetch.js              ← NAS wrapper (ESM)
        imdb-fetch-linux.cjs       ← Linux fetcher (CommonJS)
        pw-01-verify.sh
        pw-02-install.sh
        pw-03-runtest.sh
        pw-04-install-docker-socket-fix.sh
        package.json               ← Contains "type": "module"
        node_modules/              ← Playwright 1.58.x installed here

------------------------------------------------------------
4. Manual Install (If Script Workflow Not Used)
------------------------------------------------------------

**Synology example**

cd /volume1/web/**<your Project>**/lib/playwright/linux-nas-arm64  
rm -rf node_modules package-lock.json  
npm install playwright@1.58.2

This installs:
- playwright-core@1.58.2  
- playwright@1.58.2  

These modules are mounted into Docker at `/app/node_modules`.

------------------------------------------------------------
5. Download the Playwright Docker Image (Jammy)
------------------------------------------------------------

docker pull mcr.microsoft.com/playwright:v1.58.2-jammy

Verify:

docker images | grep playwright

Expected:

mcr.microsoft.com/playwright   v1.58.2-jammy   <image-id>

------------------------------------------------------------
6. How It Works
------------------------------------------------------------

6.1 NAS wrapper (runs on the NAS OS)

node imdb-fetch.js "<IMDb URL>"

6.2 Wrapper launches Docker (no compose required)

docker run --rm \
  --shm-size=1gb \
  -v <projectRoot>:/app \
  mcr.microsoft.com/playwright:v1.58.2-jammy \
  node /app/lib/playwright/linux-nas-arm64/imdb-fetch-linux.cjs "<URL>"

6.3 Inside Docker:

- Node loads playwright-core from /app/node_modules  
- Chromium (v1.58) launches headless  
- IMDb page is fetched  
- WAF detection runs  
- HTML returned as JSON  

This approach is **stateless, portable, and requires no persistent container**.

------------------------------------------------------------
7. Wrapper (imdb-fetch.js) — ESM
------------------------------------------------------------

- Dynamically resolves project root  
- Converts fetcher path to POSIX for Docker  
- Uses execSync to run the container  
- No hardcoded folder names  
- Works on ARM64 and x86 NAS models  

------------------------------------------------------------
8. Linux Fetcher (imdb-fetch-linux.cjs) — CommonJS
------------------------------------------------------------

- Ensures NODE_PATH points to /app/node_modules  
- Loads playwright-core  
- Launches Chromium headless  
- Performs WAF wait + retry  
- Returns JSON  

------------------------------------------------------------
9. Manual Test (Optional)
------------------------------------------------------------

**Synology example**

cd /volume1/web/**<your Project>**/lib/playwright/linux-nas-arm64

node imdb-fetch.js "http://www.imdb.com"

Expected:

WRAPPER LOADED: /volume1/web/**<your Project>**/lib/playwright/linux-nas-arm64/imdb-fetch.js  
Received url: http://www.imdb.com  
Amended url: https://www.imdb.com  
hostFetcher: /volume1/web/**<your Project>**/lib/playwright/linux-nas-arm64/imdb-fetch-linux.cjs  
projectRoot: /volume1/web  
containerFetcher: /app/**<your Project>**/lib/playwright/linux-nas-arm64/imdb-fetch-linux.cjs  
EXEC CMD: docker run --rm --shm-size=1gb -v /volume1/web:/app mcr.microsoft.com/playwright:v1.58.2-jammy node "/app/**<your Project>**/lib/playwright/linux-nas-arm64/imdb-fetch-linux.cjs" "https://www.imdb.com"  
FETCHER STARTED INSIDE DOCKER: /app/**<your Project>**/lib/playwright/linux-nas-arm64/imdb-fetch-linux.cjs  
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

cd /volume1/web/**<your Project>**/lib/playwright/linux-nas-arm64  
sh pw-04-install-docker-socket-fix.sh

The installer will:

- Detect Synology DSM  
- Print **Task Scheduler** instructions  
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
