#!/bin/bash
# ============================================================
# pw-01-verify.sh
# Verify NAS Playwright Environment (Dynamic Version-Aware)
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
PW_PKG="$PLAYWRIGHT_DIR/node_modules/playwright/package.json"

if [ -f "$PW_PKG" ]; then
    INSTALLED_VERSION=$(node -p "require('$PW_PKG').version")
    echo "[OK] Playwright Node library installed: v$INSTALLED_VERSION"
else
    echo "[FAIL] Playwright Node library missing"
    INSTALLED_VERSION=""
fi

# ------------------------------------------------------------
# List all Playwright Docker images
# ------------------------------------------------------------
echo ""
echo "[INFO] Available Playwright Docker images:"
docker images | grep "mcr.microsoft.com/playwright" || echo "  (none found)"
echo ""

# ------------------------------------------------------------
# Check matching Docker image
# ------------------------------------------------------------
if [ -z "$INSTALLED_VERSION" ]; then
    echo "[INFO] Skipping Docker image match check (Playwright not installed)"
else
    if docker images | grep -q "mcr.microsoft.com/playwright.*v${INSTALLED_VERSION}-jammy"; then
        echo "[OK] Matching Docker image found: v${INSTALLED_VERSION}-jammy"
    else
        echo "[FAIL] No matching Docker image for v${INSTALLED_VERSION}"
    fi
fi


# ------------------------------------------------------------
# Warn if multiple versions exist
# ------------------------------------------------------------
IMAGE_COUNT=$(docker images | grep -c "mcr.microsoft.com/playwright")

if [ "$IMAGE_COUNT" -gt 1 ]; then
    echo "[WARN] Multiple Playwright Docker images detected ($IMAGE_COUNT total)"

    if [ -z "$INSTALLED_VERSION" ]; then
        echo "       None will be used until Playwright is installed."
    else
        echo "       Only v${INSTALLED_VERSION}-jammy will be used by the app."
    fi
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

echo ""
echo "=== Verification Complete ==="
