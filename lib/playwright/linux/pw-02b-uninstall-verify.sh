#!/usr/bin/env bash
set -euo pipefail

echo "== Playwright Uninstall Verification =="

# ------------------------------------------------------------
# Resolve PLAYROOT (this script lives in lib/playwright/linux)
# ------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYROOT="$SCRIPT_DIR"

ENV_FILE="${PLAYROOT}/playwright-env.sh"
DETECT_SCRIPT="${PLAYROOT}/install-utils/01-detect-environment.sh"
VERIFY_SCRIPT="${PLAYROOT}/install-utils/07-verify-uninstall.sh"

echo "PLAYROOT: $PLAYROOT"
echo

# ------------------------------------------------------------
# Ensure env file exists (fallback to detect)
# ------------------------------------------------------------
if [[ ! -f "$ENV_FILE" ]]; then
    echo "[WARN] Environment file not found:"
    echo "       $ENV_FILE"
    echo "       Running detect to rebuild it..."
    echo

    bash "$DETECT_SCRIPT" || true

    if [[ ! -f "$ENV_FILE" ]]; then
        echo "[WARN] Env file still missing after detect."
        echo "       This is normal if uninstall already removed it."
        echo "       Verification will continue using fallback logic."
        echo
    fi
fi

# ------------------------------------------------------------
# Run uninstall verification
# ------------------------------------------------------------
if [[ -x "$VERIFY_SCRIPT" ]]; then
    echo "[verify] Running uninstall verification..."
    bash "$VERIFY_SCRIPT"
else
    echo "[FAIL] Verification script missing or not executable:"
    echo "       $VERIFY_SCRIPT"
    exit 1
fi

echo
echo "== Uninstall Verification Complete =="
