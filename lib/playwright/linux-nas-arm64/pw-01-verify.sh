#!/bin/bash
# ============================================================
# pw-01-verify.sh
# Verify NAS Playwright Environment (v1.58.x)
# Includes Docker socket permission check
# ============================================================

echo "=== Verifying NAS Playwright Environment ==="

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Project root = playwright → lib → videodb-devcode
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/../../..")"
PLAYWRIGHT_DIR="$SCRIPT_DIR"

echo "[INFO] Script directory: $SCRIPT_DIR"
echo "[INFO] Project root:     $PROJECT_ROOT"

# ------------------------------------------------------------
# Check Node
# ------------------------------------------------------------
if ! command -v node >/dev/null 2>&1; then
    echo "[FAIL] Node.js not installed"
    exit 1
else
    echo "[OK] Node.js installed: $(node -v)"
fi

# ------------------------------------------------------------
# Check npm
# ------------------------------------------------------------
if ! command -v npm >/dev/null 2>&1; then
    echo "[FAIL] npm not installed"
    exit 1
else
    echo "[OK] npm installed: $(npm -v)"
fi

# ------------------------------------------------------------
# Check Docker
# ------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
    echo "[FAIL] Docker not installed"
    exit 1
else
    echo "[OK] Docker installed: $(docker -v)"
fi

# ------------------------------------------------------------
# Check Playwright Node library
# ------------------------------------------------------------
if [ -d "$PLAYWRIGHT_DIR/node_modules/playwright" ]; then
    echo "[OK] Playwright Node library installed"
else
    echo "[FAIL] Playwright Node library missing"
fi

# ------------------------------------------------------------
# Check Playwright Docker image
# ------------------------------------------------------------
if docker images | grep -q "mcr.microsoft.com/playwright.*v1.58.2-jammy"; then
    echo "[OK] Playwright Docker image present"
else
    echo "[FAIL] Playwright Docker image missing"
fi

# ------------------------------------------------------------
# Check Docker socket exists
# ------------------------------------------------------------
SOCK="/var/run/docker.sock"

if [ ! -S "$SOCK" ]; then
    echo "[FAIL] Docker socket missing: $SOCK"
    echo "       Docker may not be running yet."
    exit 1
else
    echo "[OK] Docker socket exists"
fi

# ------------------------------------------------------------
# Check Docker socket permissions
# ------------------------------------------------------------
PERMS="$(stat -c %a "$SOCK" 2>/dev/null)"
OWNER="$(stat -c %U "$SOCK" 2>/dev/null)"
GROUP="$(stat -c %G "$SOCK" 2>/dev/null)"

echo "[INFO] Socket owner: $OWNER"
echo "[INFO] Socket group: $GROUP"
echo "[INFO] Socket perms: $PERMS"

if [ "$PERMS" = "666" ]; then
    echo "[OK] Docker socket permissions are correct (666)"
else
    echo "[FAIL] Docker socket permissions incorrect"
    echo "       Expected: 666"
    echo "       Found:    $PERMS"
    echo
    echo "This means the boot‑fix is NOT active."
    echo "Run: pw-04-install-docker-socket-fix.sh"
    exit 1
fi

echo "=== Verification Complete ==="
