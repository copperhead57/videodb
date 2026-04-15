#!/bin/bash
# pw-sudo-02-verify.sh (UPDATED FOR unified .mjs)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYROOT="${PLAYROOT:-$SCRIPT_DIR}"

DESKTOP_USER="$(stat -c %G "$PLAYROOT/xvfb.sh")"
SUDOERS_FILE="/etc/sudoers.d/videodb-playwright"

FILES=(
  "$PLAYROOT/xvfb.sh"
  "$PLAYROOT/node-clean.sh"
  "$PLAYROOT/imdb-fetch-unix.mjs"
)

echo "---------------------------------------------------------"
echo " Playwright Sudo Verification (linux-mac)"
echo "---------------------------------------------------------"
echo "PLAYROOT:"
echo "    $PLAYROOT"
echo

echo "[1] Checking required files..."
for f in "${FILES[@]}"; do
  if [[ -f "$f" ]]; then
    echo "  ✔ Found: $(basename "$f")"
  else
    echo "  ✘ Missing: $(basename "$f")"
    exit 1
  fi
done

echo
echo "[2] Checking permissions + ownership..."
for f in "${FILES[@]}"; do
  owner=$(stat -c %U "$f")
  group=$(stat -c %G "$f")
  perm=$(stat -c %a "$f")

  if [[ "$owner" == "root" && "$group" == "$DESKTOP_USER" && "$perm" == "770" ]]; then
    echo "  ✔ OK: $(basename "$f")"
  else
    echo "  ✘ WRONG: $(basename "$f") (owner=$owner group=$group perm=$perm)"
    exit 1
  fi
done

echo
echo "[3] Checking sudoers entry..."
if [[ -f "$SUDOERS_FILE" ]]; then
  echo "  ✔ Sudoers file exists"
else
  echo "  ✘ Sudoers file missing"
  exit 1
fi

echo
echo "Verification complete."
