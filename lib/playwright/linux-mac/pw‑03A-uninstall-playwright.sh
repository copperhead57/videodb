#!/bin/sh
echo "=== Playwright Uninstaller (Linux/macOS) ==="

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
# STEP 1 — Remove Playwright package
# ------------------------------------------------------------
echo "--- Step 1: Removing Playwright npm package ---"

npm remove playwright playwright-core 2>/dev/null

echo "[OK] Playwright npm package removed."
pause


# ------------------------------------------------------------
# STEP 2 — Remove Playwright browsers
# ------------------------------------------------------------
echo "--- Step 2: Removing Playwright browser binaries ---"

if [ -d "./$OS_DIR/browsers" ]; then
    rm -rf "./$OS_DIR/browsers"
    echo "[OK] Removed ./$OS_DIR/browsers/"
else
    echo "[INFO] No browsers folder found."
fi

pause


# ------------------------------------------------------------
# STEP 3 — Remove Playwright runtime folders
# ------------------------------------------------------------
echo "--- Step 3: Removing Playwright runtime folders ---"

if [ -d "./chrome-profile" ]; then
    rm -rf "./chrome-profile"
    echo "[OK] Removed chrome-profile/"
else
    echo "[INFO] chrome-profile/ not found."
fi

if [ -d "./chrome-home" ]; then
    rm -rf "./chrome-home"
    echo "[OK] Removed chrome-home/"
else
    echo "[INFO] chrome-home/ not found."
fi

pause


# ------------------------------------------------------------
# STEP 4 — Optional cleanup
# ------------------------------------------------------------
echo "--- Step 4: Optional cleanup ---"

echo "Removing node_modules and package-lock.json? (y/n)"
read answer

if [ "$answer" = "y" ]; then
    rm -rf node_modules package-lock.json
    echo "[OK] node_modules and package-lock.json removed."
else
    echo "[INFO] Skipped optional cleanup."
fi

pause


# ------------------------------------------------------------
# DONE
# ------------------------------------------------------------
echo "=== Playwright uninstall complete ==="
printf "Press Enter to exit..."
read dummy
