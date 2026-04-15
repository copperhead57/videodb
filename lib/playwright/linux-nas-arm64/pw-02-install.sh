#!/bin/bash
# ============================================================
# pw-02-install.sh
# Install Playwright Node Library + Docker Image (v1.58.x)
# ============================================================

echo "=== Installing Playwright 1.58.x for Synology ==="

# Resolve script directory (synology/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Playwright directory is the script directory itself
PLAYWRIGHT_DIR="$SCRIPT_DIR"

echo "[INFO] Script directory: $SCRIPT_DIR"

cd "$PLAYWRIGHT_DIR" || exit 1

echo "--- Removing old node_modules ---"
rm -rf node_modules package-lock.json

echo "--- Installing Playwright 1.58.2 ---"
npm install playwright@1.58.2

echo "--- Pulling Docker Image (Jammy) ---"
docker pull mcr.microsoft.com/playwright:v1.58.2-jammy

echo "=== Install Complete ==="