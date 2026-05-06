#!/usr/bin/env bash
set -euo pipefail

echo "[04] Installing Playwright (system-install mode)..."

# ------------------------------------------------------------
# Load persistent environment file
# ------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYROOT="$(dirname "${SCRIPT_DIR}")"
ENV_FILE="${PLAYROOT}/playwright-env.sh"

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "[FAIL] Missing environment file: ${ENV_FILE}"
    exit 1
fi

# Load authoritative environment
source "${ENV_FILE}"

echo "[04] Environment:"
echo "     PW_PROJECT_ROOT = ${PW_PROJECT_ROOT}"
echo "     PW_PLAYROOT     = ${PW_PLAYROOT}"
echo "     PW_OS_TYPE      = ${PW_OS_TYPE}"
echo

cd "${PW_PLAYROOT}"

# ------------------------------------------------------------
# STEP 1 — Verify Node exists
# ------------------------------------------------------------
echo "[04] Checking Node installation..."

if ! command -v node >/dev/null 2>&1; then
    echo "[FAIL] Node is not installed. Install Node 24+ first."
    exit 1
fi

echo "[04] Node version: $(node -v)"
echo "[04] npm version:  $(npm -v)"
echo

# ------------------------------------------------------------
# STEP 2 — Ensure package.json exists
# ------------------------------------------------------------
echo "[04] Ensuring package.json exists..."

if [[ ! -f "./package.json" ]]; then
    npm init -y
    echo "[04] Created package.json"
else
    echo "[04] package.json already exists"
fi

echo

# ------------------------------------------------------------
# STEP 3 — Install Playwright package
# ------------------------------------------------------------
echo "[04] Installing Playwright package..."

npm install playwright --save-exact

echo "[04] Playwright package installed."
echo

# ------------------------------------------------------------
# STEP 4 — Install Playwright browsers (system-install mode)
# ------------------------------------------------------------
echo "[04] Installing Playwright browsers (system-install mode)..."

# System-install mode → browsers go into:
#   node_modules/playwright-core/.local-browsers/
PLAYWRIGHT_BROWSERS_PATH=0 \
npx playwright install

echo "[04] Browsers installed into:"
echo "     node_modules/playwright-core/.local-browsers/"
echo

# ------------------------------------------------------------
# STEP 5 — No GUI deps needed (headless only)
# ------------------------------------------------------------
echo "[04] Skipping GUI dependencies (headless-only architecture)."
echo

echo "[04] Playwright installation complete."
