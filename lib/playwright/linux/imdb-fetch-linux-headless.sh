#!/bin/bash
# Wrapper for running the headless Playwright fetcher as user

echo "Fetcher Wrapper: imdb-fetch-linux-headless.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FETCHER="$SCRIPT_DIR/imdb-fetch-linux-headless.mjs"

# Use system-install mode (this is what you had when it worked)
export PLAYWRIGHT_BROWSERS_PATH=0

# Use FULL Chromium, NOT chrome-headless-shell
export PW_CHROMIUM_PATH="$(find "$SCRIPT_DIR/node_modules/playwright-core/.local-browsers" -type f -name 'chrome' | head -n 1)"

echo "PW_CHROMIUM_PATH: $PW_CHROMIUM_PATH"
echo "FETCHER         : $FETCHER"

exec /usr/bin/node "$FETCHER" "$1"
