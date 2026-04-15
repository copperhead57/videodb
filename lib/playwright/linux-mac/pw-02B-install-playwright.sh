#!/bin/sh
echo "=== Playwright Headful Environment Installer (Linux/macOS) ==="

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
# STEP 1 — Verify system-wide Node
# ------------------------------------------------------------
echo "--- Step 1: Checking Node installation ---"

node -v >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[FAIL] Node is not installed."
    echo "Please install Node 24+ before running this script."
    exit 1
fi

echo "[OK] Node version: $(node -v)"
echo "[OK] npm version:  $(npm -v)"
pause


# ------------------------------------------------------------
# STEP 2 — Create package.json (if missing)
# ------------------------------------------------------------
echo "--- Step 2: Ensuring package.json exists ---"

if [ ! -f "./package.json" ]; then
    echo "package.json not found — creating..."
    npm init -y
    echo "[OK] package.json created."
else
    echo "[OK] package.json already exists."
fi

pause


# ------------------------------------------------------------
# STEP 3 — Install Playwright package
# ------------------------------------------------------------
echo "--- Step 3: Installing Playwright ---"

npm install playwright
if [ $? -ne 0 ]; then
    echo "[FAIL] Playwright installation failed."
    exit 1
fi

echo "[OK] Playwright installed."
pause


# ------------------------------------------------------------
# STEP 4 — Install Playwright browsers
# ------------------------------------------------------------
echo "--- Step 4: Installing Playwright browsers ---"

PLAYWRIGHT_BROWSERS_PATH="./$OS_DIR/browsers" \
npx playwright install

if [ $? -ne 0 ]; then
    echo "[FAIL] Browser installation failed."
    exit 1
fi

echo "[OK] Browsers installed into ./$OS_DIR/browsers/"
pause


# ------------------------------------------------------------
# STEP 5 — Install GUI dependencies (Linux only)
# ------------------------------------------------------------
if [ "$OS" = "Linux" ]; then
    echo "--- Step 5: Installing GUI dependencies (sudo required) ---"
    sudo npx playwright install-deps
    if [ $? -ne 0 ]; then
        echo "[FAIL] GUI dependency installation failed."
        exit 1
    fi
    echo "[OK] GUI dependencies installed."
else
    echo "--- Step 5: Skipped (macOS does not require install-deps) ---"
fi

pause


# ------------------------------------------------------------
# STEP 6 — Final verification
# ------------------------------------------------------------
echo "--- Step 6: Running verification script ---"

if [ -f "./pw-01-verify.sh" ]; then
    ./pw-01-verify.sh
else
    echo "[WARN] Verification script not found."
fi

echo ""
echo "=== Playwright installation complete ==="
printf "Press Enter to exit..."
read dummy
