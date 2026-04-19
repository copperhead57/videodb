#!/bin/sh
echo "=== Playwright Environment Verification (Linux/macOS Headful) ==="

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

BASE_DIR="$(dirname "$0")"
PW_ROOT="$BASE_DIR"
BROWSER_ROOT="$BASE_DIR/$OS_DIR/browsers"
RUNTIME_PROFILE="$BASE_DIR/chrome-profile"
RUNTIME_HOME="$BASE_DIR/chrome-home"

check() {
    label="$1"
    path="$2"

    if [ -e "$path" ]; then
        echo "[OK]   $label"
    else
        echo "[FAIL] $label"
    fi
}

echo "--- OS Detection ---"
echo "[OK]   Detected OS: $OS → using folder: $OS_DIR"
echo ""


# ------------------------------------------------------------
# Node Runtime
# ------------------------------------------------------------
echo "--- Node Runtime ---"

node -v >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "[OK]   node (system-wide): $(node -v)"
else
    echo "[FAIL] node (system-wide not found)"
fi

npm -v >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "[OK]   npm (system-wide): $(npm -v)"
else
    echo "[FAIL] npm (system-wide not found)"
fi

echo ""


# ------------------------------------------------------------
# Playwright Project Structure
# ------------------------------------------------------------
echo "--- Playwright Project Structure ---"

check "package.json" "$PW_ROOT/package.json"
check "node_modules folder" "$PW_ROOT/node_modules"
check "Playwright package" "$PW_ROOT/node_modules/playwright"
check "Playwright Core" "$PW_ROOT/node_modules/playwright-core"
check "Playwright CLI" "$PW_ROOT/node_modules/playwright/cli.js"

echo ""


# ------------------------------------------------------------
# Playwright Browsers
# ------------------------------------------------------------
echo "--- Playwright Browsers ($OS_DIR) ---"

check "Browser root folder" "$BROWSER_ROOT"

# Chromium
chromium=$(ls "$BROWSER_ROOT" 2>/dev/null | grep '^chromium-' | head -n 1)
if [ -n "$chromium" ]; then
    echo "[OK]   Chromium installed ($chromium)"
else
    echo "[FAIL] Chromium not found"
fi

# Firefox
firefox=$(ls "$BROWSER_ROOT" 2>/dev/null | grep '^firefox-' | head -n 1)
if [ -n "$firefox" ]; then
    echo "[OK]   Firefox installed ($firefox)"
else
    echo "[FAIL] Firefox not found"
fi

# WebKit
webkit=$(ls "$BROWSER_ROOT" 2>/dev/null | grep '^webkit-' | head -n 1)
if [ -n "$webkit" ]; then
    echo "[OK]   WebKit installed ($webkit)"
else
    echo "[FAIL] WebKit not found"
fi

# FFmpeg
ffmpeg=$(ls "$BROWSER_ROOT" 2>/dev/null | grep '^ffmpeg-' | head -n 1)
if [ -n "$ffmpeg" ]; then
    echo "[OK]   FFmpeg installed ($ffmpeg)"
else
    echo "[FAIL] FFmpeg not found"
fi

echo ""


# ------------------------------------------------------------
# Runtime Folders (chrome-profile + chrome-home)
# ------------------------------------------------------------
echo "--- Playwright Runtime Folders ---"

check "chrome-profile folder" "$RUNTIME_PROFILE"
check "chrome-home folder" "$RUNTIME_HOME"

check "chrome-home/.config/Crashpad" "$RUNTIME_HOME/.config/Crashpad"
check "chrome-home/.cache" "$RUNTIME_HOME/.cache"
check "chrome-home/.local/share" "$RUNTIME_HOME/.local/share"

echo ""


# ------------------------------------------------------------
# Headful Mode Dependencies
# ------------------------------------------------------------
echo "--- Headful Mode Dependencies ---"

if [ "$OS" = "Linux" ]; then
    # GTK3
    ldconfig -p | grep -q libgtk-3.so
    if [ $? -eq 0 ]; then
        echo "[OK]   GTK3 present"
    else
        echo "[FAIL] GTK3 missing"
    fi

    # X11
    ldconfig -p | grep -qi "libX11"
    if [ $? -eq 0 ]; then
        echo "[OK]   X11 present"
    else
        echo "[FAIL] X11 missing"
    fi

    # NSS
    ldconfig -p | grep -q libnss3.so
    if [ $? -eq 0 ]; then
        echo "[OK]   NSS present"
    else
        echo "[FAIL] NSS missing"
    fi
else
    echo "[INFO] macOS does not require GTK/X11/NSS checks"
fi

echo ""
echo "=== Verification complete ==="

printf "Press Enter to exit..."
read dummy
