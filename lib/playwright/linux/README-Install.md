# Playwright IMDb‑F# Playwright IMDb‑Fetcher — Install / Verify / Uninstall
For architecture details, see README‑Overview.md.

--------------------------------------------------------------------------------
🔧 Making Scripts Executable (Required Before Installation)
--------------------------------------------------------------------------------

On a fresh clone, the script `00-make-executables.sh` may not be executable yet.

    cd lib/playwright/linux
    chmod +x 00-make-executables.sh

Now run it to fix all other `.sh` files:

    ./00-make-executables.sh

This ensures:
- all installer, uninstaller, and verify scripts are executable
- new `.sh` files added later are also handled

--------------------------------------------------------------------------------
🛠 Installation
--------------------------------------------------------------------------------

    cd lib/playwright/linux
    ./install.sh

This performs:
- environment detection
- Node installation (if required)
- Playwright installation (system-install)
- browser installation into node_modules/.local-browsers
- sudoers setup (Tier‑1 + Tier‑2)
- wrapper + fetcher permission setup (pdb:daemon 770)
- environment file generation
- full verification

After installation:
- wrappers are executable by Apache
- Playwright + browsers are installed locally
- sudoers entries allow Apache → sudo → pdb execution
- environment is fully ready

--------------------------------------------------------------------------------
🧪 Verification (Post‑Install)
--------------------------------------------------------------------------------

    cd lib/playwright/linux
    ./verify-install.sh

This:
- regenerates the environment file
- loads env
- verifies Node, Playwright, browsers
- verifies wrapper + fetcher permissions
- verifies sudoers Tier‑1 + Tier‑2
- runs a full fetcher test
- deletes the env file

Verification should pass immediately after installation.

--------------------------------------------------------------------------------
🧹 Uninstall
--------------------------------------------------------------------------------

    cd lib/playwright/linux
    ./uninstall.sh

This removes:
- node_modules/
- package-lock.json
- Tier‑2 sudoers file
- optionally Tier‑1 (only if no other Tier‑2 exist)
- environment file
- resets wrapper + fetcher to raw Git state:
      owner = pdb
      group = pdb
      mode  = 664

Wrappers remain in the repo but are no longer executable by Apache.

--------------------------------------------------------------------------------
🧪 Verification (Post‑Uninstall)
--------------------------------------------------------------------------------

    cd lib/playwright/linux
    ./verify-uninstall.sh

This confirms:
- node_modules removed
- package-lock.json removed
- Tier‑2 sudoers removed
- Tier‑1 removed only if safe
- wrapper + fetcher exist and are 664 pdb:pdb
- no Playwright runtime remains

Verification should fail if Playwright is still installed (expected).

--------------------------------------------------------------------------------
🧪 Testing the IMDb Fetcher (Headless)
--------------------------------------------------------------------------------

Under Apache (via sudoers):

    ./imdb-fetch-headless.sh "<url>"

From a normal shell:

    node imdb-fetch-unix-headless.mjs "<url>"

--------------------------------------------------------------------------------
📦 Installation Summary
--------------------------------------------------------------------------------

    cd lib/playwright/linux
    chmod +x 00-make-executables.sh
    ./00-make-executables.sh
    ./install.sh

After this, the environment is fully ready for IMDb fetching.
etcher — Install / Verify / Uninstall
# Linux Only
# System Apache • XAMPP/LAMPP • Headful Chromium

This document describes how to install, verify, and uninstall the Playwright IMDb‑Fetcher environment on Linux.  
For architectural details, see README‑Overview.md.

--------------------------------------------------------------------------------
📦 Requirements
--------------------------------------------------------------------------------

Linux (Debian/Ubuntu recommended)

Apache environment:
    - System Apache (apache2)
    - or XAMPP/LAMPP (httpd.bin)

Desktop user must have:
    - sudo privileges
    - write access to the project folder

Installer automatically:
    - detects Apache environment
    - installs Node.js (if missing)
    - installs Playwright
    - configures wrapper permissions
    - creates runtime folders
    - optionally configures sudoers

--------------------------------------------------------------------------------
🚀 Installation
--------------------------------------------------------------------------------

From the project root:

