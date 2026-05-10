#!/bin/bash
# ============================================================
# pw-03-runtest.sh
# Run a test fetch and show first 800 chars of HTML
# ============================================================

echo "=== Running Playwright Test Fetch ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

TEST_URL="https://www.imdb.com/title/tt0111161/"

# ------------------------------------------------------------
# Run fetcher
# ------------------------------------------------------------
RAW_OUTPUT=$(node imdb-fetch-linux-nas-headless.js "$TEST_URL")

# Strip ANSI escape codes (safety)
RAW_OUTPUT=$(echo "$RAW_OUTPUT" | sed 's/\x1b\[[0-9;]*m//g')

# ------------------------------------------------------------
# Extract JSON block safely
# ------------------------------------------------------------
JSON=$(echo "$RAW_OUTPUT" | awk '
    BEGIN { injson=0 }
    /^[[:space:]]*{/ { injson=1 }
    injson==1 { print }
    /^[[:space:]]*}/ { if (injson==1) exit }
')

if [ -z "$JSON" ]; then
    echo "[FAIL] No JSON detected in output"
    echo "--- Raw Output ---"
    echo "$RAW_OUTPUT"
    exit 1
fi

echo ""
echo "--- JSON (excluding html) ---"
echo "$JSON" | jq 'del(.html)'

# ------------------------------------------------------------
# Extract HTML
# ------------------------------------------------------------
HTML=$(echo "$JSON" | jq -r '.html // ""')

# ------------------------------------------------------------
# Show preview
# ------------------------------------------------------------
PREVIEW=$(echo "$HTML" | head -c 800)

echo ""
echo "--- HTML Preview (first 800 chars) ---"
echo "$PREVIEW"
echo "-------------------------------------"

echo "=== Test Complete ==="
