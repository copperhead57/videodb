#!/bin/bash
# pw-sudo-02-verify.sh
# Verification for menu-based Playwright sudo setup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYROOT="${PLAYROOT:-$SCRIPT_DIR}"

SUDOERS_FILE="/etc/sudoers.d/videodb-playwright"

FILES=(
  "$PLAYROOT/xvfb.sh"
  "$PLAYROOT/node-clean.sh"
  "$PLAYROOT/imdb-fetch-unix.mjs"
)

echo "---------------------------------------------------------"
echo " Playwright Sudo Verification"
echo "---------------------------------------------------------"
echo "PLAYROOT:"
echo "    $PLAYROOT"
echo

# ---------------------------------------------------------
# 1. Check required files
# ---------------------------------------------------------
echo "[1] Checking required files..."
for f in "${FILES[@]}"; do
  if [[ -f "$f" ]]; then
    echo "  ✔ Found: $(basename "$f")"
  else
    echo "  ✘ Missing: $(basename "$f")"
    exit 1
  fi
done

# ---------------------------------------------------------
# 2. Check permissions + ownership
# ---------------------------------------------------------
echo
echo "[2] Checking permissions + ownership..."

for f in "${FILES[@]}"; do
  owner=$(stat -c %U "$f")
  group=$(stat -c %G "$f")
  perm=$(stat -c %a "$f")

  if [[ "$owner" == "root" && "$perm" == "770" ]]; then
    echo "  ✔ OK: $(basename "$f") (owner=$owner group=$group perm=$perm)"
  else
    echo "  ✘ WRONG: $(basename "$f") (owner=$owner group=$group perm=$perm)"
    exit 1
  fi
done

# ---------------------------------------------------------
# 3. Check sudoers file
# ---------------------------------------------------------
echo
echo "[3] Checking sudoers entry..."

if [[ ! -f "$SUDOERS_FILE" ]]; then
  echo "  ✘ Sudoers file missing"
  exit 1
fi

echo "  ✔ Sudoers file exists"

# Validate syntax
if visudo -c -f "$SUDOERS_FILE" >/dev/null 2>&1; then
  echo "  ✔ Sudoers syntax OK"
else
  echo "  ✘ Sudoers syntax error"
  exit 1
fi

# ---------------------------------------------------------
# 4. Check sudoers content (www-data / daemon)
# ---------------------------------------------------------
echo
echo "[4] Checking sudoers rules..."

HAS_WWWDATA=0
HAS_DAEMON=0

grep -q "^www-data" "$SUDOERS_FILE" && HAS_WWWDATA=1
grep -q "^daemon" "$SUDOERS_FILE" && HAS_DAEMON=1

if [[ $HAS_WWWDATA -eq 1 ]]; then
  echo "  ✔ Contains rules for www-data"
fi

if [[ $HAS_DAEMON -eq 1 ]]; then
  echo "  ✔ Contains rules for daemon"
fi

if [[ $HAS_WWWDATA -eq 0 && $HAS_DAEMON -eq 0 ]]; then
  echo "  ✘ No valid sudoers rules found"
  exit 1
fi

# ---------------------------------------------------------
# Summary
# ---------------------------------------------------------
echo
echo "Verification complete — all checks passed."
