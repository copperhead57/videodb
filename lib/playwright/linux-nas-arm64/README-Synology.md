# Playwright NAS Setup (Docker‑Based, ARM64 & x86 Compatible)

This subsystem runs **Playwright inside Docker**, not on the NAS OS.  
The NAS only runs a lightweight Node.js wrapper that launches the container.

Works on:
- Synology DSM 7.x (ARM64 & x86)
- QNAP (ARM64 & x86)
- TrueNAS SCALE
- UnRAID
- Any Linux NAS with Docker support

Playwright browsers live **inside Docker**.  
Your NAS only stores the Node.js library + wrapper scripts.

⚠️ Testing Status  
this setup has been **tested only on Synology ARM64**.
    - full functionality is not avaialble some parts apper flakly.
    - imdb tab doesnt always render full pages but links appear to work
    - saving IMDB data to videodb is limnited.
    
It *should* work on x86 NAS models and other NAS platforms, but these have not yet been validated.

------------------------------------------------------------
1. Requirements
------------------------------------------------------------

- Docker installed on the NAS  
- Node.js installed (from NAS package center or system package manager)  
- SSH access (recommended)  
- Playwright Docker image (Jammy)  
- Local Playwright Node.js library (v1.58.x recommended)

Supported architectures:

| Architecture | Supported | Notes |
|-------------|-----------|-------|
| ARM64       | ✔️ Yes    | Fully tested on Synology ARM64 |
| x86_64      | ✔️ Yes    | Expected to work, not yet tested |

------------------------------------------------------------
2. NAS Script Workflow (Preferred Method)
------------------------------------------------------------

pw-01-verify.sh  
    Checks Node, npm, Docker, Playwright, folder structure.

pw-02-install.sh  
    Installs Playwright 1.58.2 + pulls Docker image.

pw-03-runtest.sh  
    Runs a real IMDb fetch to confirm everything works.

There is **no clean script** because:
- Browsers live inside Docker  
- Docker image should not be mutated  
- node_modules must remain intact  
- The environment must stay runnable  

This keeps the NAS setup stable, deterministic, and contributor‑friendly.

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
        package.json               ← Contains "type": "module"
        node_modules/              ← Playwright 1.58.x installed here

This structure works on **ARM64 and x86 NAS models**.

------------------------------------------------------------
4. Install Playwright Node.js Library (v1.58.x)
------------------------------------------------------------

cd /volume1/web/videodb-devcode/lib/playwright/linux-nas-arm64
rm -rf node_modules package-lock.json
npm install playwright@1.58.2

This installs:
- playwright-core@1.58.2
- playwright@1.58.2

These modules are mounted into Docker at /app/node_modules.

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

cd /volume1/web/videodb-devcode/lib/playwright/linux-nas-arm64

node imdb-fetch.js "https://www.imdb.com/title/tt0111161/"

Expected:

{ ok: true, wafDetected: false, html: "<!DOCTYPE html>..." }

------------------------------------------------------------
10. Architecture Notes
------------------------------------------------------------

ARM64 NAS (Synology, QNAP, TrueNAS SCALE ARM)
✔ Fully supported  
✔ Playwright Docker image includes ARM64 Chromium  

x86 NAS (Synology Plus, QNAP x86, UnRAID, TrueNAS SCALE)
✔ Expected to work  
⚠️ Not yet tested  
✔ Same Docker image and scripts apply  
