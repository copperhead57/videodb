#!/bin/bash
# ============================================================
# pw-03-runtest.sh
# Run a test fetch and show first 50 chars of HTML
# ============================================================

echo "=== Running Playwright Test Fetch ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

TEST_URL="https://www.imdb.com/title/tt0111161/"

# Run fetch and capture output
RAW_OUTPUT=$(node imdb-fetch.js "$TEST_URL")

# Extract ONLY the JSON object (first { ... } block)
JSON=$(echo "$RAW_OUTPUT" | sed -n '/^{/,/}$/p')

echo ""
echo "--- JSON (excluding html) ---"
echo "$JSON" | jq 'del(.html)'

# Extract HTML safely
HTML=$(echo "$JSON" | jq -r '.html // ""')

# Show EXACT first 50 characters (no extra lines)
PREVIEW=$(echo "$HTML" | head -c 500)

echo ""
echo "--- HTML Preview (first 500 chars) ---"
echo "$PREVIEW"
echo "-------------------------------------"

echo "=== Test Complete ==="