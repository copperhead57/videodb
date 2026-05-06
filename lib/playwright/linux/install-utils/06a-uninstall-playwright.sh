#!/usr/bin/env bash
set -euo pipefail

echo "[06a] Uninstalling Playwright runtime..."

# ------------------------------------------------------------
# Resolve PLAYROOT (same pattern as launcher)
# ------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYROOT="$(dirname "$SCRIPT_DIR")"     # .../lib/playwright/linux
ENV_FILE="${PLAYROOT}/playwright-env.sh"
DETECT_SCRIPT="${PLAYROOT}/install-utils/01-detect-environment.sh"

# ------------------------------------------------------------
# SAFETY: Ensure env file exists (fallback to detect)
# ------------------------------------------------------------
if [[ ! -f "$ENV_FILE" ]]; then
    echo "[WARN] Missing env file: $ENV_FILE"
    echo "       Running detect to rebuild it..."
    bash "$DETECT_SCRIPT"
fi

if [[ ! -f "$ENV_FILE" ]]; then
    echo "[FAIL] Cannot continue — env file still missing after detect."
    exit 1
fi

# Load authoritative environment
source "$ENV_FILE"

echo "PLAYROOT      : $PW_PLAYROOT"
echo "PROJECT_ROOT  : $PW_PROJECT_ROOT"
echo "PROJECT_NAME  : $PW_PROJECT_NAME"
echo "DESKTOP_USER  : $PW_DESKTOP_USER"
echo

# ------------------------------------------------------------
# Remove package-lock.json
# ------------------------------------------------------------
if [[ -f "${PW_PLAYROOT}/package-lock.json" ]]; then
    echo "  - Removing package-lock.json"
    rm -f "${PW_PLAYROOT}/package-lock.json"
else
    echo "  - package-lock.json already removed"
fi

# ------------------------------------------------------------
# Remove node_modules (entire folder)
# ------------------------------------------------------------
if [[ -d "${PW_PLAYROOT}/node_modules" ]]; then
    echo "  - Removing node_modules/"
    rm -rf "${PW_PLAYROOT}/node_modules"
else
    echo "  - node_modules already removed"
fi

# ------------------------------------------------------------
# Remove legacy folders if they exist (safe cleanup)
# ------------------------------------------------------------
for legacy in "chrome-profile" "chrome-home" "browsers"; do
    TARGET="${PW_PLAYROOT}/${legacy}"
    if [[ -d "$TARGET" ]]; then
        echo "  - Removing legacy folder: $legacy/"
        rm -rf "$TARGET"
    fi
done

echo "[06a] Playwright runtime removal complete."
