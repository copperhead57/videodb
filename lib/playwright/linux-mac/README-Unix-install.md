# ============================================================
# PLAYWRIGHT INSTALLATION (Linux + macOS)
# ============================================================
# Unified structure (2026):
#
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
#
# ============================================================



# ============================================================
# 0. RECOMMENDED: AUTOMATED INSTALL METHOD
# ============================================================
# These scripts:
# - Detect OS (Linux or macOS)
# - Install Playwright-core into linux-mac/node_modules/
# - Install browsers into linux/browsers/ or mac/browsers/
# - Install GUI dependencies on Linux only
# - Verify installation before and after
# - Prepare unified fetcher (imdb-fetch-unix.mjs)
# - Prevent incorrect installs



# ------------------------------------------------------------
# Step A — Install Node (optional helper)
# ------------------------------------------------------------
./pw-02A-install-node.sh



# ------------------------------------------------------------
# Step B — Install Playwright (auto-detects OS)
# ------------------------------------------------------------
./pw-02B-install-playwright.sh



# ------------------------------------------------------------
# Step C — Verify installation
# ------------------------------------------------------------
./pw-01-verify.sh

# Expected output:
# ✔ Node OK
# ✔ Playwright-core OK
# ✔ Browser bundle found
# ✔ Profile folder OK
# ✔ Unified fetcher OK



# ============================================================
# 1. SUDO SETUP (REQUIRED FOR XAMPP + GUI)
# ============================================================
# Playwright must run as the *desktop user*, even when launched
# by the *webserver user* (Apache/XAMPP).
#
# These scripts configure safe, minimal sudo permissions:
#   pw-sudo-01-setup.sh
#   pw-sudo-02-verify.sh
#   pw-sudo-03-undo.sh
#
# Only these 3 scripts get NOPASSWD permissions:
#   xvfb.sh
#   node-clean.sh
#   imdb-fetch-unix.mjs



# ------------------------------------------------------------
# Step 1 — Run sudo setup (as root)
# ------------------------------------------------------------
sudo PLAYROOT=/full/path/to/lib/playwright/linux-mac \
    ./pw-sudo-01-setup.sh

# This script:
# - Auto-detects webserver user (XAMPP-first)
# - Auto-detects desktop user
# - Applies correct permissions (root:pdb, chmod 770)
# - Writes sudoers entry
# - Validates sudoers with visudo



# ------------------------------------------------------------
# Step 2 — Verify sudo setup
# ------------------------------------------------------------
./pw-sudo-02-verify.sh

# Expected:
# ✔ xvfb.sh OK
# ✔ node-clean.sh OK
# ✔ imdb-fetch-unix.mjs OK
# ✔ sudoers entry OK



# ------------------------------------------------------------
# Step 3 — Undo sudo setup (optional)
# ------------------------------------------------------------
sudo ./pw-sudo-03-undo.sh

# This removes:
# - sudoers entry
# - resets permissions to 755
# - restores root:root ownership



# ============================================================
# 2. MANUAL INSTALL METHOD (if preferred)
# ============================================================

# ------------------------------------------------------------
# Step 1 — Install Node (system-wide)
# ------------------------------------------------------------

# Linux (NodeSource)
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt install -y nodejs

# macOS/Linux (nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install --lts

# Verify
node -v
npm -v



# ------------------------------------------------------------
# Step 2 — Install Playwright-core (shared Linux + mac)
# ------------------------------------------------------------
cd lib/playwright/linux-mac
npm init -y
npm install playwright



# ------------------------------------------------------------
# Step 3 — Install Playwright browsers (OS-specific)
# ------------------------------------------------------------

# Linux
PLAYWRIGHT_BROWSERS_PATH=./linux/browsers \
npx playwright install

# macOS
PLAYWRIGHT_BROWSERS_PATH=./mac/browsers \
npx playwright install



# ------------------------------------------------------------
# Step 4 — Install GUI dependencies (Linux only)
# ------------------------------------------------------------
sudo npx playwright install-deps

# macOS does NOT require this step.



# ------------------------------------------------------------
# Step 5 — Verify installation
# ------------------------------------------------------------
./pw-01-verify.sh



# ============================================================
# 3. RUNNING PLAYWRIGHT (via PHP / XAMPP)
# ============================================================

# PHP launcher calls:
sudo -u <webuser> sudo -n -u <desktopuser> \
    xvfb.sh node-clean.sh imdb-fetch-unix.mjs "<url>"

# The unified .mjs file:
# - Sets DISPLAY / XAUTHORITY / DBUS
# - Resets LD_LIBRARY_PATH
# - Sets NODE_PATH + PLAYWRIGHT_BROWSERS_PATH
# - Launches portable Chromium
# - Waits for AWS WAF
# - Returns JSON:
#
# {
#   "ok": true,
#   "html": "<full html>",
#   "wafDetected": false,
#   "error": null
# }



# ============================================================
# END OF INSTALLATION
# ============================================================
