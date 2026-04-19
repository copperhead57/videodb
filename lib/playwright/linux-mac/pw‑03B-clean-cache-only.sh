#!/bin/sh
echo "=== Playwright Cache Cleaner (Linux/macOS) ==="

pause() {
    printf "\nPress Enter to continue, or Ctrl+C to cancel..."
    read dummy
    echo ""
}

# Detect OS
OS="$(uname)"
if [ "$OS" = "Linux" ]; then
    OS_DIR="linux"
elif [ "$OS" = "Darwin" ]; then
    OS_DIR="mac"
else
    echo "[FAIL] Unsupported OS: $OS"
    exit 1
fi

BASE_DIR="$(dirname "$0")/../linux-mac"
cd "$BASE_DIR" || exit 1

echo "[OK] Detected OS: $OS → using folder: $OS_DIR"
pause


# ------------------------------------------------------------
# STEP 1 — Clean chrome-home caches
# ------------------------------------------------------------
echo "--- Step 1: Cleaning chrome-home caches ---"

if [ -d "./chrome-home/.cache" ]; then
    sudo -u www-data rm -rf "./chrome-home/.cache"/*
    echo "[OK] chrome-home/.cache cleared."
else
    echo "[INFO] chrome-home/.cache not found."
fi

pause


# ------------------------------------------------------------
# STEP 2 — Clean chrome-profile browser caches
# ------------------------------------------------------------
echo "--- Step 2: Cleaning chrome-profile browser caches ---"

PROFILE_DIR="./chrome-profile/Default"

if [ -d "$PROFILE_DIR" ]; then
    sudo -u www-data rm -rf "$PROFILE_DIR/Cache" 2>/dev/null || true
    sudo -u www-data rm -rf "$PROFILE_DIR/GPUCache" 2>/dev/null || true
    sudo -u www-data rm -rf "$PROFILE_DIR/Code Cache" 2>/dev/null || true

    echo "[OK] Browser caches cleared in chrome-profile/Default/"
else
    echo "[INFO] chrome-profile/Default not found — nothing to clean."
fi

pause


# ------------------------------------------------------------
# DONE
# ------------------------------------------------------------
echo "=== Playwright cache cleaning complete ==="
printf "Press Enter to exit..."
read dummy

