#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="${BASE_DIR}/install-utils"

echo "== Playwright Headless Installer =="

echo
echo "This installer will:"
echo "  • Detect whether you are running System Apache or XAMPP/LAMPP"
echo "  • Verify Node.js availability"
echo "  • Configure sudo rules for Apache → pdb privilege chain"
echo "  • Install Playwright (system-install mode: PLAYWRIGHT_BROWSERS_PATH=0)"
echo "  • Install Chromium browsers into playwright-core/.local-browsers"
echo "  • Run a full verification of the entire chain"
echo
echo "Proceed? (y/N)"
read -r REPLY

case "$REPLY" in
    [yY]|[yY][eE][sS])
        echo
        echo "[OK] Starting installation..."
        ;;
    *)
        echo
        echo "[CANCELLED] No changes were made."
        exit 1
        ;;
esac

echo
echo "[00] Making install-utils scripts executable..."
bash "${UTILS_DIR}/00-make-executables.sh"
echo "[00] Done."
echo

echo "[01] Detecting environment (system vs XAMPP)..."
bash "${UTILS_DIR}/01-detect-environment.sh"
echo "[01] Done."
echo

echo "[02] Verifying Node.js..."
bash "${UTILS_DIR}/02-install-node.sh"
echo "[02] Done."
echo

echo "[03] Configuring sudo rules for Apache → pdb..."
sudo bash "${UTILS_DIR}/03-sudo-setup.sh"
echo "[03] Done."
echo

echo "[04] Installing Playwright (system-install mode)..."
bash "${UTILS_DIR}/04-install-playwright.sh"
echo "[04] Done."
echo

echo "[07] Running full verification..."
bash "${UTILS_DIR}/07-verify-install.sh"
echo "[07] Done."
echo

echo "== Install complete =="
