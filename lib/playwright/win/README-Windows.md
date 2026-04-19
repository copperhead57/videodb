Windows Portable Playwright Setup (videodb)
===========================================

A fully portable, deterministic Playwright + Chromium environment for Windows.
No global Node installation required. No PATH changes. No system dependencies.

Everything runs from:

    videodb/lib/playwright/win/

This document explains how to:

- Verify the portable Playwright bundle
- Install portable Node.js correctly (ZIP version)
- Install Playwright using pw-02-install.ps1
- Install Chromium into the correct portable folder
- Test Playwright using pw-03-runtest.ps1
- Use cleanup scripts
- Understand the expected folder structure
- Run commands safely (Beginner Friendly)


------------------------------------------------------------
How to Run Commands (Beginner Friendly)
------------------------------------------------------------

All commands in this guide are run from **PowerShell**, not CMD.

### 1. Open PowerShell
Start Menu → type "powershell" → open **Windows PowerShell**

### 2. Navigate to the Playwright folder

    cd C:\Users\Public\Web\wamp64\www\github-copperhead\videodb\lib\playwright\win

Run `dir` to confirm you're in the right place.

### 3. Running PowerShell scripts (in order)

    .\pw-01-verify.ps1
    .\pw-02-install.ps1
    .\pw-01-verify.ps1   (run again after install)
    .\pw-03-runtest.ps1 https://example.com

### 4. Running Node and npm

    .\node.exe -v
    .\npm.cmd -v
    .\npx.cmd -v


------------------------------------------------------------
1. Verification Script (Run First)
------------------------------------------------------------

Run:

    .\pw-01-verify.ps1

This checks:

- node.exe
- npm.cmd (embedded in Node 25)
- Node internal runtime (snapshot)
- Playwright package
- Playwright CLI
- Chromium
- FFmpeg
- Headed browser
- Headless Shell browser
- Winldd

If all items show **[OK]**, your environment is ready for installation.


------------------------------------------------------------
2. Installing Portable Node.js (Required)
------------------------------------------------------------

Download from:

    https://nodejs.org/dist/latest/

Choose the Windows ZIP:

    node-v25.x.x-win-x64.zip

Extract and copy the contents into:

    videodb/lib/playwright/win/

You should now have:

    node.exe
    npm.cmd
    npx.cmd
    node_modules/

Verify:

    .\node.exe -v
    .\npm.cmd -v
    .\npx.cmd -v


------------------------------------------------------------
3. Automated Playwright Installation (Recommended)
------------------------------------------------------------

Once portable Node is present, run:

    .\pw-02-install.ps1

This script:

- Installs Playwright locally
- Installs Chromium into the portable folder
- Ensures a deterministic, reproducible bundle

After installation, run verification again:

    .\pw-01-verify.ps1

If everything shows **[OK]**, Playwright is fully installed.


------------------------------------------------------------
4. Manual Playwright Installation (Alternative)
------------------------------------------------------------

Install Playwright:

    .\npm.cmd install playwright

Install Chromium:

    set PLAYWRIGHT_BROWSERS_PATH=0
    .\node.exe node_modules\playwright\cli.js install chromium
    set PLAYWRIGHT_BROWSERS_PATH=

Verify:

    .\node.exe node_modules\playwright\cli.js --version


------------------------------------------------------------
5. Cleanup Script (Optional)
------------------------------------------------------------

To remove Firefox/WebKit and reduce bundle size:

    .\pw-04-clean.cmd


------------------------------------------------------------
6. Expected Windows Playwright Folder Structure
------------------------------------------------------------

    win/
      node.exe
      npm.cmd
      npx.cmd
      node_modules/
        playwright/
        playwright-core/
          .local-browsers/
            chromium-xxxx/
            ffmpeg-xxxx/
            chromium_headless_shell-xxxx/
            winldd-xxxx/
      pw-01-verify.ps1
      pw-02-install.ps1
      pw-03-runtest.ps1
      pw-04-clean.cmd
      README-Windows.md

Node 25 change:
The following folders no longer exist:

    node_modules/npm/
    node_modules/corepack/
    node_modules/lib/

These are now embedded inside node.exe. This is normal and correct.


------------------------------------------------------------
7. Testing Playwright (Optional)
------------------------------------------------------------

To confirm that Playwright and Chromium are working correctly, run:

    .\pw-03-runtest.ps1 https://example.com

What to expect:

- A Chromium browser window opens
- The page loads normally
- When you close the browser window, the script exits automatically

If the browser opens and loads the page, your portable Playwright environment is fully functional.

============================================================
README Complete
============================================================