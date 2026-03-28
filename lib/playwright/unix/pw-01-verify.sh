#!/bin/bash
# ============================================================
# pw-01-verify.sh
# Portable Playwright Environment Verification (Unix/macOS)
# ============================================================

echo "=== Playwright Portable Environment Verification (Unix/macOS) ==="

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Node binaries
NODE_BIN="$SCRIPT_DIR/node"
NPM_BIN="$SCRIPT_DIR/npm"
NPX_BIN="$SCRIPT_DIR/npx"

# Playwright paths
PW_NODE_MODULES="$SCRIPT_DIR/node_modules"
PW_CLI="$PW_NODE_MODULES/playwright/cli.js"
BROWSER_DIR="$PW_NODE_MODULES/playwright-core/.local-browsers"

# ------------------------------------------------------------
# Helper function
# ------------------------------------------------------------
check() {
    if [ "$2" = "OK" ]; then
        printf "[OK]   %s\n" "$1"
    else
        printf "[FAIL] %s\n" "$1"
    fi
}

# ------------------------------------------------------------
# 1. Check Node
# ------------------------------------------------------------
if [ -x "$NODE_BIN" ]; then
    NODE_VER=$("$NODE_BIN" -v 2>/dev/null)
    check "node ($NODE_VER)" "OK"
else
    check "node" "FAIL"
fi

# ------------------------------------------------------------
# 2. Check npm
# ------------------------------------------------------------
if [ -x "$NPM_BIN" ]; then
    NPM_VER=$("$NPM_BIN" -v 2>/dev/null)
    check "npm ($NPM_VER)" "OK"
else
    check "npm" "FAIL"
fi

# ------------------------------------------------------------
# 3. Check npx
# ------------------------------------------------------------
if [ -x "$NPX_BIN" ]; then
    check "npx" "OK"
else
    check "npx" "FAIL"
fi

# ------------------------------------------------------------
# 4. Check Playwright package
# ------------------------------------------------------------
if [ -d "$PW_NODE_MODULES/playwright" ]; then
    check "playwright package" "OK"
else
    check "playwright package" "FAIL"
fi

# ------------------------------------------------------------
# 5. Check Playwright CLI
# ------------------------------------------------------------
if [ -f "$PW_CLI" ]; then
    check "playwright CLI" "OK"
else
    check "playwright CLI" "FAIL"
fi

# ------------------------------------------------------------
# 6. Check Chromium browser bundle
# ------------------------------------------------------------
if [ -d "$BROWSER_DIR" ]; then
    check "Chromium browser bundle" "OK"
else
    check "Chromium browser bundle" "FAIL"
fi

echo "=== Verification Complete ==="