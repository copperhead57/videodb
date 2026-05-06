#!/usr/bin/env bash
set -euo pipefail

echo "[02] Verifying Node.js..."

# ------------------------------------------------------------
# Load persistent environment file
# ------------------------------------------------------------
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYROOT="$(dirname "${BASE_DIR}")"
ENV_FILE="${PLAYROOT}/playwright-env.sh"

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "[02] ERROR: Persistent env file not found:"
    echo "     ${ENV_FILE}"
    exit 1
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

REQUIRED_MAJOR=24

# ------------------------------------------------------------
# STEP 1 — Check if Node exists
# ------------------------------------------------------------
if command -v node >/dev/null 2>&1; then
    NODE_VERSION="$(node -v | sed 's/v//')"
    NODE_MAJOR="${NODE_VERSION%%.*}"

    echo "  Found Node.js: v${NODE_VERSION}"
    echo "  npm version:   $(npm -v)"

    if (( NODE_MAJOR >= REQUIRED_MAJOR )); then
        echo "  Node version is sufficient (>= ${REQUIRED_MAJOR})."
        echo "[02] Node.js verification complete."
        exit 0
    fi

    echo
    echo "[02] ERROR: Node.js version is too old."
    echo "  Required: ${REQUIRED_MAJOR}+"
    echo "  Found:    ${NODE_MAJOR}"
    echo
    echo "Please upgrade Node.js manually before continuing."
    exit 1
fi

# ------------------------------------------------------------
# STEP 2 — Node is missing → auto-install for first-timers
# ------------------------------------------------------------
echo
echo "  Node.js is not installed."
echo "  Installing Node.js ${REQUIRED_MAJOR}.x system-wide via NodeSource..."

curl -fsSL "https://deb.nodesource.com/setup_${REQUIRED_MAJOR}.x" | sudo -E bash -
sudo apt install -y nodejs

echo "  Node.js installation complete."

# ------------------------------------------------------------
# STEP 3 — Verify installation
# ------------------------------------------------------------
echo
echo "  Verifying Node.js installation..."

if ! command -v node >/dev/null 2>&1; then
    echo "  [FAIL] Node.js not found after installation."
    exit 1
fi

echo "  Node version: $(node -v)"
echo "  npm version:  $(npm -v)"

echo "[02] Node.js verification complete."
