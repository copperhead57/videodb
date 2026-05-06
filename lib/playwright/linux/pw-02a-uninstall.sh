#!/usr/bin/env bash
set -euo pipefail

echo "== Playwright Uninstall / Reset =="

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../lib/playwright/linux
UTILS_DIR="${BASE_DIR}/install-utils"
ENV_FILE="${BASE_DIR}/playwright-env.sh"
DETECT_SCRIPT="${UTILS_DIR}/01-detect-environment.sh"

echo
echo "This will remove the Playwright runtime for THIS repo only."
echo "Node, global system packages, and Apache will NOT be touched."
echo
echo "It will remove:"
echo "  - node_modules/ (entire folder)"
echo "  - package-lock.json"
echo "  - project-specific sudoers entry"
echo "  - playwright-env.sh"
echo
echo "It will NOT remove:"
echo "  - wrapper scripts"
echo "  - package.json"
echo "  - PHP app files"
echo "  - Node.js itself"
echo

read -r -p "Proceed? (y/N): " REPLY
case "$REPLY" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "Cancelled."; exit 1 ;;
esac

# ------------------------------------------------------------
# SAFETY: Ensure env file exists (fallback to detect)
# ------------------------------------------------------------
if [[ ! -f "$ENV_FILE" ]]; then
    echo
    echo "[WARN] Environment file missing: $ENV_FILE"
    echo "       Running environment detection to rebuild it..."
    echo

    bash "$DETECT_SCRIPT"

    if [[ ! -f "$ENV_FILE" ]]; then
        echo "[FAIL] Detect script did not recreate env file."
        echo "       Cannot continue uninstall safely."
        exit 1
    fi
fi

# Load authoritative environment
source "$ENV_FILE"

echo
echo "== Preview of what WILL be removed =="
echo "  - ${PW_PLAYROOT}/node_modules/"
echo "  - ${PW_PLAYROOT}/package-lock.json"
echo "  - /etc/sudoers.d/${PW_DESKTOP_USER}-playwright-${PW_PROJECT_NAME}-${PW_ENVIRONMENT}"
echo
echo "== What will NOT be removed =="
echo "  - wrapper scripts"
echo "  - package.json"
echo "  - PHP app files"
echo "  - Node.js / system packages"
echo

read -r -p "Proceed with removal? (y/N): " REPLY2
case "$REPLY2" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "Cancelled."; exit 1 ;;
esac

# ------------------------------------------------------------
# Run uninstall steps
# ------------------------------------------------------------
echo
bash "${UTILS_DIR}/06a-uninstall-playwright.sh"
echo
bash "${UTILS_DIR}/06b-uninstall-sudoers.sh"
echo

echo "== Uninstall complete =="
echo

# ------------------------------------------------------------
# Run post-uninstall verification
# ------------------------------------------------------------
echo "== Running post-uninstall verification =="
echo

bash "${BASE_DIR}/pw-02b-uninstall-verify.sh" || true

echo
echo "== Uninstall + Verify complete =="

# ------------------------------------------------------------
# Final cleanup: remove playwright-env.sh
# ------------------------------------------------------------
if [[ -f "$ENV_FILE" ]]; then
    echo "  - Removing playwright-env.sh file"
    rm -f "$ENV_FILE"
else
    echo "  - playwright-env.sh file already removed"
fi
