# ============================================================
# UNINSTALL / RESET GUIDE — Linux + macOS (shared environment)
# ============================================================

This project uses the following structure:

lib/playwright/
    linux-mac/
        xvfb.sh
        node-clean.sh
        imdb-fetch-unix.mjs        ← unified wrapper + fetcher
        node_modules/

        linux/
            browsers/

        mac/
            browsers/

# ============================================================



# ============================================================
# 0. RECOMMENDED: AUTOMATED UNINSTALL SCRIPTS
# ============================================================

These scripts safely remove ONLY the Playwright environment.
They do NOT remove:
  - Node
  - npm
  - GUI dependencies
  - System packages
  - Wrapper scripts (xvfb.sh, node-clean.sh)
  - Unified fetcher (imdb-fetch-unix.mjs)



# ------------------------------------------------------------
# A — Full Playwright uninstall (safe reset)
# ------------------------------------------------------------
./pw-03A-uninstall-playwright.sh

Removes:
  - linux-mac/node_modules/
  - linux-mac/linux/browsers/
  - linux-mac/mac/browsers/
  - ~/.cache/ms-playwright

This is the recommended “factory reset” for Playwright.



# ------------------------------------------------------------
# B — Clean cache only (non-destructive)
# ------------------------------------------------------------
./pw-03B-clean-cache-only.sh

Removes ONLY:
  - ~/.cache/ms-playwright

Useful when:
  - Browser launch fails
  - Chromium profile corrupts
  - AWS WAF blocks cached signatures
  - You want a clean browser download without reinstalling everything



# ------------------------------------------------------------
# C — Verify environment after uninstall
# ------------------------------------------------------------
./pw-01-verify.sh

Expected:
  - Node OK (system-wide)
  - Playwright-core: FAIL (correct after uninstall)
  - Browser bundle: FAIL (correct after uninstall)
  - Cache: OK/FAIL depending on script used

# ============================================================



# ============================================================
# 1. OPTIONAL: UNINSTALL NODE (only if user chooses)
# ============================================================

If Node was installed via APT or NodeSource:
  sudo apt remove nodejs npm
  sudo apt autoremove

If installed via nvm:
  nvm uninstall <version>
  rm -rf ~/.nvm
  sed -i '/NVM_DIR/d' ~/.bashrc

Verify Node removed:
  node -v
  npm -v

# ============================================================



# ============================================================
# 2. MANUAL UNINSTALL (same as pw‑03A, but step-by-step)
# ============================================================

cd lib/playwright/linux-mac

# Remove Playwright-core
rm -rf node_modules/

# Remove Linux browsers
rm -rf linux/browsers/

# Remove macOS browsers
rm -rf mac/browsers/

# Remove Playwright cache
rm -rf ~/.cache/ms-playwright

echo "Manual uninstall complete."

# Verify manually:
./pw-01-verify.sh

# ============================================================



# ============================================================
# 3. OPTIONAL: UNINSTALL GUI DEPENDENCIES (Linux only)
# ============================================================

These were installed by:
  sudo npx playwright install-deps

They include:
  GTK, X11, NSS, codecs, fonts, WebKit libs, video libs

WHY THERE IS NO AUTO-UNINSTALL SCRIPT:
--------------------------------------
These packages are *shared system libraries* used by:
  - Linux Mint desktop
  - Firefox / Chrome
  - Electron apps
  - Steam
  - Flatpak apps
  - Video players

Removing them WILL break other applications.

Playwright does NOT provide a safe uninstall command for these
dependencies, and this project intentionally does NOT automate it.

If you absolutely must remove them, do so manually and at your own risk.

# ============================================================



# ============================================================
# 4. OPTIONAL: UNDO SUDO SETUP (if previously configured)
# ============================================================

If you configured sudo permissions for Playwright:

  sudo ./pw-sudo-03-undo.sh

This removes:
  - /etc/sudoers.d/videodb-playwright
  - Resets permissions on:
        xvfb.sh
        node-clean.sh
        imdb-fetch-unix.mjs

After undo:
  - Webserver will no longer be able to run Playwright
  - PHP fetcher calls will fail (expected)

# ============================================================



# ============================================================
# END OF UNINSTALLATION
# ============================================================
