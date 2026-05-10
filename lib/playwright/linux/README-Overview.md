# Playwright IMDb‑Fetcher Environment — Architecture Overview
# Linux Only • Headless Execution • System‑Install Playwright
# Unified Linux Architecture (System Apache • XAMPP/LAMPP)

This document describes the architecture, design principles, and execution model of the Playwright IMDb‑Fetcher environment for Linux (headless only). For installation and usage instructions, see README‑Install.md.

--------------------------------------------------------------------------------
📁 Folder Structure (Final Architecture)
--------------------------------------------------------------------------------

lib/playwright/
    linux/
        imdb-fetch-linux-headless.sh          ← Wrapper (Apache → sudo → pdb → Node)
        imdb-fetch-linux-headless.mjs    ← Dedicated Playwright fetcher (Node)

        node_modules/                   ← Playwright + dependencies
            playwright/
            playwright-core/
                .local-browsers/        ← Playwright browser binaries (system-install)

        install-utils/
            01-detect-environment.sh
            02-install-node.sh
            03-sudo-setup.sh
            04-install-playwright.sh
            06a-uninstall-playwright.sh
            06b-uninstall-sudoers.sh
            07-verify-install.sh
            07-verify-uninstall.sh

        install.sh
        uninstall.sh
        verify-install.sh
        verify-uninstall.sh

✔ No chrome-profile  
✔ No chrome-home  
✔ No Crashpad/XDG dirs  
✔ No xvfb  
✔ No node-clean  
✔ No browsers/ folder  

All runtime is contained inside node_modules/.

--------------------------------------------------------------------------------
🧠 Why This Architecture Exists
--------------------------------------------------------------------------------

The goal is to provide a clean, deterministic, headless Playwright environment that:

- requires no writable HOME hacks
- requires no persistent Chromium profile
- avoids Crashpad/XDG failures
- avoids Apache-owned runtime folders
- avoids root-owned files
- avoids global Playwright installs
- supports multiple projects safely
- is fully reproducible

This is achieved by using system-install Playwright, where:

- browsers live inside .local-browsers under node_modules
- no global browser cache is used
- no HOME override is required
- no profile directories are created
- no Apache-owned directories exist

This eliminates all complexity from the old headful model.

--------------------------------------------------------------------------------
🔐 Execution Model (Final)
--------------------------------------------------------------------------------

1. Apache executes the wrapper via sudo:
    apache → sudo → pdb → wrapper → node → fetcher → Playwright → Chromium

2. Wrapper + fetcher permissions (runtime):
    owner: pdb
    group: daemon (or www-data)
    mode: 770

This ensures:
- Apache can execute the wrapper
- Node (running as pdb) can execute the fetcher
- contributors can edit both files
- no root-owned files
- no privilege escalation beyond sudoers rules

3. Sudoers Architecture (Tier‑1 + Tier‑2)

Tier‑1 (global per user):
    /etc/sudoers.d/<desktop-user>-playwright
Contains no project-specific rules. Exists once per user.

Tier‑2 (per project):
    /etc/sudoers.d/<desktop-user>-playwright-<project>-<environment>
Contains the actual Apache → sudo → pdb rules.

Uninstall removes Tier‑2.  
Tier‑1 is removed only if no other Tier‑2 remain.

--------------------------------------------------------------------------------
🌐 Environment Detection (Linux Only)
--------------------------------------------------------------------------------

01-detect-environment.sh determines:
- system Apache (apache2)
- XAMPP/LAMPP Apache (httpd.bin)
- or none

This sets:
- PW_APACHE_USER
- PW_ENVIRONMENT
- sudoers filenames
- wrapper permissions
- Playwright install mode

--------------------------------------------------------------------------------
📜 Script Overview (High‑Level)
--------------------------------------------------------------------------------

install.sh
    Runs the full installation pipeline:
    - detect environment
    - install Node (if needed)
    - install Playwright
    - install browsers (system-install)
    - create sudoers
    - set wrapper/fetcher permissions
    - generate env file

verify-install.sh
    Regenerates env file, loads it, runs full verification:
    - confirms browsers installed
    - confirms Playwright installed
    - confirms sudoers correct
    - confirms wrapper/fetcher perms correct
    - confirms fetcher works end-to-end

uninstall.sh
    - removes node_modules
    - removes package-lock.json
    - removes Tier‑2 sudoers
    - resets wrapper/fetcher to raw Git state (664, pdb:pdb)
    - removes env file
    - runs uninstall verification

verify-uninstall.sh
    - confirms node_modules removed
    - confirms package-lock.json removed
    - confirms Tier‑2 removed
    - confirms Tier‑1 removed only if safe
    - confirms wrapper/fetcher exist and are 664 pdb:pdb

--------------------------------------------------------------------------------
📦 Summary (Final Architecture)
--------------------------------------------------------------------------------

This architecture provides:
- deterministic Playwright execution
- headless-only stability
- no HOME overrides
- no persistent profile
- no Crashpad/XDG issues
- no Apache-owned runtime folders
- clean system-install browser model
- contributor-friendly permissions
- safe multi-project sudoers
- clean uninstall with raw Git restore

For installation and usage, see README‑Install.md.
