#!/bin/sh
echo "=== Playwright Cache Cleanup ==="

CACHE_DIR="$HOME/.cache/ms-playwright"

if [ -d "$CACHE_DIR" ]; then
    echo "--- Removing Playwright cache ---"
    rm -rf "$CACHE_DIR"
    echo "[OK] Cache removed: $CACHE_DIR"
else
    echo "[INFO] No Playwright cache found at: $CACHE_DIR"
fi

echo ""
echo "=== Cache cleanup complete ==="
printf "Press Enter to exit..."
read dummy
