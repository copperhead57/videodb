#!/bin/bash
# ============================================================
# pw-03-runtest.sh
# Test IMDb Fetcher (Unix/macOS)
# ============================================================

URL="$1"

if [ -z "$URL" ]; then
    echo "Usage: ./pw-03-runtest.sh <url>"
    exit 1
fi

echo "=== Running Playwright Test (Unix/macOS) ==="
echo "URL: $URL"

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Node binary
NODE_BIN="$SCRIPT_DIR/node"

# Generic fetcher
FETCHER="$SCRIPT_DIR/imdb-fetch.js"

# Run fetcher
RAW_OUTPUT=$("$NODE_BIN" "$FETCHER" "$URL" 2>/dev/null)

# Extract JSON without HTML
JSON_NO_HTML=$(echo "$RAW_OUTPUT" | sed 's/"html":".*"/"html":"<removed>"/')

# Extract HTML preview (first 50 chars)
HTML_PREVIEW=$(echo "$RAW_OUTPUT" | sed -n 's/.*"html":"\([^"]*\)".*/\1/p' | cut -c1-50)

echo
echo "--- JSON (excluding html) ---"
echo "$JSON_NO_HTML"

echo
echo "--- HTML Preview (first 50 chars) ---"
echo "$HTML_PREVIEW"
echo "-------------------------------------"

echo "=== Test Complete ==="