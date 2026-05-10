#!/bin/bash
# ============================================================
# Playwright Installer (Latest-Aware, Deterministic)
# ============================================================

set -e

echo "----------------------------------------"
echo " Playwright Installer"
echo "----------------------------------------"

# Read current version from package.json (strip caret)
CURRENT_VERSION=$(node -p "require('./package.json').dependencies.playwright.replace('^','')")
echo "Current package.json version: $CURRENT_VERSION"

# Get latest version from npm
LATEST_VERSION=$(npm view playwright version)
echo "Latest available version: $LATEST_VERSION"
echo ""

# Compare versions
if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    echo "✔ You already have the latest Playwright version."
    PW_VERSION="$CURRENT_VERSION"
else
    echo "A newer Playwright version is available."
    echo "  1) Keep current version ($CURRENT_VERSION)"
    echo "  2) Upgrade to latest version ($LATEST_VERSION)"
    echo ""
    read -p "Enter choice (1 or 2): " CHOICE

    if [[ "$CHOICE" == "1" ]]; then
        PW_VERSION="$CURRENT_VERSION"
        echo "✔ Keeping version: $PW_VERSION"
    elif [[ "$CHOICE" == "2" ]]; then
        PW_VERSION="$LATEST_VERSION"
        echo "✔ Upgrading to: $PW_VERSION"
    else
        echo "Invalid choice"
        exit 1
    fi
fi

echo ""
echo "--- Removing old node_modules ---"
rm -rf node_modules package-lock.json

echo "--- Installing Playwright $PW_VERSION ---"
npm install "playwright@$PW_VERSION"

echo "--- Pulling Docker Image (Jammy) ---"
docker pull "mcr.microsoft.com/playwright:v${PW_VERSION}-jammy"

echo ""
echo "✔ Installation complete."
echo "Playwright version installed: $PW_VERSION"
echo "Docker image pulled: mcr.microsoft.com/playwright:v${PW_VERSION}-jammy"

