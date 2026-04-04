#!/bin/bash
# ============================================================
# pw-01-verify.sh
# Verify Synology Playwright Environment (v1.58.x)
# ============================================================

echo "=== Verifying Synology Playwright Environment ==="

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Project root = synology → playwright → lib → videodb-devcode
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/../../..")"
PLAYWRIGHT_DIR="$SCRIPT_DIR"

echo "[INFO] Script directory: $SCRIPT_DIR"
echo "[INFO] Project root:     $PROJECT_ROOT"

# Check Node
if ! command -v node >/dev/null 2>&1; then
    echo "[FAIL] Node.js not installed"
    exit 1
else
    echo "[OK] Node.js installed: $(node -v)"
fi

# Check npm
if ! command -v npm >/dev/null 2>&1; then
    echo "[FAIL] npm not installed"
    exit 1
else
    echo "[OK] npm installed: $(npm -v)"
fi

# Check Docker
if ! command -v docker >/dev/null 2>&1; then
    echo "[FAIL] Docker not installed"
    exit 1
else
    echo "[OK] Docker installed: $(docker -v)"
fi

# Check Playwright Node library
if [ -d "$PLAYWRIGHT_DIR/node_modules/playwright" ]; then
    echo "[OK] Playwright Node library installed"
else
    echo "[FAIL] Playwright Node library missing"
fi

# Check Docker image
if docker images | grep -q "mcr.microsoft.com/playwright.*v1.58.2-jammy"; then
    echo "[OK] Playwright Docker image present"
else
    echo "[FAIL] Playwright Docker image missing"
fi

echo "=== Verification Complete ==="