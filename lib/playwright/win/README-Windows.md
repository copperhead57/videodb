Windows Portable Playwright Setup (videodb)
===========================================

A fully portable, deterministic Playwright + Chromium environment for Windows.
No global Node installation required. No PATH changes. No system dependencies.

Everything runs from:

    videodb/lib/playwright/win/

This document explains how to:

- Verify the portable Playwright bundle
- Install portable Node.js correctly (ZIP version)
- Install Playwright using pw-01-Installer.ps1
- Install Chromium into the correct portable folder
- Test Playwright using pw-04-run-test.ps1
- Uninstall Node + Playwright using pw-02-uninstaller.ps1
- Verify uninstall using pw-03-verify-uninstall.ps1
- Understand the expected folder structure
- Run commands safely (Beginner Friendly)


------------------------------------------------------------
Portable Environment Contract (Critical)
------------------------------------------------------------

To guarantee a fully deterministic, reproducible Playwright environment on Windows, the following rules must always be followed:

- All commands must be run from PowerShell, not CMD
- All commands must be executed from:
      videodb/lib/playwright/win/
- PLAYWRIGHT_BROWSERS_PATH must always point to:
      ./node_modules/playwright-core/.local-browsers
- No global Node.js installation may be used
- No global Playwright installation may be used
- No PATH modifications are allowed
- No external system browsers are used
- The portable folder must not be moved after installation

Breaking any of these rules causes environment drift and invalidates the portable setup.


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

    .\pw-03-verify-install.ps1
    .\pw-01-Installer.ps1
    .\pw-03-verify-install.ps1   (run again after install)
    .\pw-04-run-test.ps1

### 4. Running Node and npm

    .\node.exe -v
    .\npm.cmd -v
    .\npx.cmd -v


------------------------------------------------------------
Why PowerShell Only (Not CMD)
------------------------------------------------------------

PowerShell is required because:

- It preserves environment variables correctly
- It handles quoting and paths reliably
- Playwright CLI behaves consistently under PowerShell
- UTF‑8 output is supported
- All scripts in this bundle are written for PowerShell semantics

CMD breaks quoting, path resolution, and environment propagation.
Running Playwright from CMD is unsupported and will cause failures.


------------------------------------------------------------
1. Verification Script (Run First)
------------------------------------------------------------

Run:

    .\pw-03-verify-install.ps1

This checks:

- node.exe
- npm.cmd
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
2. Automated Playwright Installation (Recommended)
------------------------------------------------------------

    Run : .\pw-01-Installer.ps1

    This launcher:

    - Installs portable Node (pw-01a-install-node.ps1)
    - Installs Playwright + Chromium (pw-01b-install-playwright.ps1)
    - Verifies installation (pw-03-verify-install.ps1)
        If everything shows **[OK]**, Playwright is fully installed.
    - Runs the test harness (pw-04-run-test.ps1)

------------------------------------------------------------
3. Manual Node and Playwright Installation (Alternative)
------------------------------------------------------------

    3a. Installing Portable Node.js
        Download from: https://nodejs.org/dist/vxx.xx.x (Latest LTS version)
            Choose the Windows ZIP: node-vxx.x.x-win-x64.zip

        Extract and copy the following into: videodb/lib/playwright/win/
            node.exe
            npm.cmd
            npx.cmd
            node_modules/

        Verify:
            .\node.exe -v
            .\npm.cmd -v
            .\npx.cmd -v

    3b.Install Playwright:
        Run: .\npm.cmd install playwright

        Verify: .\node.exe node_modules\playwright\cli.js --version

    3c.Install Chromium:
        set environment to put broswers in correct dir
        Note: “This variable is temporary and resets automatically when you close PowerShell.”
        Run: $env:PLAYWRIGHT_BROWSERS_PATH = "$PWD\node_modules\playwright-core\.local-browsers"
        
        Actual install
            .\node.exe node_modules\playwright\cli.js install chromium

    3d. Verify install
        .\pw-03-verify-install.ps1

    3e. run full test:
        .\pw-04-run-test.ps1

------------------------------------------------------------
4. Automated Playwright Un-Installation (Recommended)
------------------------------------------------------------

    Run: .\pw-02-uninstaller.ps1

    This launcher:

    - Un-Installs portable Node (pw-02a-uninstall-node.ps1)
    - Un-Installs Playwright + Chromium (pw-02b-uninstall-playwright.ps1)
    - Verifies installation (pw-03-verify-uninstall.ps1)

------------------------------------------------------------
5. Uninstalling Node + Playwright Manual
------------------------------------------------------------

    5a.Uninstall Node:
    Run: .\pw-02a-uninstall-node.ps1

    Removes:
        - node.exe
        - npm.cmd
        - npx.cmd

    5b.Uninstall Playwright:
    Run: .\pw-02b-uninstall-playwright.ps1

    Removes:
        - node_modules
        - chrome-profile
        - package-lock.json

    5c. Verify uninstall:
    Run: .\pw-03-verify-uninstall.ps1

    5d. ### Alternate manual uninstall via exploer or other tool
        Manually deleted the following files andr directoies
        - node.exe
        - npm.cmd
        - npx.cmd
        - node_modules
        - chrome-profile
        - package-lock.json

------------------------------------------------------------
6. Expected Windows Playwright Folder Structure
------------------------------------------------------------

    win/
      node.exe *
      npm.cmd  *  
      npx.cmd  *
      node_modules/  *
        .bin/
        playwright/
        playwright-core/
            .local-browsers/
            chromium-xxxx/
            ffmpeg-xxxx/
            chromium_headless_shell-xxxx/
            winldd-xxxx/
      chrome-profile/ %
      package-lock.json *
      pw-01a-install-node.ps1
      pw-01b-install-playwright.ps1
      pw-01-Installer.ps1
      pw-02a-uninstall-node.ps1
      pw-02b-uninstall-playwright.ps1
      pw-02-uninstaller.ps1
      pw-03-verify-install.ps1
      pw-03-verify-uninstall.ps1
      pw-04-run-test.ps1
      imdb-fetch-headed.mjs
      package.json
      README-Windows.md

      * installed not part of the git structure
      % created when running the application by playwright

    When Node 25 becomes LTS change:
        The following folders no longer exist:
        node_modules/npm/
        node_modules/corepack/
        node_modules/lib/

These are now embedded inside node.exe. This is normal and correct.

------------------------------------------------------------
Browser Path Guarantee (Do Not Break This)
------------------------------------------------------------
    Playwright must always find Chromium inside:

        win/node_modules/playwright-core/.local-browsers/

    If this folder is missing or moved:

    - Playwright may reinstall browsers into the wrong location
    - The portable environment becomes non‑deterministic
    - Scripts may silently fall back to system browsers
    - Fetchers may fail or behave inconsistently

    Always verify that `.local-browsers/` exists after installation.

------------------------------------------------------------
Why Persistent Context Is Required (Playwright + IMDb)
------------------------------------------------------------
    Some websites (including IMDb) use advanced WAF and fingerprinting systems.
    A persistent browser profile is required because it:

    - Reduces browser entropy drift
    - Preserves cookies, localStorage, and session data
    - Avoids first‑run browser noise
    - Makes Chromium startup faster
    - Produces stable, repeatable fetch results
    - Reduces WAF delays and false positives

    This matches the Linux/NAS methodology and ensures consistent behavior across platforms.

------------------------------------------------------------
Do NOT Do This on Windows (Important)
------------------------------------------------------------
    To keep the portable environment stable, never do the following:

    - Do NOT run scripts from CMD
    - Do NOT double‑click .ps1 files
    - Do NOT run Node or npm from outside the win/ folder
    - Do NOT install Node globally
    - Do NOT install Playwright globally
    - Do NOT move or rename the win/ folder after installation
    - Do NOT run npm install from any other directory

    These actions cause environment drift and break determinism.


------------------------------------------------------------
Troubleshooting Checklist (Deterministic Tests)
------------------------------------------------------------
    Use this list to confirm the environment is correct:

    - .\node.exe -v prints Node xx
    - .\npm.cmd -v prints npm 11
    - .\npx.cmd -v prints a valid version
    - .\node.exe node_modules\playwright\cli.js --version prints the Playwright version
    - .\node.exe -p "require('playwright-core').chromium.executablePath()"
          → must print a path inside .local-browsers
    - .\pw-04-run-test.ps1
          → Chromium opens and loads the page

    If all items pass, the portable environment is functioning correctly.

------------------------------------------------------------
Security Model (Safe for All Users)
------------------------------------------------------------
    This portable Playwright bundle:

    - Requires no admin rights
    - Modifies no system files
    - Creates no registry entries
    - Installs no global packages
    - Stores all browser data inside:
          win/chrome-profile/
    - Can be deleted safely at any time
    - Leaves no traces on the system

    This makes it safe for shared machines, production servers, and offline environments.

------------------------------------------------------------
7. Testing Playwright (Optional)
------------------------------------------------------------
    To confirm that Playwright and Chromium are working correctly, run:
        .\pw-04-run-test.ps1

    What to expect:
    - A Chromium browser window opens
    - The page loads normally
    - When you close the browser window, the script exits automatically

    If the browser opens and loads the page, your portable Playwright environment is fully functional.
============================================================
README Complete
============================================================
