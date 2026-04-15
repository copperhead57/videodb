#!/bin/bash
# pw-sudo-04-detect.sh
# Read-only diagnostic for Playwright + XAMPP/Apache sudo setup
# Updated for unified imdb-fetch-unix.mjs (2026)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYROOT="${PLAYROOT:-$SCRIPT_DIR}"

XVFB_WRAPPER="$PLAYROOT/xvfb.sh"
NODE_CLEAN="$PLAYROOT/node-clean.sh"
FETCHER="$PLAYROOT/imdb-fetch-unix.mjs"
SUDOERS_FILE="/etc/sudoers.d/videodb-playwright"

echo "==========================================================="
echo " Playwright / Webserver Diagnostic (Unified .mjs Version)"
echo "==========================================================="
echo "PLAYROOT: $PLAYROOT"
echo



# ---------------------------------------------------------
# 1. Apache/XAMPP processes
# ---------------------------------------------------------
echo "1) Apache/XAMPP processes (user + args):"
APACHE_PROCS="$(ps -eo user,pid,ppid,comm,args | grep -E 'httpd|apache|lampp' | grep -v grep || true)"
if [ -z "$APACHE_PROCS" ]; then
  echo "  (no httpd/apache/lampp processes found)"
else
  echo "$APACHE_PROCS"
fi
echo



# ---------------------------------------------------------
# 2. Detect webserver user
# ---------------------------------------------------------
echo "2) Detected webserver user:"
WEBUSER="$(ps -eo user,args | awk '$2 ~ /httpd/ && $1!="root" {print $1; exit}')"
WEBUSER="${WEBUSER:-daemon}"
WEBUSER="${WEBUSER:-www-data}"
WEBUSER="${WEBUSER:-apache}"
WEBUSER="${WEBUSER:-http}"
echo "  WEBUSER: $WEBUSER"
echo



# ---------------------------------------------------------
# 3. Detect desktop user
# ---------------------------------------------------------
echo "3) Desktop user candidates:"
echo "  who:"
who || true
echo
echo "  loginctl:"
loginctl list-sessions --no-legend 2>/dev/null || echo "  (no loginctl sessions)"
echo

DESKTOP_USER="$(who | awk '/:0|:1/ {print $1; exit}')"
DESKTOP_USER="${DESKTOP_USER:-$(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $3; exit}')}"
DESKTOP_USER="${DESKTOP_USER:-$(awk -F: '($3>=1000)&&($1!~/^(nobody|systemd|daemon)/){print $1; exit}' /etc/passwd)}"

echo "  Detected DESKTOP_USER: $DESKTOP_USER"
echo



# ---------------------------------------------------------
# 4. Sudoers entry
# ---------------------------------------------------------
echo "4) Sudoers entry (if present):"
if [ -f "$SUDOERS_FILE" ]; then
  SUDOERS_CONTENT="$(sudo cat "$SUDOERS_FILE" 2>/dev/null || true)"
  echo "$SUDOERS_CONTENT"
else
  echo "  $SUDOERS_FILE not found"
fi
echo



# ---------------------------------------------------------
# 5. Wrapper + helper presence and perms
# ---------------------------------------------------------
echo "5) Wrapper + helper presence and permissions:"
for f in "$XVFB_WRAPPER" "$NODE_CLEAN" "$FETCHER"; do
  if [ -f "$f" ]; then
    ls -l "$f"
  else
    echo "  MISSING: $f"
  fi
done
echo



# ---------------------------------------------------------
# 6. Suggested manual test command
# ---------------------------------------------------------
echo "6) Suggested manual test command:"
echo "  sudo -u $WEBUSER sudo -n -u $DESKTOP_USER \\"
echo "    $XVFB_WRAPPER $NODE_CLEAN \\"
echo "    $FETCHER \"https://www.imdb.com\""
echo



# ---------------------------------------------------------
# 7. Summary (PASS / FAIL)
# ---------------------------------------------------------
echo "==========================================================="
echo " Summary"
echo "==========================================================="

# Apache running?
if [ -z "$APACHE_PROCS" ]; then
  echo "❌ Apache is NOT running — Playwright cannot be triggered from PHP."
else
  echo "✔ Apache is running."
fi

# Webuser correct?
if [[ "$WEBUSER" == "daemon" ]]; then
  echo "✔ Webserver user correctly detected as 'daemon' (XAMPP)."
else
  echo "⚠ Webserver user detected as '$WEBUSER' — expected 'daemon' for XAMPP."
fi

# Sudoers correct?
if echo "$SUDOERS_CONTENT" | grep -q "$WEBUSER ALL=($DESKTOP_USER)"; then
  echo "✔ Sudoers entry matches expected configuration."
else
  echo "❌ Sudoers entry does NOT match expected configuration."
fi

# Wrapper perms?
if [ -f "$XVFB_WRAPPER" ] && ls -l "$XVFB_WRAPPER" | grep -q "root $DESKTOP_USER"; then
  echo "✔ Wrapper permissions look correct."
else
  echo "❌ Wrapper permissions incorrect or missing."
fi

# Unified fetcher perms?
if [ -f "$FETCHER" ] && ls -l "$FETCHER" | grep -q "root $DESKTOP_USER"; then
  echo "✔ Unified fetcher permissions OK."
else
  echo "❌ Unified fetcher permissions incorrect or missing."
fi

echo
echo "==========================================================="
echo " End diagnostic"
echo "==========================================================="
