NOTE: This macOS setup is UNTESTED. It is provided for contributors who wish
to develop or validate the Playwright environment on macOS. The project owner
does not have a macOS machine, so this guide may require adjustments.

macOS Portable Playwright Setup (videodb)
=========================================

A fully portable, deterministic Playwright + Chromium environment for macOS.
No global Node installation required. No PATH changes. No system dependencies.

Everything runs from:

    videodb/lib/playwright/mac/

This document explains how to:

- Verify the portable Playwright bundle
- Install portable Node.js correctly (macOS tar.gz version)
- Install Playwright manually (no auto scripts yet)
- Install Chromium into the correct portable folder
- Test Playwright using pw-03-runtest.sh
- Understand the expected folder structure
- Run commands safely (Beginner Friendly)


------------------------------------------------------------
How to Run Commands (Beginner Friendly)
------------------------------------------------------------

All commands in this guide are run from the **Terminal** app.

### 1. Open Terminal
Applications → Utilities → Terminal

### 2. Navigate to the Playwright folder

    cd /path/to/videodb/lib/playwright/mac

Run `ls` to confirm you're in the right place.

### 3. Running scripts (in order)

    ./pw-01-verify.sh
    ./pw-02-install.sh   (not available yet — manual install only)
    ./pw-01-verify.sh
    ./pw-03-runtest.sh https://example.com

### 4. Running Node and npm

    ./node -v
    ./npm -v
    ./npx -v


------------------------------------------------------------
1. Verification Script (Run First)
------------------------------------------------------------

Run:

    ./pw-01-verify.sh

This checks:

- node (portable)
- npm (embedded in Node 25)
- Node internal runtime (snapshot)
- Playwright package
- Playwright CLI
- Chromium browser bundle

If all items show **[OK]**, your environment is ready for installation.


------------------------------------------------------------
2. Installing Portable Node.js (Required)
------------------------------------------------------------

Download from:

    https://nodejs.org/dist/latest/

Choose the macOS tar.gz:

    node-v25.x.x-darwin-x64.tar.gz
    or
    node-v25.x.x-darwin-arm64.tar.gz  (Apple Silicon)

Extract and copy the contents into:

    videodb/lib/playwright/mac/

You should now have:

    node
    npm
    npx
    node_modules/

Verify:

    ./node -v
    ./npm -v
    ./npx -v


------------------------------------------------------------
3. Manual Playwright Installation (Required)
------------------------------------------------------------

Install Playwright:

    ./npm install playwright

Install Chromium:

    export PLAYWRIGHT_BROWSERS_PATH=0
    ./node node_modules/playwright/cli.js install chromium
    unset PLAYWRIGHT_BROWSERS_PATH

Verify:

    ./node node_modules/playwright/cli.js --version


------------------------------------------------------------
4. Expected macOS Playwright Folder Structure
------------------------------------------------------------

    mac/
      node
      npm
      npx
      node_modules/
        playwright/
        playwright-core/
          .local-browsers/
            chromium-xxxx/
            ffmpeg-xxxx/
            chromium_headless_shell-xxxx/
      pw-01-verify.sh
      pw-03-runtest.sh
      README-macOS.md

Node 25 change:
The following folders no longer exist:

    node_modules/npm/
    node_modules/corepack/
    node_modules/lib/

These are now embedded inside the Node binary. This is normal and correct.


------------------------------------------------------------
5. Testing Playwright (Optional)
------------------------------------------------------------

To confirm that Playwright and Chromium are working correctly, run:

    ./pw-03-runtest.sh https://example.com

What to expect:

- A Chromium browser window opens (headless or headful depending on config)
- The page loads normally
- When the browser closes, the script exits automatically

If the browser loads the page, your portable Playwright environment is fully functional.

============================================================
README Complete
============================================================