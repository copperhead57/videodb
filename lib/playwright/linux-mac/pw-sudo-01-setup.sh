#!/bin/bash
# pw-sudo-01-setup.sh
# Playwright sudo setup with explicit menu selection
# Safe for repo use — no auto-detection, no guessing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYROOT="${PLAYROOT:-$SCRIPT_DIR}"

XVFB="$PLAYROOT/xvfb.sh"
NODECLEAN="$PLAYROOT/node-clean.sh"
FETCHER="$PLAYROOT/imdb-fetch-unix.mjs"

SUDOERS_FILE="/etc/sudoers.d/videodb-playwright"

echo "---------------------------------------------------------"
echo " Playwright Sudo Setup (Menu Version)"
echo "---------------------------------------------------------"
echo "PLAYROOT detected as:"
echo "  $PLAYROOT"
echo
echo "Scripts to authorize:"
echo "  • $XVFB"
echo "  • $NODECLEAN"
echo "  • $FETCHER"
echo

# ---------------------------------------------------------
# 1. Ask user which webserver(s) to configure
# ---------------------------------------------------------
echo "Which webserver should be configured?"
echo "  1) Native Apache (www-data)"
echo "  2) XAMPP Apache (daemon)"
echo "  3) Both"
echo

read -p "Select option (1/2/3): " CHOICE

case "$CHOICE" in
  1) USERS=("www-data");;
  2) USERS=("daemon");;
  3) USERS=("www-data" "daemon");;
  *)
     echo "Invalid choice. Exiting."
     exit 1
     ;;
esac

# ---------------------------------------------------------
# 2. Must run as root
# ---------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: This script must be run as root (sudo)."
  exit 2
fi

# ---------------------------------------------------------
# 3. Validate scripts exist
# ---------------------------------------------------------
for f in "$XVFB" "$NODECLEAN" "$FETCHER"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: Missing required file: $f"
    exit 3
  fi
done

# ---------------------------------------------------------
# 4. Set safe permissions (developer-editable)
# ---------------------------------------------------------
echo "--- Setting permissions ---"
chmod 770 "$XVFB" "$NODECLEAN" "$FETCHER"

# ---------------------------------------------------------
# 5. Write sudoers file
# ---------------------------------------------------------
echo "--- Writing sudoers file ---"

{
  echo "# Playwright sudo rules"
  echo "Defaults:www-data !requiretty"
  echo "Defaults:daemon !requiretty"
  echo

  for U in "${USERS[@]}"; do
    echo "$U ALL=($U) NOPASSWD: $XVFB"
    echo "$U ALL=($U) NOPASSWD: $NODECLEAN"
    echo "$U ALL=($U) NOPASSWD: $FETCHER"
    echo
  done
} > "$SUDOERS_FILE"

chmod 440 "$SUDOERS_FILE"

# Validate
if ! visudo -c -f "$SUDOERS_FILE" >/dev/null 2>&1; then
  echo "ERROR: sudoers validation failed."
  exit 4
fi

# ---------------------------------------------------------
# Summary
# ---------------------------------------------------------
echo
echo "---------------------------------------------------------"
echo " Playwright sudo setup complete"
echo "---------------------------------------------------------"
echo "PLAYROOT:      $PLAYROOT"
echo "SUDOERS FILE:  $SUDOERS_FILE"
echo "Configured for users:"
for U in "${USERS[@]}"; do
  echo "  • $U"
done

echo
echo "Test command:"
echo "  sudo -u www-data sudo -n -u www-data $XVFB $NODECLEAN $FETCHER \"https://www.imdb.com\""
echo
echo "Done."
