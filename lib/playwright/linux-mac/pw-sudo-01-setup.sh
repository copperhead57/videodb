#!/bin/bash
# pw-sudo-01-setup.sh (UPDATED FOR unified .mjs)
# Universal, auto-detecting, XAMPP-safe Playwright sudo setup
# Run as root:
#   sudo PLAYROOT=/full/path/to/lib/playwright/linux-mac ./setup-playwright-sudo.sh

set -euo pipefail

# ---------------------------------------------------------
# Resolve script directory and PLAYROOT
# ---------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYROOT="${PLAYROOT:-$SCRIPT_DIR}"

echo "---------------------------------------------------------"
echo " Playwright Sudo Setup (linux-mac)"
echo "---------------------------------------------------------"
echo "Detected PLAYROOT directory:"
echo "    $PLAYROOT"
echo
echo "This will modify permissions for the following files:"
echo "  • xvfb.sh"
echo "  • node-clean.sh"
echo "  • imdb-fetch-unix.mjs"
echo
read -p "Proceed with this directory? (y/N): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Setup cancelled."
    exit 0
fi

XVFB_WRAPPER="$PLAYROOT/xvfb.sh"
NODE_CLEAN="$PLAYROOT/node-clean.sh"
FETCHER_MJS="$PLAYROOT/imdb-fetch-unix.mjs"
SUDOERS_FILE="/etc/sudoers.d/videodb-playwright"

# ---------------------------------------------------------
# 1. Detect webserver user (XAMPP-first)
# ---------------------------------------------------------
WEBUSER="$(ps -eo user,args | awk '$2 ~ /httpd/ && $1!="root" {print $1; exit}')"
WEBUSER="${WEBUSER:-daemon}"
WEBUSER="${WEBUSER:-www-data}"
WEBUSER="${WEBUSER:-apache}"
WEBUSER="${WEBUSER:-http}"

# ---------------------------------------------------------
# 2. Detect desktop user
# ---------------------------------------------------------
DESKTOP_USER="$(who | awk '/:0|:1/ {print $1; exit}')"
DESKTOP_USER="${DESKTOP_USER:-$(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $3; exit}')}"
DESKTOP_USER="${DESKTOP_USER:-$(awk -F: '($3>=1000)&&($1!~/^(nobody|systemd|daemon)/){print $1; exit}' /etc/passwd)}"

if [ -z "$DESKTOP_USER" ]; then
  echo "ERROR: Could not detect a desktop user." >&2
  exit 1
fi

# Must run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script as root (sudo)." >&2
  exit 2
fi

# ---------------------------------------------------------
# 3. Ensure wrapper scripts exist
# ---------------------------------------------------------
if [ ! -f "$XVFB_WRAPPER" ]; then
  echo "ERROR: Missing $XVFB_WRAPPER"
  exit 3
fi

if [ ! -f "$NODE_CLEAN" ]; then
  echo "ERROR: Missing $NODE_CLEAN"
  exit 4
fi

if [ ! -f "$FETCHER_MJS" ]; then
  echo "ERROR: Missing $FETCHER_MJS"
  exit 5
fi

# ---------------------------------------------------------
# 4. Secure permissions (but allow developer editing)
# ---------------------------------------------------------
echo "--- Setting ownership and permissions ---"
chown root:"$DESKTOP_USER" "$XVFB_WRAPPER" "$NODE_CLEAN" "$FETCHER_MJS"
chmod 770 "$XVFB_WRAPPER" "$NODE_CLEAN" "$FETCHER_MJS"

# ---------------------------------------------------------
# 5. Write sudoers entry
# ---------------------------------------------------------
echo "--- Writing sudoers entry ---"
cat > "$SUDOERS_FILE" <<EOF
Defaults:$WEBUSER !requiretty
$WEBUSER ALL=($DESKTOP_USER) NOPASSWD: $XVFB_WRAPPER
$WEBUSER ALL=($DESKTOP_USER) NOPASSWD: $NODE_CLEAN
$WEBUSER ALL=($DESKTOP_USER) NOPASSWD: $FETCHER_MJS
EOF

chmod 0440 "$SUDOERS_FILE"

# Validate sudoers file
if ! visudo -c -f "$SUDOERS_FILE" >/dev/null 2>&1; then
  echo "ERROR: sudoers validation failed." >&2
  exit 6
fi

# ---------------------------------------------------------
# Summary
# ---------------------------------------------------------
cat <<SUMMARY

Playwright sudo setup complete (linux-mac)
PLAYROOT:        $PLAYROOT
WEBUSER:         $WEBUSER
DESKTOP_USER:    $DESKTOP_USER
XVFB_WRAPPER:    $XVFB_WRAPPER
NODE_CLEAN:      $NODE_CLEAN
FETCHER_MJS:     $FETCHER_MJS
SUDOERS_FILE:    $SUDOERS_FILE

Test command:
  sudo -u $WEBUSER sudo -n -u $DESKTOP_USER \\
    $XVFB_WRAPPER $NODE_CLEAN \\
    $FETCHER_MJS "https://www.imdb.com"

SUMMARY
