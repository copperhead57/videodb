#!/usr/bin/env bash
set -euo pipefail

# This launcher lives in: lib/playwright/linux/
# It calls the real executable fixer in: linux/install-utils/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="${SCRIPT_DIR}/install-utils"
TARGET="${UTILS_DIR}/00-make-executables.sh"

echo "[launcher] Running installer executable fixer"
echo "           → ${TARGET}"
echo

if [[ ! -f "$TARGET" ]]; then
    echo "[FAIL] Missing: ${TARGET}"
    exit 1
fi

if [[ ! -x "$TARGET" ]]; then
    echo "[launcher] Adding +x to 00-make-executables.sh"
    chmod +x "$TARGET"
fi

bash "$TARGET"

echo
echo "[launcher] Done."
